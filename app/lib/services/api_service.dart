import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/')) {
          // Token expired or invalid. Attempt refresh.
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            try {
              final prefs = await SharedPreferences.getInstance();
              final newToken = prefs.getString('auth_token');
              
              final headers = Map<String, dynamic>.from(e.requestOptions.headers);
              if (newToken != null) {
                headers['Authorization'] = 'Bearer $newToken';
              }

              final opts = Options(
                method: e.requestOptions.method,
                headers: headers,
              );
              final response = await _dio.request(
                e.requestOptions.path,
                options: opts,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } catch (retryErr) {
              // Refresh succeeded but retry failed - clear auth and let caller handle
              await _clearAuth();
              return handler.next(e);
            }
          } else {
            // Refresh failed, clear auth and let caller handle fallback
            await _clearAuth();
          }
        }
        return handler.next(e);
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      // Note: Do not use the main _dio instance here to avoid infinite loops if this fails with 401
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await refreshDio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        await prefs.setString('auth_token', response.data['token']);
        if (response.data['refreshToken'] != null) {
          await prefs.setString('refresh_token', response.data['refreshToken']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    // We intentionally do NOT remove the user ID here.
    // This allows the app to seamlessly fall back to offline mode using the
    // local database, rather than forcefully logging the user out.
  }

  // --- Auth Endpoints ---

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phoneNumber': phone,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/auth/register', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resetPassword(String phone, String newPassword) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'phoneNumber': phone,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      // If 401, the token is missing or invalid - this is expected for offline/demo mode
      if (e.response?.statusCode == 401) {
        throw ApiException('No valid authentication token. Please login.', statusCode: 401);
      }
      throw _handleError(e);
    }
  }
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/profile', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Patient Endpoints ---

  Future<List<dynamic>> getPatients() async {
    try {
      final response = await _dio.get('/patients');
      // Backend returns { success, data: [...], pagination: {} } — extract the list.
      final body = response.data;
      if (body is Map && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPatient(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/patients', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePatient(dynamic id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/patients/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Screening Endpoints ---

  Future<Map<String, dynamic>> createScreening(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/screenings', data: data);
      return response.data; // Server AI response
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getScreening(String id) async {
    try {
      final response = await _dio.get('/screenings/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getPatientScreenings(String patientId) async {
    try {
      final response = await _dio.get('/screenings/patient/$patientId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateScreening(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/screenings/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteScreening(String id) async {
    try {
      await _dio.delete('/screenings/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Preventive Care Endpoints ---

  Future<List<dynamic>> getPreventiveCareArticles() async {
    try {
      final response = await _dio.get('/preventive-care/articles');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getArticlesByCategory(String category) async {
    try {
      final response = await _dio.get('/preventive-care/articles/category/$category');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getArticle(String id) async {
    try {
      final response = await _dio.get('/preventive-care/articles/$id');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Analytics Endpoints ---

  Future<Map<String, dynamic>> getAnalyticsData(String type) async {
    try {
      final response = await _dio.get('/analytics/$type');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPopulationInsights() async {
    try {
      final response = await _dio.get('/analytics/population-insights');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> exportAnalyticsReport(String format) async {
    try {
      final response = await _dio.get('/analytics/export', 
        queryParameters: {'format': format});
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- User Management Endpoints ---

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/profile', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/users/change-password', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Health Center/Location Endpoints ---

  Future<List<dynamic>> getHealthCenters() async {
    try {
      final response = await _dio.get('/health-centers');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateHealthCenter(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/health-centers/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- Sync Endpoints ---

  Future<Map<String, dynamic>> syncPush(List<Map<String, dynamic>> data) async {
    try {
      final response = await _dio.post('/sync/push', data: {'changes': data});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> syncPull(DateTime lastSync) async {
    try {
      final response = await _dio.get('/sync/pull', 
        queryParameters: {'lastSync': lastSync.toIso8601String()});
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await _dio.get('/sync/status');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> syncBatch(Map<String, dynamic> batchData) async {
    try {
      final response = await _dio.post('/sync/batch', data: batchData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || 
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('Network connection failed. Please check your internet.', statusCode: e.response?.statusCode);
    }
    if (e.response != null) {
      var data = e.response?.data;
      String message = 'API Error: ${e.response?.statusCode}';
      
      // If data is a string, try parsing it as JSON
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is Map) {
        if (data.containsKey('errors') && data['errors'] is List && data['errors'].isNotEmpty) {
          final firstError = data['errors'][0];
          if (firstError is Map && firstError.containsKey('message')) {
            message = firstError['message'].toString();
          } else {
            message = data['message']?.toString() ?? message;
          }
        } else if (data.containsKey('error')) {
          message = data['error'].toString();
        } else if (data.containsKey('message')) {
          message = data['message'].toString();
        }
      }
      return ApiException(message, statusCode: e.response?.statusCode, data: data);
    }
    
    return ApiException(e.message ?? 'Unknown error occurred');
  }
}
