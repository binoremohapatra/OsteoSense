import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userRole; // 'agent' or 'user'

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;
  String? get userRole => _userRole;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      _userRole = prefs.getString('user_role');
      final userId = prefs.getInt('current_user_id');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      debugPrint('Loading current user - Token: ${token != null ? "EXISTS" : "NULL"}, Role: $_userRole, UserID: $userId, LoggedIn: $isLoggedIn');

      // Fix invalid role values
      if (_userRole != 'agent' && _userRole != 'user') {
        debugPrint('Invalid role detected: $_userRole, defaulting to agent');
        _userRole = 'agent';
        await prefs.setString('user_role', 'agent');
      }

      if (!isLoggedIn) {
        debugPrint('User not logged in according to preferences');
        _currentUser = null;
        _userRole = null;
      } else if (token != null) {
        try {
          // Try API first
          final userData = await ApiService().getCurrentUser();
          _currentUser = User.fromMap(userData['data'] ?? userData);
          final newUserId = _currentUser!.id;
          if (newUserId != null) await prefs.setInt('current_user_id', newUserId);
          debugPrint('User loaded from API successfully');
        } catch (e) {
          debugPrint('API auth failed, falling back to local DB: $e');
          // Fallback to local DB - this handles 401 errors gracefully
          if (userId != null) {
            final db = DatabaseHelper();
            final users = await db.query(
              'users',
              where: 'id = ?',
              whereArgs: [userId],
            );
            if (users.isNotEmpty) {
              _currentUser = User.fromMap(users.first);
              debugPrint('Loaded user from local DB fallback');
            } else {
              debugPrint('No user found in local DB with ID: $userId');
              // Clear login flag if user not found
              await prefs.setBool('is_logged_in', false);
            }
          } else {
            debugPrint('No user ID in preferences for DB fallback');
            await prefs.setBool('is_logged_in', false);
          }
        }
      } else {
        // No token, check local fallback just in case it's a demo session
        debugPrint('No token found, checking local DB fallback');
        if (userId != null) {
          final db = DatabaseHelper();
          final users = await db.query(
            'users',
            where: 'id = ?',
            whereArgs: [userId],
          );
          if (users.isNotEmpty) {
            _currentUser = User.fromMap(users.first);
            debugPrint('Loaded user from local DB (no token)');
          } else {
            debugPrint('No user found in local DB with ID: $userId');
            await prefs.setBool('is_logged_in', false);
          }
        } else {
          debugPrint('No user ID in preferences');
          await prefs.setBool('is_logged_in', false);
        }
      }

      debugPrint('Final auth state - IsAuthenticated: $isAuthenticated, User: $_currentUser');
    } catch (e) {
      debugPrint('Error loading current user: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Try API Login
      final response = await ApiService().login(phoneNumber, password);
      final token = response['token'];
      final refreshToken = response['refreshToken'];
      final userData = response['user'];
      _currentUser = User.fromMap(userData);
      final role = _currentUser!.healthCenterId != null ? 'agent' : 'user';
      _userRole = role;
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token);
        debugPrint('Token saved to preferences');
      }
      if (refreshToken != null) {
        await prefs.setString('refresh_token', refreshToken);
        debugPrint('Refresh token saved to preferences');
      }
      await prefs.setInt('current_user_id', _currentUser!.id!);
      await prefs.setString('user_role', role);
      await prefs.setBool('is_logged_in', true);
      debugPrint('User ID: ${_currentUser!.id}, Role: $role saved to preferences');
      debugPrint('Login flag set to true');

      // Verify saved data
      final savedToken = prefs.getString('auth_token');
      final savedUserId = prefs.getInt('current_user_id');
      final savedRole = prefs.getString('user_role');
      final savedLoginFlag = prefs.getBool('is_logged_in');
      debugPrint('Verification - Token: ${savedToken != null ? "EXISTS" : "NULL"}, UserID: $savedUserId, Role: $savedRole, LoggedIn: $savedLoginFlag');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (apiError) {
      // 2. Fallback to Local DB on network failure
      try {
        final db = DatabaseHelper();
        final users = await db.query(
          'users',
          where: 'phone_number = ? AND password = ?',
          whereArgs: [phoneNumber, password],
        );

        if (users.isNotEmpty) {
          _currentUser = User.fromMap(users.first);
          final role = _currentUser!.healthCenterId != null ? 'agent' : 'user';
          _userRole = role; // Set in memory, not just prefs
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('current_user_id', _currentUser!.id!);
          await prefs.setString('user_role', role);
          await prefs.setBool('is_logged_in', true);
          debugPrint('Offline login - User ID: ${_currentUser!.id}, Role: $role saved to preferences');
          debugPrint('Login flag set to true');

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = apiError is ApiException ? apiError.message : 'Invalid credentials (offline)';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (dbError) {
        _errorMessage = apiError is ApiException ? apiError.message : dbError.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> signup(User user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Try API Signup
      final response = await ApiService().register(user.toApiMap());
      final token = response['token'];
      final refreshToken = response['refreshToken'];
      final userData = response['user'];

      _currentUser = User.fromMap(userData);
      
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('auth_token', token);
      if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
      await prefs.setInt('current_user_id', _currentUser!.id!);
      await prefs.setString('user_role', _currentUser!.healthCenterId != null ? 'agent' : 'user');
      
      // Save locally as well for offline fallback
      final db = DatabaseHelper();
      final existing = await db.query('users', where: 'phone_number = ?', whereArgs: [user.phoneNumber]);
      if (existing.isEmpty) {
        await db.insert('users', _currentUser!.toMap());
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (apiError) {
      // 2. Fallback to Local DB on network failure
      try {
        final db = DatabaseHelper();
        final existingUsers = await db.query(
          'users',
          where: 'phone_number = ?',
          whereArgs: [user.phoneNumber],
        );

        if (existingUsers.isNotEmpty) {
          _errorMessage = 'Phone number already registered locally';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final id = await db.insert('users', user.toMap());
        _currentUser = user.copyWith(id: id);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_user_id', _currentUser!.id!);
        await prefs.setString('user_role', _currentUser!.healthCenterId != null ? 'agent' : 'user');

        // Note: Ideally queue this signup for sync when online
        
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (dbError) {
        _errorMessage = apiError is ApiException ? apiError.message : dbError.toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
  }


  Future<void> logout() async {
    debugPrint('Logging out user...');
    _currentUser = null;
    _userRole = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('user_role');
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('is_logged_in');

    debugPrint('Cleared all auth data from preferences');
    notifyListeners();
  }

  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      await db.update(
        'users',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      _currentUser = updatedUser;
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  Future<void> saveUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // Resolve role: prefer in-memory, fall back to current user, then prefs
    final role = _userRole ?? 
        (_currentUser?.healthCenterId != null ? 'agent' : null) ??
        prefs.getString('user_role') ?? 'agent';
    _userRole = role; // Keep in-memory in sync
    await prefs.setString('user_role', role);
  }
}