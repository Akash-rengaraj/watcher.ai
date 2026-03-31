import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/mock_data.dart';

class AppProvider with ChangeNotifier {
  // Mock Hive Data Access
  List<VitalData> _vitals = List.from(mockHistoricalVitals);
  List<AILogEvent> _aiLogs = List.from(mockAILogs);
  UserSettings _settings = UserSettings();
  
  // Emergency State
  bool _isEmergencyActive = false;
  String _emergencyContext = "";
  
  // Dynamic AI State
  String _aiDailyBriefing = "Connecting to remote AI Insights server...";

  // Real-time mockup
  Timer? _timer;

  AppProvider() {
  // Fetch real ESP32 data from backend every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isEmergencyActive) {
        _fetchRealVitals();
      }
    });
  }

  // Getters
  List<VitalData> get vitals => _vitals;
  List<AILogEvent> get aiLogs => _aiLogs;
  UserSettings get settings => _settings;
  bool get isEmergencyActive => _isEmergencyActive;
  String get emergencyContext => _emergencyContext;
  String get aiDailyBriefing => _aiDailyBriefing;

  VitalData get currentVitals => _vitals.last;
  
  // "Overall Health Rate" calculation (mock)
  int get healthScore {
    int score = 100;
    bool isCritical = false;

    if (currentVitals.spO2 < 95) score -= 15;
    if (currentVitals.spO2 < 90) { score -= 25; isCritical = true; }
    if (currentVitals.heartRate > 100 || currentVitals.heartRate < 60) score -= 10;
    if (currentVitals.heartRate > 120 || currentVitals.heartRate < 45) { score -= 20; isCritical = true; }
    if (currentVitals.temperature > 37.5) score -= 5;
    if (currentVitals.systolicBP > 140 || currentVitals.diastolicBP > 90) score -= 10;
    if (currentVitals.systolicBP > 180) { score -= 20; isCritical = true; }

    int finalScore = score.clamp(0, 100);
    if (isCritical && finalScore > 49) {
      finalScore = 49; // Force red zone if any critical vital
    }
    return finalScore;
  }

  // Settings Actions
  void updateRestingHR(int hr) {
    _settings.targetRestingHR = hr;
    notifyListeners();
  }

  void updateTargetBP(int systolic, int diastolic) {
    _settings.targetSystolicBP = systolic;
    _settings.targetDiastolicBP = diastolic;
    notifyListeners();
  }

  void updateContacts(String doctor, String fam1, String fam2) {
    _settings.doctorPhone = doctor;
    _settings.familyPhone1 = fam1;
    _settings.familyPhone2 = fam2;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    _settings.enableNotifications = val;
    notifyListeners();
  }

  // Emergency Action "Simulate Drop"
  void triggerEmergency({String contextMsg = "SPO2 CRITICAL: Elevate head, ensure airway is clear", bool injectMock = true}) {
    if (injectMock) {
      // Inject a critical vital reading to trigger UI color changes underneath the overlay
      var droppingVital = VitalData(
        timestamp: DateTime.now(),
        heartRate: 135, // Tachycardia
        spO2: 82,       // Hypoxia
        temperature: _vitals.last.temperature,
        systolicBP: 160,
        diastolicBP: 95,
      );
      _vitals.add(droppingVital);
    }

    _emergencyContext = contextMsg;
    _isEmergencyActive = true;
    notifyListeners();
  }

  void dismissEmergency() {
    _isEmergencyActive = false;
    // Auto-recover vitals after dismissal for demo purposes
    var recoveredVital = VitalData(
      timestamp: DateTime.now(),
      heartRate: 85, 
      spO2: 95,      
      temperature: _vitals.last.temperature,
      systolicBP: 130,
      diastolicBP: 85,
    );
    _vitals.add(recoveredVital);
    notifyListeners();
  }

  // Real-time ESP32 Fetcher
  Future<void> _fetchRealVitals() async {
    try {
      final url = Uri.parse('https://watcher-ai-79fv.onrender.com/vitals');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        if (respData['data'] == null) return; // Still waiting for sensor
        
        final measured = respData['data']['measured'];
        final detailedPlan = respData['detailed_wellness_plan'];
        
        var newData = VitalData(
          timestamp: DateTime.now(),
          heartRate: (measured['bpm'] as num).toInt(),
          spO2: (measured['spo2'] as num).toInt(),
          temperature: (measured['temp'] as num).toDouble(),
          systolicBP: _vitals.isNotEmpty ? _vitals.last.systolicBP : 120, // Keep mock BP since sensor doesn't have it
          diastolicBP: _vitals.isNotEmpty ? _vitals.last.diastolicBP : 80,
        );

        // Prevent rapid UI flickering if the ESP32 hasn't pushed a new data point yet
        if (_vitals.isEmpty || _vitals.last.heartRate != newData.heartRate || _vitals.last.spO2 != newData.spO2) {
          _vitals.add(newData);
          if (_vitals.length > 200) _vitals.removeAt(0);
        }
        
        if (detailedPlan != null) {
          final String newDescription = detailedPlan['immediate_actions'][0].toString();
          final String envStr = detailedPlan['hydration_and_environment'].toString();
          final String monitorStr = detailedPlan['monitoring_advice'].toString();
          
          _aiDailyBriefing = "$envStr\n$monitorStr\n\nNote: ${detailedPlan['disclaimer']}";
          
          if (_aiLogs.isEmpty || _aiLogs.first.description != newDescription) {
            final newAiLog = AILogEvent(
              timestamp: DateTime.now(),
              title: "Live Action Plan",
              description: newDescription,
              isWarning: newData.spO2 < 95 || newData.heartRate > 100,
            );
            _aiLogs.insert(0, newAiLog);
            if (_aiLogs.length > 50) _aiLogs.removeLast();
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
