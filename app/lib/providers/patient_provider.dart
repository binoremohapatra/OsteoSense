import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class PatientProvider with ChangeNotifier {
  List<Patient> _patients = [];
  Patient? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, dynamic> _screeningData = {};

  // Sync guard — prevents concurrent/repeated API calls
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  DateTime? _rateLimitedUntil; // set when server returns 429

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;
  int? get selectedPatientId => _selectedPatient?.id;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get screeningData => _screeningData;

  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = null;
    // Schedule notifyListeners safely — never during build
    Future.microtask(notifyListeners);

    try {
      // STEP 1: Load local DB instantly — no API wait
      final db = DatabaseHelper();
      final localData = await db.query(
        'patients',
        where: 'deleted = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
      _patients = localData.map((data) => Patient.fromMap(data)).toList();
      _isLoading = false;
      Future.microtask(notifyListeners); // Show patients immediately

      // STEP 2: Background API sync — throttled, non-blocking
      _maybeSync(db);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        debugPrint('Error loading patients: $e');
      }
      _isLoading = false;
      Future.microtask(notifyListeners);
    }
  }

  /// Syncs with server only if: not already syncing, not rate-limited,
  /// and at least 60 seconds since last sync.
  void _maybeSync(DatabaseHelper db) {
    final now = DateTime.now();

    // 429 rate limit active — wait it out
    if (_rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!)) {
      if (kDebugMode) {
        debugPrint('[PatientProvider] Sync skipped — rate limited until $_rateLimitedUntil');
      }
      return;
    }

    // Already syncing — skip
    if (_isSyncing) return;

    // Too soon since last sync (min 60 seconds between syncs)
    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!).inSeconds < 60) {
      return;
    }

    _syncWithApiInBackground(db);
  }

  /// Syncs patients from server in background without blocking the UI.
  Future<void> _syncWithApiInBackground(DatabaseHelper db) async {
    _isSyncing = true;
    try {
      final patientsData = await ApiService()
          .getPatients()
          .timeout(const Duration(seconds: 10));

      _lastSyncTime = DateTime.now();
      _rateLimitedUntil = null; // Clear any previous rate limit

      final mappedPatients = <Map<String, dynamic>>[];
      for (var data in patientsData) {
        final pData = Map<String, dynamic>.from(data as Map);
        pData['server_id'] = pData['id'] ?? pData['_id'];
        if (pData['createdAt'] != null) {
          pData['created_at'] = pData['createdAt'].toString();
        }
        if (pData['updatedAt'] != null) {
          pData['updated_at'] = pData['updatedAt'].toString();
        }
        pData['synced'] = 1;
        mappedPatients.add(pData);
      }

      await db.bulkUpsertPatients(mappedPatients);

      // Reload merged list (server + unsynced local)
      final allData = await db.query(
        'patients',
        where: 'deleted = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
      _patients = allData.map((data) => Patient.fromMap(data)).toList();
      Future.microtask(notifyListeners);
    } catch (apiError) {
      _lastSyncTime = DateTime.now(); // Still update so we don't retry instantly
      // Check if it's a 429 — parse retry-after if possible
      final errStr = apiError.toString();
      if (errStr.contains('429')) {
        // Default: wait 5 minutes before next attempt
        _rateLimitedUntil = DateTime.now().add(const Duration(minutes: 5));
        if (kDebugMode) {
          debugPrint('[PatientProvider] Rate limited (429). Next sync after $_rateLimitedUntil');
        }
      } else if (kDebugMode) {
        debugPrint('[PatientProvider] Background sync skipped: $apiError');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> searchPatients(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
      final db = DatabaseHelper();
      final patientsData = await db.query(
        'patients',
        where: 'name LIKE ? OR village LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );

      _patients = patientsData.map((data) => Patient.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByRiskLevel(String riskLevel) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
      final db = DatabaseHelper();
      final screeningsData = await db.query(
        'screenings',
        where: 'risk_level = ?',
        whereArgs: [riskLevel],
        orderBy: 'screening_date DESC',
      );

      final patientIds = screeningsData.map((s) => s['patient_id'] as int).toSet();
      
      if (patientIds.isEmpty) {
        _patients = [];
      } else {
        final placeholders = List.filled(patientIds.length, '?').join(',');
        final patientsData = await db.query(
          'patients',
          where: 'id IN ($placeholders)',
          whereArgs: patientIds.toList(),
        );
        _patients = patientsData.map((data) => Patient.fromMap(data)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(Patient patient) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(notifyListeners);

    try {
      final db = DatabaseHelper();
      
      // STEP 1: Save locally FIRST — instant, no API wait
      final id = await db.insert('patients', patient.toMap());
      var newPatient = patient.copyWith(id: id);
      
      // Show patient in list immediately
      _patients.insert(0, newPatient);
      _selectedPatient = newPatient;
      _isLoading = false;
      Future.microtask(notifyListeners); // Refresh list right away

      // STEP 2: Sync to API in background (non-blocking)
      _syncNewPatientToApi(db, id, newPatient);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      Future.microtask(notifyListeners);
      return false;
    }
  }

  /// Pushes a newly added patient to the server without blocking the UI.
  Future<void> _syncNewPatientToApi(DatabaseHelper db, int localId, Patient patient) async {
    try {
      final apiData = {
        'localId': localId,
        'name': patient.name,
        'fullName': patient.name,
        'age': patient.age,
        'gender': patient.gender,
        'contact': patient.contact,
        'village': patient.village,
        'address': patient.address,
        'occupation': patient.occupation,
        'height_cm': patient.heightCm,
        'weight_kg': patient.weightKg,
        'height': patient.heightCm,
        'weight': patient.weightKg,
      };
      
      final response = await ApiService().createPatient(apiData);
      final serverId = response['patient']['_id'];
      
      // Update local record with server ID
      await db.update(
        'patients',
        {'server_id': serverId, 'synced': 1},
        where: 'id = ?',
        whereArgs: [localId],
      );

      // Update in-memory record too
      final idx = _patients.indexWhere((p) => p.id == localId);
      if (idx != -1) {
        _patients[idx] = patient.copyWith(serverId: serverId, synced: true);
        if (_selectedPatient?.id == localId) {
          _selectedPatient = _patients[idx];
        }
        Future.microtask(notifyListeners);
      }
    } catch (apiError) {
      // Failed — queue for later sync
      await db.addToSyncQueue('patients', localId, 'insert', patient.toMap());
      if (kDebugMode) {
        debugPrint('[PatientProvider] addPatient API sync queued: $apiError');
      }
    }
  }

  Future<bool> updatePatient(Patient patient) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      
      // Update local DB first
      await db.update(
        'patients',
        patient.toMap(),
        where: 'id = ?',
        whereArgs: [patient.id],
      );

      var updatedPatient = patient;

      try {
        // Try API sync immediately if we have a serverId
        if (patient.serverId != null) {
          final apiData = {
            'name': patient.name,
            'fullName': patient.name,
            'age': patient.age,
            'gender': patient.gender,
            'contact': patient.contact,
            'village': patient.village,
            'address': patient.address,
            'occupation': patient.occupation,
            'height_cm': patient.heightCm,
            'weight_kg': patient.weightKg,
            'height': patient.heightCm,
            'weight': patient.weightKg,
          };
          
          // Call updatePatient API using the mongo _id
          await ApiService().updatePatient(patient.serverId, apiData);
          
          updatedPatient = patient.copyWith(synced: true);
          await db.update(
            'patients',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [patient.id],
          );
        } else {
           // It was never synced, just add to sync queue as an insert or update
           await db.addToSyncQueue('patients', patient.id!, 'update', patient.toMap());
        }
      } catch (apiError) {
        // Failed to sync immediately, add to sync queue
        await db.addToSyncQueue('patients', patient.id!, 'update', patient.toMap());
      }

      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _patients[index] = updatedPatient;
      }

      if (_selectedPatient?.id == patient.id) {
        _selectedPatient = updatedPatient;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePatient(int patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      await db.delete(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );

      _patients.removeWhere((p) => p.id == patientId);
      
      if (_selectedPatient?.id == patientId) {
        _selectedPatient = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> selectPatient(Patient patient) async {
    _selectedPatient = patient;
    notifyListeners();
  }

  Future<void> loadPatientById(int patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      final patientsData = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );

      if (patientsData.isNotEmpty) {
        _selectedPatient = Patient.fromMap(patientsData.first);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
