import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/// Analytics Service - Handles all analytics calculations and reporting
/// 
/// This service provides comprehensive analytics for the OsteoSense application
/// including risk distribution, screening trends, joint affection statistics,
/// and population insights.
class AnalyticsService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Get risk distribution statistics
  /// Returns count of screenings by risk level (low, medium, high)
  Future<Map<String, int>> getRiskDistribution() async {
    try {
      final screeningsData = await _db.query('screenings');

      int low = 0;
      int medium = 0;
      int high = 0;

      for (var data in screeningsData) {
        final riskLevel = data['risk_level'] as String?;
        if (riskLevel != null) {
          switch (riskLevel.toLowerCase()) {
            case 'low':
              low++;
              break;
            case 'medium':
              medium++;
              break;
            case 'high':
              high++;
              break;
          }
        }
      }

      return {'low': low, 'medium': medium, 'high': high};
    } catch (e) {
      if (kDebugMode) {
        print('Error getting risk distribution: $e');
      }
      return {'low': 0, 'medium': 0, 'high': 0};
    }
  }

  /// Get screening trends over time
  /// 
  /// Parameters:
  /// - period: 'week' for last 7 days, 'month' for last 30 days
  /// Returns list of screening counts grouped by date
  Future<List<Map<String, dynamic>>> getScreeningTrends({String period = 'week'}) async {
    try {
      final screeningsData = await _db.query(
        'screenings',
        orderBy: 'screening_date ASC',
      );

      final Map<String, int> dateCount = {};
      final now = DateTime.now();
      final cutoffDate = period == 'week' 
          ? now.subtract(const Duration(days: 7))
          : now.subtract(const Duration(days: 30));

      for (var data in screeningsData) {
        final dateStr = data['screening_date'] as String;
        final date = DateTime.parse(dateStr);
        
        if (date.isAfter(cutoffDate)) {
          final key = period == 'week'
              ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
              : '${date.year}-${date.month.toString().padLeft(2, '0')}';
          dateCount[key] = (dateCount[key] ?? 0) + 1;
        }
      }

      // Fill in missing dates with 0
      final result = <Map<String, dynamic>>[];
      if (period == 'week') {
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          result.add({
            'date': key,
            'count': dateCount[key] ?? 0,
          });
        }
      } else {
        // Last 30 days
        for (int i = 29; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          result.add({
            'date': key,
            'count': dateCount[key] ?? 0,
          });
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting screening trends: $e');
      }
      return [];
    }
  }

  /// Get joint affection statistics
  /// Returns distribution of screenings by joint type
  /// Now uses the joint_id field directly from screenings
  Future<Map<String, int>> getJointAffection() async {
    try {
      final screeningsData = await _db.query('screenings');

      int knee = 0;
      int hip = 0;
      int ankle = 0;
      int shoulder = 0;
      int elbow = 0;
      int wrist = 0;
      int other = 0;

      for (var data in screeningsData) {
        final jointId = data['joint_id'] as String?;
        if (jointId != null) {
          switch (jointId.toLowerCase()) {
            case 'knee':
              knee++;
              break;
            case 'hip':
              hip++;
              break;
            case 'ankle':
              ankle++;
              break;
            case 'shoulder':
              shoulder++;
              break;
            case 'elbow':
              elbow++;
              break;
            case 'wrist':
              wrist++;
              break;
            default:
              other++;
          }
        } else {
          other++;
        }
      }

      return {
        'knee': knee,
        'hip': hip,
        'ankle': ankle,
        'shoulder': shoulder,
        'elbow': elbow,
        'wrist': wrist,
        'other': other,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting joint affection: $e');
      }
      return {
        'knee': 0,
        'hip': 0,
        'ankle': 0,
        'shoulder': 0,
        'elbow': 0,
        'wrist': 0,
        'other': 0,
      };
    }
  }

  /// Get overall statistics
  /// Returns comprehensive statistics for the dashboard
  Future<Map<String, dynamic>> getOverallStatistics() async {
    try {
      final patientsData = await _db.query('patients');
      final screeningsData = await _db.query('screenings');

      final totalPatients = patientsData.length;
      final totalScreenings = screeningsData.length;

      // Calculate high risk count
      int highRiskCount = 0;
      for (var data in screeningsData) {
        final riskLevel = data['risk_level'] as String?;
        if (riskLevel?.toLowerCase() == 'high') {
          highRiskCount++;
        }
      }

      // Calculate unique patients screened
      final uniquePatientIds = screeningsData
          .map((s) => s['patient_id'] as int)
          .toSet();
      final patientsScreened = uniquePatientIds.length;

      // Calculate average confidence score
      double totalConfidence = 0;
      int confidenceCount = 0;
      for (var data in screeningsData) {
        final confidence = data['confidence'] as double?;
        if (confidence != null) {
          totalConfidence += confidence;
          confidenceCount++;
        }
      }
      final avgConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;

      // Calculate weekly screenings
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      int weeklyScreenings = 0;
      for (var data in screeningsData) {
        final dateStr = data['screening_date'] as String;
        final date = DateTime.parse(dateStr);
        if (date.isAfter(weekAgo)) {
          weeklyScreenings++;
        }
      }

      return {
        'totalPatients': totalPatients,
        'totalScreenings': totalScreenings,
        'highRiskCount': highRiskCount,
        'patientsScreened': patientsScreened,
        'avgConfidence': avgConfidence,
        'weeklyScreenings': weeklyScreenings,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting overall statistics: $e');
      }
      return {
        'totalPatients': 0,
        'totalScreenings': 0,
        'highRiskCount': 0,
        'patientsScreened': 0,
        'avgConfidence': 0.0,
        'weeklyScreenings': 0,
      };
    }
  }

  /// Get patient-specific analytics
  /// Returns analytics for a specific patient
  Future<Map<String, dynamic>> getPatientAnalytics(int patientId) async {
    try {
      final screeningsData = await _db.query(
        'screenings',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'screening_date DESC',
      );

      if (screeningsData.isEmpty) {
        return {
          'totalScreenings': 0,
          'lastScreeningDate': null,
          'riskTrend': [],
          'avgConfidence': 0.0,
          'currentRiskLevel': null,
        };
      }

      final totalScreenings = screeningsData.length;
      final lastScreeningDate = screeningsData.first['screening_date'] as String;

      // Calculate risk trend over time
      final riskTrend = <Map<String, dynamic>>[];
      for (var data in screeningsData.reversed) {
        riskTrend.add({
          'date': data['screening_date'] as String,
          'riskLevel': data['risk_level'] as String?,
          'confidence': data['confidence'] as double?,
        });
      }

      // Calculate average confidence
      double totalConfidence = 0;
      int confidenceCount = 0;
      for (var data in screeningsData) {
        final confidence = data['confidence'] as double?;
        if (confidence != null) {
          totalConfidence += confidence;
          confidenceCount++;
        }
      }
      final avgConfidence = confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0;

      final currentRiskLevel = screeningsData.first['risk_level'] as String?;

      return {
        'totalScreenings': totalScreenings,
        'lastScreeningDate': lastScreeningDate,
        'riskTrend': riskTrend,
        'avgConfidence': avgConfidence,
        'currentRiskLevel': currentRiskLevel,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting patient analytics: $e');
      }
      return {
        'totalScreenings': 0,
        'lastScreeningDate': null,
        'riskTrend': [],
        'avgConfidence': 0.0,
        'currentRiskLevel': null,
      };
    }
  }

  /// Get population insights
  /// Returns AI-powered insights based on screening data
  Future<String> getPopulationInsights() async {
    try {
      final stats = await getOverallStatistics();
      final jointAff = await getJointAffection();

      final totalPatients = stats['totalPatients'] as int;
      final highRiskCount = stats['highRiskCount'] as int;
      final highRiskPercentage = totalPatients > 0 
          ? (highRiskCount / totalPatients * 100).toStringAsFixed(1)
          : '0.0';

      // Identify most affected joint
      String mostAffectedJoint = 'knee';
      int maxCount = jointAff['knee'] as int;
      if (jointAff['hip'] as int > maxCount) {
        mostAffectedJoint = 'hip';
        maxCount = jointAff['hip'] as int;
      }
      if (jointAff['ankle'] as int > maxCount) {
        mostAffectedJoint = 'ankle';
        maxCount = jointAff['ankle'] as int;
      }

      // Generate insights
      final insights = StringBuffer();
      
      if (highRiskCount > 0) {
        insights.writeln('High risk patients: $highRiskCount ($highRiskPercentage% of total)');
      }
      
      if (mostAffectedJoint != 'other' && maxCount > 0) {
        insights.writeln('Most affected joint: $mostAffectedJoint');
      }
      
      final weeklyScreenings = stats['weeklyScreenings'] as int;
      if (weeklyScreenings > 0) {
        insights.writeln('Weekly screenings: $weeklyScreenings');
      }

      if (insights.isEmpty) {
        return 'Start conducting screenings to generate population insights.';
      }

      return insights.toString().trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting population insights: $e');
      }
      return 'Unable to generate insights at this time.';
    }
  }

  /// Export analytics data
  /// Returns formatted data for export (CSV format)
  Future<String> exportAnalytics({String format = 'csv'}) async {
    try {
      final screeningsData = await _db.query(
        'screenings',
        orderBy: 'screening_date DESC',
      );

      if (screeningsData.isEmpty) {
        return 'No data to export';
      }

      if (format == 'csv') {
        final buffer = StringBuffer();
        buffer.writeln('Date,Patient ID,Joint ID,Risk Level,Confidence,Pain Level,Stiffness,Swelling,Past Injury');
        
        for (var data in screeningsData) {
          buffer.writeln(
            '${data['screening_date']},'
            '${data['patient_id']},'
            '${data['joint_id']},'
            '${data['risk_level']},'
            '${data['confidence']},'
            '${data['pain_level']},'
            '${data['stiffness_duration']},'
            '${data['swelling']},'
            '${data['past_injury']}'
          );
        }
        
        return buffer.toString();
      }

      return 'Unsupported format';
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting analytics: $e');
      }
      return 'Error exporting data';
    }
  }

  /// Get demographic breakdown
  /// Returns patient demographics by age group and gender
  Future<Map<String, dynamic>> getDemographicBreakdown() async {
    try {
      final patientsData = await _db.query('patients');

      int maleCount = 0;
      int femaleCount = 0;
      int otherCount = 0;

      final ageGroups = <String, int>{
        '0-30': 0,
        '31-40': 0,
        '41-50': 0,
        '51-60': 0,
        '60+': 0,
      };

      for (var data in patientsData) {
        // Gender breakdown
        final gender = data['gender'] as String?;
        if (gender != null) {
          switch (gender.toLowerCase()) {
            case 'male':
              maleCount++;
              break;
            case 'female':
              femaleCount++;
              break;
            default:
              otherCount++;
          }
        }

        // Age group breakdown
        final age = data['age'] as int?;
        if (age != null) {
          if (age <= 30) {
            ageGroups['0-30'] = (ageGroups['0-30'] ?? 0) + 1;
          } else if (age <= 40) {
            ageGroups['31-40'] = (ageGroups['31-40'] ?? 0) + 1;
          } else if (age <= 50) {
            ageGroups['41-50'] = (ageGroups['41-50'] ?? 0) + 1;
          } else if (age <= 60) {
            ageGroups['51-60'] = (ageGroups['51-60'] ?? 0) + 1;
          } else {
            ageGroups['60+'] = (ageGroups['60+'] ?? 0) + 1;
          }
        }
      }

      return {
        'gender': {
          'male': maleCount,
          'female': femaleCount,
          'other': otherCount,
        },
        'ageGroups': ageGroups,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting demographic breakdown: $e');
      }
      return {
        'gender': {'male': 0, 'female': 0, 'other': 0},
        'ageGroups': {'0-30': 0, '31-40': 0, '41-50': 0, '51-60': 0, '60+': 0},
      };
    }
  }

  /// Get sync status
  /// Returns information about data synchronization
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final syncQueueData = await _db.query('sync_queue');
      
      int pendingSync = 0;
      int failedSync = 0;
      
      for (var data in syncQueueData) {
        final retryCount = data['retry_count'] as int? ?? 0;
        if (retryCount == 0) {
          pendingSync++;
        } else {
          failedSync++;
        }
      }

      // Check synced status of patients and screenings
      final patientsData = await _db.query('patients');
      final screeningsData = await _db.query('screenings');

      int syncedPatients = 0;
      int syncedScreenings = 0;

      for (var data in patientsData) {
        if ((data['synced'] as int? ?? 0) == 1) {
          syncedPatients++;
        }
      }

      for (var data in screeningsData) {
        if ((data['synced'] as int? ?? 0) == 1) {
          syncedScreenings++;
        }
      }

      return {
        'pendingSync': pendingSync,
        'failedSync': failedSync,
        'totalPatients': patientsData.length,
        'syncedPatients': syncedPatients,
        'totalScreenings': screeningsData.length,
        'syncedScreenings': syncedScreenings,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sync status: $e');
      }
      return {
        'pendingSync': 0,
        'failedSync': 0,
        'totalPatients': 0,
        'syncedPatients': 0,
        'totalScreenings': 0,
        'syncedScreenings': 0,
      };
    }
  }
}