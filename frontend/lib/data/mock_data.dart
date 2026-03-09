// Hive mock-like data models

class VitalData {
  final DateTime timestamp;
  final int heartRate; // bpm
  final int spO2; // %
  final double temperature; // C
  final int systolicBP; // mmHg
  final int diastolicBP; // mmHg

  VitalData({
    required this.timestamp,
    required this.heartRate,
    required this.spO2,
    required this.temperature,
    required this.systolicBP,
    required this.diastolicBP,
  });

  // Helper getters
  bool get isCritical => spO2 < 90 || heartRate > 120 || heartRate < 45 || systolicBP > 180 || systolicBP < 80;
  bool get isWarning => spO2 < 95 || heartRate > 100 || heartRate < 60 || systolicBP > 140 || systolicBP < 90 || temperature > 38.0;
}

class AILogEvent {
  final DateTime timestamp;
  final String title;
  final String description;
  final bool isWarning;

  AILogEvent({
    required this.timestamp,
    required this.title,
    required this.description,
    this.isWarning = false,
  });
}

class UserSettings {
  int targetRestingHR;
  int targetSystolicBP;
  int targetDiastolicBP;
  bool enableNotifications;
  
  String doctorPhone;
  String familyPhone1;
  String familyPhone2;

  UserSettings({
    this.targetRestingHR = 70,
    this.targetSystolicBP = 120,
    this.targetDiastolicBP = 80,
    this.enableNotifications = true,
    this.doctorPhone = "+15550199",
    this.familyPhone1 = "+15550188",
    this.familyPhone2 = "+15550177",
  });
}

// Generate massive historical array for lively charts
List<VitalData> mockHistoricalVitals = List.generate(150, (index) {
  // Generate points going backwards in time
  final hoursAgo = 150 - index;
  int baseHR = 70;
  int baseSpO2 = 98;
  
  // Create some natural waves and occasional spikes
  if (index > 40 && index < 60) {
    baseHR = 85; // Activity spike
    baseSpO2 = 95;
  }
  if (index > 100 && index < 110) {
    baseHR = 62; // Deep sleep
    baseSpO2 = 99;
  }

  return VitalData(
    timestamp: DateTime.now().subtract(Duration(hours: hoursAgo)),
    heartRate: baseHR + (index % 5) - 2,
    spO2: (baseSpO2 + (index % 2)).clamp(90, 100),
    temperature: 36.5 + ((index % 10) / 20.0),
    systolicBP: 120 + (index % 6),
    diastolicBP: 80 + (index % 4),
  );
});

List<AILogEvent> mockAILogs = [
  AILogEvent(
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    title: "Minor SpO2 Dip Detected",
    description: "SpO2 dropped to 94% accompanied by a slight elevation in Heart Rate. Recovered automatically within 15 minutes.",
    isWarning: true,
  ),
  AILogEvent(
    timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    title: "Vitals Stabilized",
    description: "Heart rate returned to baseline of 70 bpm. Post-operative recovery is tracking slightly ahead of average.",
  ),
  AILogEvent(
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    title: "Routine Check",
    description: "All sensors reporting correctly. ESP32 communication nominal.",
  ),
];
