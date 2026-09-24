import 'package:flutter/foundation.dart';
import '../models/screening.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class ScreeningProvider with ChangeNotifier {
  List<Screening> _screenings = [];
  Screening? _currentScreening;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineResult = false;

  // Draft answers from SymptomQuestionnaireScreen — held in memory
  // until ProcessingScreen submits them.
  int? _draftPatientId;
  String? _draftJointId;
  String? _draftSide;
  int _draftPainLevel = 0;
  String _draftStiffnessDuration = 'none';
  bool _draftSwelling = false;
  bool _draftPastInjury = false;
  String _draftPastInjuryDetail = '';
  int _draftMriKlGrade = 0;
  String? _draftGaitData;
  Map<String, dynamic> _draftSymptomsMap = {};
  Map<String, dynamic> _draftFunctionalMap = {};

  List<Screening> get screenings => _screenings;
  Screening? get currentScreening => _currentScreening;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineResult => _isOfflineResult;
  int? get draftPatientId => _draftPatientId;
  String? get draftJointId => _draftJointId;
  String? get draftSide => _draftSide;
  int get draftPainLevel => _draftPainLevel;
  String get draftStiffnessDuration => _draftStiffnessDuration;
  bool get draftSwelling => _draftSwelling;
  bool get draftPastInjury => _draftPastInjury;
  String get draftPastInjuryDetail => _draftPastInjuryDetail;
  int get draftMriKlGrade => _draftMriKlGrade;
  String? get draftGaitData => _draftGaitData;
  Map<String, dynamic> get draftSymptomsMap => _draftSymptomsMap;
  Map<String, dynamic> get draftFunctionalMap => _draftFunctionalMap;

  set draftGaitData(String? value) {
    _draftGaitData = value;
    notifyListeners();
  }

  set draftPatientId(int? value) {
    _draftPatientId = value;
    notifyListeners();
  }

  set draftJointId(String? value) {
    _draftJointId = value;
    notifyListeners();
  }

  set draftSide(String? value) {
    _draftSide = value;
    notifyListeners();
  }

  set draftPainLevel(int value) {
    _draftPainLevel = value;
    notifyListeners();
  }

  set draftStiffnessDuration(String value) {
    _draftStiffnessDuration = value;
    notifyListeners();
  }

  set draftSwelling(bool value) {
    _draftSwelling = value;
    notifyListeners();
  }

  set draftPastInjury(bool value) {
    _draftPastInjury = value;
    notifyListeners();
  }

  set draftPastInjuryDetail(String value) {
    _draftPastInjuryDetail = value;
    notifyListeners();
  }

  set draftMriKlGrade(int value) {
    _draftMriKlGrade = value;
    notifyListeners();
  }

  set draftSymptomsMap(Map<String, dynamic> value) {
    _draftSymptomsMap = value;
    notifyListeners();
  }

  set draftFunctionalMap(Map<String, dynamic> value) {
    _draftFunctionalMap = value;
    notifyListeners();
  }

  Future<void> loadScreenings() async {
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
        orderBy: 'screening_date DESC',
      );

      _screenings = screeningsData.map((data) => Screening.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadScreeningsByPatient(int patientId) async {
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
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'screening_date DESC',
      );

      _screenings = screeningsData.map((data) => Screening.fromMap(data)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveScreening(Screening screening) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      var finalScreening = screening;
      
      try {
        // Find the patient's server ID to associate the screening
        final patients = await db.query('patients', where: 'id = ?', whereArgs: [screening.patientId]);
        final serverPatientId = patients.isNotEmpty ? patients.first['server_id'] as String? : null;
        
        if (serverPatientId != null) {
          // Parse gait features
          List<double> gaitFeatures = [];
          if (screening.gaitData != null) {
            try {
              final parsed = screening.gaitData!.replaceAll('[', '').replaceAll(']', '').split(',');
              gaitFeatures = parsed.map((e) => double.tryParse(e.trim()) ?? 0.0).toList();
            } catch (_) {}
          }
          
          final apiData = {
            'patientId': serverPatientId,
            'painLevel': screening.painLevel,
            'stiffnessDuration': screening.stiffnessDuration,
            'swelling': screening.swelling,
            'pastInjury': screening.pastInjury,
            'gaitFeatures': gaitFeatures,
          };
          
          final response = await ApiService().createScreening(apiData);
          final serverResult = response['screening'];
          
          // Use server's AI calculation
          finalScreening = screening.copyWith(
            serverId: serverResult['_id'],
            riskLevel: serverResult['riskLevel'],
            confidence: serverResult['confidence']?.toDouble(),
            contributingFactors: serverResult['contributingFactors'] != null 
                ? (serverResult['contributingFactors'] as List).join(',') 
                : '',
            aiReasoning: serverResult['aiReasoning'],
            doctorRecommendations: serverResult['doctorRecommendations'],
            synced: true,
          );
          _isOfflineResult = false;
        } else {
          // We don't have a serverPatientId, we can't sync this screening yet.
          // Fall back to offline flow
          _isOfflineResult = true;
        }
      } catch (apiError) {
        // Fall back to offline calculation that was passed in `screening`
        _isOfflineResult = true;
      }
      
      // Save locally
      final id = await db.insert('screenings', finalScreening.toMap());
      finalScreening = finalScreening.copyWith(id: id);
      
      if (_isOfflineResult) {
        // Add to sync queue for later
        await db.addToSyncQueue('screenings', id, 'insert', finalScreening.toMap());
      }
      
      _screenings.insert(0, finalScreening);
      _currentScreening = finalScreening;
      
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

  Future<bool> updateScreening(Screening screening) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      await db.update(
        'screenings',
        screening.toMap(),
        where: 'id = ?',
        whereArgs: [screening.id],
      );

      final index = _screenings.indexWhere((s) => s.id == screening.id);
      if (index != -1) {
        _screenings[index] = screening;
      }

      if (_currentScreening?.id == screening.id) {
        _currentScreening = screening;
      }

      // Add to sync queue
      await db.addToSyncQueue('screenings', screening.id!, 'update', screening.toMap());

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

  Future<bool> deleteScreening(int screeningId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      await db.delete(
        'screenings',
        where: 'id = ?',
        whereArgs: [screeningId],
      );

      _screenings.removeWhere((s) => s.id == screeningId);
      
      if (_currentScreening?.id == screeningId) {
        _currentScreening = null;
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

  void setCurrentScreening(Screening screening) {
    _currentScreening = screening;
    notifyListeners();
  }

  void clearCurrentScreening() {
    _currentScreening = null;
    notifyListeners();
  }

  Future<Map<String, int>> getRiskDistribution() async {
    try {
      final db = DatabaseHelper();
      final screeningsData = await db.query('screenings');

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
      return {'low': 0, 'medium': 0, 'high': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getScreeningsOverTime() async {
    try {
      final db = DatabaseHelper();
      final screeningsData = await db.query(
        'screenings',
        orderBy: 'screening_date ASC',
      );

      final Map<String, int> dateCount = {};
      
      for (var data in screeningsData) {
        final dateStr = data['screening_date'] as String;
        final date = DateTime.parse(dateStr);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        dateCount[key] = (dateCount[key] ?? 0) + 1;
      }

      return dateCount.entries.map((e) => {
        'date': e.key,
        'count': e.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getTotalScreenings() async {
    try {
      final db = DatabaseHelper();
      final screeningsData = await db.query('screenings');
      return screeningsData.length;
    } catch (e) {
      return 0;
    }
  }

  /// Store symptom questionnaire answers in-memory so ProcessingScreen can use them.
  void setDraftAnswers({
    required int patientId,
    String? jointId,
    String? side,
    required int painLevel,
    required String stiffnessDuration,
    required bool swelling,
    required bool pastInjury,
    required String pastInjuryDetail,
    int mriKlGrade = 0,
    Map<String, dynamic>? symptomsMap,
    Map<String, dynamic>? functionalMap,
  }) {
    _draftPatientId = patientId;
    _draftJointId = jointId;
    _draftSide = side;
    _draftPainLevel = painLevel;
    _draftStiffnessDuration = stiffnessDuration;
    _draftSwelling = swelling;
    _draftPastInjury = pastInjury;
    _draftPastInjuryDetail = pastInjuryDetail;
    _draftMriKlGrade = mriKlGrade;
    _draftSymptomsMap = symptomsMap ?? {};
    _draftFunctionalMap = functionalMap ?? {};
    notifyListeners();
  }

  void clearDraft() {
    _draftPatientId = null;
    _draftJointId = null;
    _draftSide = null;
    _draftPainLevel = 0;
    _draftStiffnessDuration = 'none';
    _draftSwelling = false;
    _draftPastInjury = false;
    _draftPastInjuryDetail = '';
    _draftMriKlGrade = 0;
    _draftGaitData = null;
    _draftSymptomsMap = {};
    _draftFunctionalMap = {};
  }

  void setDraftGaitData(String data) {
    _draftGaitData = data;
    notifyListeners();
  }

  /// Generate contributing factors from questionnaire responses
  List<String> generateContributingFactors() {
    final factors = <String>[];
    
    // Pain level factors
    if (_draftPainLevel >= 7) {
      factors.add('Severe pain symptoms (${_draftPainLevel}/10)');
    } else if (_draftPainLevel >= 4) {
      factors.add('Moderate pain symptoms (${_draftPainLevel}/10)');
    }
    
    // Stiffness factors
    if (_draftStiffnessDuration != 'none') {
      if (_draftStiffnessDuration == '>60') {
        factors.add('Prolonged morning stiffness (>60 min)');
      } else if (_draftStiffnessDuration == '30-60') {
        factors.add('Moderate morning stiffness (30-60 min)');
      } else {
        factors.add('Mild morning stiffness (<30 min)');
      }
    }
    
    // Swelling factor
    if (_draftSwelling) {
      factors.add('Joint swelling present');
    }
    
    // Past injury factor
    if (_draftPastInjury) {
      factors.add('History of joint injury/surgery');
      if (_draftPastInjuryDetail.isNotEmpty) {
        factors.add('Past injury: ${_draftPastInjuryDetail}');
      }
    }
    
    // MRI/KL Grade factors
    if (_draftMriKlGrade > 0) {
      if (_draftMriKlGrade == 1) {
        factors.add('MRI indicates mild joint changes (KL Grade 1)');
      } else if (_draftMriKlGrade == 2) {
        factors.add('MRI indicates definite osteophytes (KL Grade 2)');
      } else if (_draftMriKlGrade == 3) {
        factors.add('MRI indicates structural joint damage (KL Grade 3)');
      } else if (_draftMriKlGrade == 4) {
        factors.add('MRI indicates severe joint damage (KL Grade 4)');
      }
    }
    
    // Expanded symptoms factors
    if (_draftSymptomsMap.isNotEmpty) {
      final painChars = _draftSymptomsMap['pain_characteristics'] as Map<String, dynamic>?;
      if (painChars != null) {
        final selectedPain = painChars.entries.where((e) => e.value == true).map((e) => e.key).toList();
        if (selectedPain.isNotEmpty) {
          factors.add('Pain characteristics: ${selectedPain.join(', ')}');
        }
      }
      
      final stiffnessTriggers = _draftSymptomsMap['stiffness_triggers'] as Map<String, dynamic>?;
      if (stiffnessTriggers != null) {
        final selectedTriggers = stiffnessTriggers.entries.where((e) => e.value == true).map((e) => e.key).toList();
        if (selectedTriggers.isNotEmpty) {
          factors.add('Stiffness triggers: ${selectedTriggers.join(', ')}');
        }
      }
      
      final otherSymptoms = _draftSymptomsMap['other_symptoms'] as Map<String, dynamic>?;
      if (otherSymptoms != null) {
        final selectedOthers = otherSymptoms.entries.where((e) => e.value == true).map((e) => e.key).toList();
        if (selectedOthers.isNotEmpty) {
          factors.add('Other symptoms: ${selectedOthers.join(', ')}');
        }
      }
    }
    
    // Functional assessment factors
    if (_draftFunctionalMap.isNotEmpty) {
      final highDifficultyItems = _draftFunctionalMap.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .toList();
      if (highDifficultyItems.isNotEmpty) {
        factors.add('Functional limitations: ${highDifficultyItems.join(', ')}');
      }
    }
    
    return factors;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
