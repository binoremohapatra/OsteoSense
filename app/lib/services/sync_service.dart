import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

enum ConflictStrategy {
  serverWins,
  clientWins,
  manual,
  lastModified,
}

class SyncConflict {
  final String tableName;
  final int recordId;
  final Map<String, dynamic> clientData;
  final Map<String, dynamic> serverData;
  final DateTime clientModified;
  final DateTime serverModified;

  SyncConflict({
    required this.tableName,
    required this.recordId,
    required this.clientData,
    required this.serverData,
    required this.clientModified,
    required this.serverModified,
  });
}

class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final int conflictCount;
  final String message;
  final List<SyncConflict> conflicts;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.message = '',
    this.conflicts = const [],
  });
}

class SyncError {
  final String tableName;
  final int recordId;
  final String action;
  final String errorMessage;
  final DateTime timestamp;

  SyncError({
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.errorMessage,
    required this.timestamp,
  });
}

class SyncStatus {
  final bool isSyncing;
  final int pendingItems;
  final DateTime? lastSyncTime;
  final String syncStatus;
  final int failedItems;

  SyncStatus({
    required this.isSyncing,
    required this.pendingItems,
    this.lastSyncTime,
    required this.syncStatus,
    required this.failedItems,
  });
}

class SyncService {
  static SyncService? _instance;
  final DatabaseHelper _db = DatabaseHelper();
  bool _isSyncing = false;
  bool _isPaused = false;
  StreamSubscription? _connectivitySubscription;
  Timer? _backgroundSyncTimer;
  ConflictStrategy _conflictStrategy = ConflictStrategy.lastModified;

  factory SyncService() {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  SyncService._internal();

  bool get isSyncing => _isSyncing;
  bool get isPaused => _isPaused;
  ConflictStrategy get conflictStrategy => _conflictStrategy;

  void setConflictStrategy(ConflictStrategy strategy) {
    _conflictStrategy = strategy;
  }

  void startAutoSync() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      // Handle both single ConnectivityResult and List<ConnectivityResult>
      ConnectivityResult result;
      if (results is List<ConnectivityResult>) {
        final List<ConnectivityResult> resultList = results as List<ConnectivityResult>;
        if (resultList.isNotEmpty) {
          result = resultList.first;
        } else {
          result = ConnectivityResult.none;
        }
      } else {
        result = results;
      }
      
      if (result != ConnectivityResult.none && !_isPaused) {
        performFullSync();
      }
    });
  }

  void stopAutoSync() {
    _connectivitySubscription?.cancel();
    stopBackgroundSync();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIDIRECTIONAL SYNC
  // ─────────────────────────────────────────────────────────────────────────

  Future<SyncResult> performFullSync() async {
    if (_isSyncing || _isPaused) {
      return SyncResult(
        success: false,
        message: _isPaused ? 'Sync is paused' : 'Sync already in progress',
      );
    }

    _isSyncing = true;
    debugPrint('Starting full sync...');

    try {
      final pushResult = await pushLocalChanges();
      if (!pushResult.success) {
        _isSyncing = false;
        return pushResult;
      }

      final pullResult = await pullServerChanges();
      
      // Update last sync time
      await _db.updateLastSyncTime(DateTime.now());

      _isSyncing = false;
      
      return SyncResult(
        success: pullResult.success,
        syncedCount: pushResult.syncedCount + pullResult.syncedCount,
        failedCount: pushResult.failedCount + pullResult.failedCount,
        conflictCount: pushResult.conflictCount + pullResult.conflictCount,
        message: 'Full sync completed',
        conflicts: [...pushResult.conflicts, ...pullResult.conflicts],
      );
    } catch (e) {
      debugPrint('Full sync error: $e');
      _isSyncing = false;
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    }
  }

  Future<SyncResult> pushLocalChanges() async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sync in progress');

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;
    final conflicts = <SyncConflict>[];

    try {
      final syncQueue = await _db.getPendingSyncItems();
      
      if (syncQueue.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: true, syncedCount: 0, message: 'No local changes to sync');
      }

      debugPrint('Pushing ${syncQueue.length} local changes...');

      List<Map<String, dynamic>> changes = [];
      List<int> queueIds = [];

      for (var item in syncQueue) {
        try {
          final dataStr = item['data'] as String;
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          data['_sync_queue_id'] = item['id'];
          data['_sync_action'] = item['action'];
          data['localId'] = item['record_id'];
          data['tableName'] = item['table_name'];
          
          changes.add(data);
          queueIds.add(item['id'] as int);
        } catch (e) {
          debugPrint('Error parsing sync item: $e');
          failedCount++;
        }
      }

      try {
        final response = await ApiService().syncPush(changes);
        
        // Handle successfully synced items
        final syncedItems = response['synced'] ?? [];
        for (var item in syncedItems) {
          final localId = item['localId'];
          final serverId = item['serverId'];
          final tableName = item['tableName'];
          
          if (localId != null && serverId != null) {
            await _db.update(
              tableName,
              {'server_id': serverId, 'synced': 1},
              where: 'id = ?',
              whereArgs: [localId],
            );
            syncedCount++;
          }
        }

        // Handle conflicts
        final conflictItems = response['conflicts'] ?? [];
        for (var conflictData in conflictItems) {
          final conflict = SyncConflict(
            tableName: conflictData['tableName'],
            recordId: conflictData['recordId'],
            clientData: conflictData['clientData'],
            serverData: conflictData['serverData'],
            clientModified: DateTime.parse(conflictData['clientModified']),
            serverModified: DateTime.parse(conflictData['serverModified']),
          );
          
          final resolved = await resolveConflict(conflict);
          if (resolved) {
            syncedCount++;
          } else {
            conflicts.add(conflict);
          }
        }

        // Clear successfully synced items from queue
        for (var qId in queueIds) {
          await _db.markSyncItemComplete(qId);
        }

        _isSyncing = false;
        return SyncResult(
          success: true,
          syncedCount: syncedCount,
          failedCount: failedCount,
          conflictCount: conflicts.length,
          message: 'Push completed',
          conflicts: conflicts,
        );
      } catch (e) {
        debugPrint('Push API failed: $e');

        // Check if this is an authentication error
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          debugPrint('Authentication error - sync will be retried when user logs in');
          _isSyncing = false;
          return SyncResult(
            success: false,
            syncedCount: syncedCount,
            failedCount: failedCount,
            message: 'Authentication required. Please login to sync data.',
          );
        }

        // Increment retry counts for other errors
        for (var item in syncQueue) {
          final retryCount = (item['retry_count'] as int) + 1;
          if (retryCount >= AppConstants.maxRetryCount) {
            await _db.removeFromSyncQueue(item['id'] as int);
            failedCount++;
          } else {
            await _db.update(
              'sync_queue',
              {'retry_count': retryCount},
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        }

        _isSyncing = false;
        return SyncResult(
          success: false,
          syncedCount: syncedCount,
          failedCount: failedCount,
          message: 'Push failed: $e',
        );
      }
    } catch (e) {
      debugPrint('Push error: $e');
      _isSyncing = false;
      return SyncResult(
        success: false,
        failedCount: failedCount,
        message: 'Push error: $e',
      );
    }
  }

  Future<SyncResult> pullServerChanges() async {
    if (_isSyncing) return SyncResult(success: false, message: 'Sync in progress');

    _isSyncing = true;
    int syncedCount = 0;
    int failedCount = 0;

    try {
      final lastSync = await _db.getLastSyncTime();
      final serverChanges = await ApiService().syncPull(lastSync);
      
      debugPrint('Pulled ${serverChanges.length} changes from server');

      for (var change in serverChanges) {
        try {
          final tableName = change['tableName'] as String;
          final action = change['action'] as String;
          final data = change['data'] as Map<String, dynamic>;

          switch (action) {
            case 'insert':
            case 'update':
              await _db.insert(tableName, data);
              syncedCount++;
              break;
            case 'delete':
              await _db.delete(
                tableName,
                where: 'server_id = ?',
                whereArgs: [data['server_id']],
              );
              syncedCount++;
              break;
          }
        } catch (e) {
          debugPrint('Error processing server change: $e');
          failedCount++;
        }
      }

      _isSyncing = false;
      return SyncResult(
        success: true,
        syncedCount: syncedCount,
        failedCount: failedCount,
        message: 'Pull completed',
      );
    } catch (e) {
      debugPrint('Pull error: $e');
      _isSyncing = false;
      return SyncResult(
        success: false,
        failedCount: failedCount,
        message: 'Pull failed: $e',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONFLICT RESOLUTION
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> resolveConflict(SyncConflict conflict) async {
    switch (_conflictStrategy) {
      case ConflictStrategy.serverWins:
        return await _applyServerData(conflict);
      case ConflictStrategy.clientWins:
        return await _applyClientData(conflict);
      case ConflictStrategy.lastModified:
        return conflict.serverModified.isAfter(conflict.clientModified)
            ? await _applyServerData(conflict)
            : await _applyClientData(conflict);
      case ConflictStrategy.manual:
        // Return false - requires manual intervention
        return false;
    }
  }

  Future<bool> _applyServerData(SyncConflict conflict) async {
    try {
      await _db.update(
        conflict.tableName,
        conflict.serverData,
        where: 'id = ?',
        whereArgs: [conflict.recordId],
      );
      return true;
    } catch (e) {
      debugPrint('Error applying server data: $e');
      return false;
    }
  }

  Future<bool> _applyClientData(SyncConflict conflict) async {
    try {
      // Re-queue the client data for push
      await _db.addToSyncQueue(
        conflict.tableName,
        conflict.recordId,
        'update',
        conflict.clientData,
      );
      return true;
    } catch (e) {
      debugPrint('Error applying client data: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<SyncStatus> getSyncStatus() async {
    final pendingItems = await getPendingSyncCount();
    final lastSyncTime = await _db.getLastSyncTime();
    final failedItems = await getFailedSyncCount();

    return SyncStatus(
      isSyncing: _isSyncing,
      pendingItems: pendingItems,
      lastSyncTime: lastSyncTime,
      syncStatus: _isSyncing ? 'syncing' : (pendingItems > 0 ? 'pending' : 'idle'),
      failedItems: failedItems,
    );
  }

  Future<void> pauseSync() async {
    _isPaused = true;
    debugPrint('Sync paused');
  }

  Future<void> resumeSync() async {
    _isPaused = false;
    debugPrint('Sync resumed');
    if (await isConnected()) {
      performFullSync();
    }
  }

  Future<void> clearSyncQueue() async {
    try {
      final syncQueue = await _db.getSyncQueue();
      for (var item in syncQueue) {
        await _db.removeFromSyncQueue(item['id'] as int);
      }
      debugPrint('Sync queue cleared');
    } catch (e) {
      debugPrint('Error clearing sync queue: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BACKGROUND SYNC
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> startBackgroundSync({Duration interval = const Duration(minutes: 15)}) async {
    stopBackgroundSync();
    
    _backgroundSyncTimer = Timer.periodic(interval, (timer) async {
      if (!_isPaused && await isConnected()) {
        await performFullSync();
      }
    });
    
    debugPrint('Background sync started with ${interval.inMinutes} minute interval');
  }

  Future<void> stopBackgroundSync() async {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
    debugPrint('Background sync stopped');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ERROR HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> handleSyncError(SyncError error) async {
    debugPrint('Sync error: ${error.errorMessage}');
    // Log to database for later review
    await _db.logAuditEvent({
      'action': 'sync_error',
      'table_name': error.tableName,
      'record_id': error.recordId,
      'new_values': {'error': error.errorMessage},
    });
  }

  Future<List<SyncError>> getSyncErrors() async {
    // This would query a sync_errors table if we implemented it
    // For now, return empty list
    return [];
  }

  Future<void> retryFailedSync() async {
    final pendingItems = await _db.getPendingSyncItems();
    final failedItems = pendingItems.where((item) => 
      (item['retry_count'] as int) > 0 && (item['retry_count'] as int) < AppConstants.maxRetryCount
    ).toList();

    debugPrint('Retrying ${failedItems.length} failed sync items');

    // Reset retry counts
    for (var item in failedItems) {
      await _db.update(
        'sync_queue',
        {'retry_count': 0},
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }

    // Attempt sync again
    await performFullSync();
  }

  Future<int> getFailedSyncCount() async {
    try {
      final syncQueue = await _db.getSyncQueue();
      return syncQueue.where((item) => (item['retry_count'] as int) > 0).length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> syncPendingData() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    debugPrint('Starting sync...');

    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      ConnectivityResult result;
      
      // Handle both single ConnectivityResult and List<ConnectivityResult>
      if (connectivity is List<ConnectivityResult>) {
        final List<ConnectivityResult> resultList = connectivity as List<ConnectivityResult>;
        if (resultList.isEmpty || resultList.first == ConnectivityResult.none) {
          debugPrint('No internet connection available');
          _isSyncing = false;
          return false;
        }
        result = resultList.first;
      } else {
        result = connectivity;
        if (result == ConnectivityResult.none) {
          debugPrint('No internet connection available');
          _isSyncing = false;
          return false;
        }
      }

      // Get all pending sync items
      final syncQueue = await _db.getSyncQueue();
      
      if (syncQueue.isEmpty) {
        debugPrint('No pending data to sync');
        _isSyncing = false;
        return true;
      }

      debugPrint('Found ${syncQueue.length} items to sync');

      List<Map<String, dynamic>> patients = [];
      List<Map<String, dynamic>> screenings = [];
      List<int> queueIds = [];

      for (var item in syncQueue) {
        try {
          final tableName = item['table_name'] as String;
          final action = item['action'] as String;
          final recordId = item['record_id'] as int;
          final dataStr = item['data'] as String;
          
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          data['_sync_queue_id'] = item['id'];
          data['_sync_action'] = action;
          data['localId'] = recordId;

          if (tableName == 'patients') {
            patients.add(data);
          } else if (tableName == 'screenings') {
            screenings.add(data);
          }
          queueIds.add(item['id'] as int);
        } catch (e) {
          debugPrint('Error parsing sync item ${item['id']}: $e');
        }
      }

      final batchData = {
        'patients': patients,
        'screenings': screenings,
      };

      try {
        final response = await ApiService().syncBatch(batchData);
        
        // Handle successfully synced patients
        final syncedPatients = response['results']?['patients'] ?? [];
        for (var p in syncedPatients) {
          final localId = p['localId'];
          final serverId = p['serverId'];
          if (localId != null && serverId != null) {
            await _db.update(
              'patients',
              {'server_id': serverId, 'synced': 1},
              where: 'id = ?',
              whereArgs: [localId],
            );
          }
        }

        // Handle successfully synced screenings
        final syncedScreenings = response['results']?['screenings'] ?? [];
        for (var s in syncedScreenings) {
          final localId = s['localId'];
          final serverId = s['serverId'];
          if (localId != null && serverId != null) {
            await _db.update(
              'screenings',
              {'server_id': serverId, 'synced': 1},
              where: 'id = ?',
              whereArgs: [localId],
            );
          }
        }

        // Clear synced items from queue
        for (var qId in queueIds) {
          await _db.removeFromSyncQueue(qId);
        }

        debugPrint('Sync completed successfully');
        _isSyncing = false;
        return true;
      } catch (e) {
        debugPrint('Sync batch API failed: $e');
        
        // Increment retry counts
        for (var item in syncQueue) {
          final retryCount = (item['retry_count'] as int) + 1;
          if (retryCount >= AppConstants.maxRetryCount) {
            await _db.removeFromSyncQueue(item['id'] as int);
          } else {
            await _db.update(
              'sync_queue',
              {'retry_count': retryCount},
              where: 'id = ?',
              whereArgs: [item['id']],
            );
          }
        }
        
        _isSyncing = false;
        return false;
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      _isSyncing = false;
      return false;
    }
  }





  Future<int> getPendingSyncCount() async {
    try {
      final patientCount = await _db.getUnsyncedCount('patients');
      final screeningCount = await _db.getUnsyncedCount('screenings');
      final queueCount = (await _db.getSyncQueue()).length;
      return patientCount + screeningCount + queueCount;
    } catch (e) {
      debugPrint('Error getting pending sync count: $e');
      return 0;
    }
  }

  Future<bool> isConnected() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity is List<ConnectivityResult>) {
        final List<ConnectivityResult> resultList = connectivity as List<ConnectivityResult>;
        return resultList.isNotEmpty && resultList.first != ConnectivityResult.none;
      } else {
        final ConnectivityResult result = connectivity;
        return result != ConnectivityResult.none;
      }
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPatientFromServer(int patientId) async {
    try {
      // Actually fetch via ApiService if we needed to, but we generally just use ApiService.getPatients() 
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchScreeningFromServer(int screeningId) async {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    stopAutoSync();
  }
}
