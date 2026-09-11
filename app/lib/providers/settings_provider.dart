import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SettingsProvider with ChangeNotifier {
  String _language = 'en';
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  int _pendingSyncCount = 0;

  // Notification settings
  bool _pushNotificationsEnabled = true;
  bool _screeningRemindersEnabled = true;
  bool _healthAlertsEnabled = true;
  bool _vibrationEnabled = true;
  String _notificationSound = 'Default';
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';
  bool _quietHoursEnabled = false;

  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoSyncEnabled => _autoSyncEnabled;
  ConnectivityResult get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus != ConnectivityResult.none;
  int get pendingSyncCount => _pendingSyncCount;

  // Notification getters
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get screeningRemindersEnabled => _screeningRemindersEnabled;
  bool get healthAlertsEnabled => _healthAlertsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get notificationSound => _notificationSound;
  String get quietHoursStart => _quietHoursStart;
  String get quietHoursEnd => _quietHoursEnd;
  bool get quietHoursEnabled => _quietHoursEnabled;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _language = prefs.getString('language') ?? 'en';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;

      // Load notification settings
      _pushNotificationsEnabled = prefs.getBool('push_notifications_enabled') ?? true;
      _screeningRemindersEnabled = prefs.getBool('screening_reminders_enabled') ?? true;
      _healthAlertsEnabled = prefs.getBool('health_alerts_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _notificationSound = prefs.getString('notification_sound') ?? 'Default';
      _quietHoursStart = prefs.getString('quiet_hours_start') ?? '22:00';
      _quietHoursEnd = prefs.getString('quiet_hours_end') ?? '07:00';
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;

      await checkConnectivity();
      await updatePendingSyncCount();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
    }
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _autoSyncEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_sync_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving auto sync preference: $e');
    }
  }

  // Notification settings methods
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving push notification preference: $e');
    }
  }

  Future<void> setScreeningRemindersEnabled(bool enabled) async {
    _screeningRemindersEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('screening_reminders_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving screening reminder preference: $e');
    }
  }

  Future<void> setHealthAlertsEnabled(bool enabled) async {
    _healthAlertsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('health_alerts_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving health alert preference: $e');
    }
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving vibration preference: $e');
    }
  }

  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_sound', sound);
    } catch (e) {
      debugPrint('Error saving notification sound: $e');
    }
  }

  Future<void> setQuietHoursEnabled(bool enabled) async {
    _quietHoursEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quiet_hours_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving quiet hours enabled: $e');
    }
  }

  Future<void> setQuietHoursStart(String time) async {
    _quietHoursStart = time;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quiet_hours_start', time);
    } catch (e) {
      debugPrint('Error saving quiet hours start: $e');
    }
  }

  Future<void> setQuietHoursEnd(String time) async {
    _quietHoursEnd = time;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quiet_hours_end', time);
    } catch (e) {
      debugPrint('Error saving quiet hours end: $e');
    }
  }

  Future<void> checkConnectivity() async {
    try {
      final connectivity = Connectivity();
      // Added a timeout because connectivity_plus checkConnectivity() can hang indefinitely on some Android emulators
      final results = await connectivity.checkConnectivity().timeout(
        const Duration(seconds: 2),
        onTimeout: () => ConnectivityResult.none, // fallback to none if it hangs
      );

      // Handle both single ConnectivityResult and List<ConnectivityResult>
      if (results is List<ConnectivityResult>) {
        final List<ConnectivityResult> resultList = results as List<ConnectivityResult>;
        if (resultList.isNotEmpty) {
          _connectionStatus = resultList.first;
        } else {
          _connectionStatus = ConnectivityResult.none;
        }
      } else {
        _connectionStatus = results;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _connectionStatus = ConnectivityResult.none;
      notifyListeners();
    }
  }

  Future<void> updatePendingSyncCount() async {
    try {
      // This would typically query the database for unsynced records
      // For now, we'll use a placeholder
      _pendingSyncCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending sync count: $e');
    }
  }

  void incrementPendingSync() {
    _pendingSyncCount++;
    notifyListeners();
  }

  void decrementPendingSync() {
    if (_pendingSyncCount > 0) {
      _pendingSyncCount--;
      notifyListeners();
    }
  }

  Future<void> clearOfflineData() async {
    try {
      // This would clear all offline data from the database
      // For now, it's a placeholder
      _pendingSyncCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }

  void startConnectivityListener() {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((results) {
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
      
      _connectionStatus = result;
      notifyListeners();
      
      // Auto-sync if enabled and connected
      if (_autoSyncEnabled && _connectionStatus != ConnectivityResult.none) {
        // Trigger sync
      }
    });
  }
}
