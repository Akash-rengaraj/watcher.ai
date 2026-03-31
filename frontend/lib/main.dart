import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const VitalBridgeApp());
}

class VitalBridgeApp extends StatelessWidget {
  const VitalBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitalBridge Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> currentVitals = {};
  String aiSuggestion = "Initializing Neural Engine. Standing by for telemetry...";
  bool isConnected = true;
  Timer? _timer;

  // Configuration map bridging the 19 Python metrics directly to the UI
  final List<Map<String, dynamic>> metricsConfig = [
    {'key': 'BPM', 'title': 'Heart Rate', 'unit': 'BPM', 'color': Colors.redAccent},
    {'key': 'SpO2', 'title': 'SpO2', 'unit': '%', 'color': Colors.lightBlue},
    {'key': 'Temp_C', 'title': 'Core Temp', 'unit': '°C', 'color': Colors.orangeAccent},
    {'key': 'Pressure_hPa', 'title': 'Env Press', 'unit': 'hPa', 'color': Colors.indigoAccent},
    {'key': 'Respiratory_Rate', 'title': 'Resp Rate', 'unit': 'br/m', 'color': Colors.greenAccent},
    {'key': 'Max_Heart_Rate', 'title': 'Max HR', 'unit': 'BPM', 'color': Colors.grey},
    {'key': 'Heart_Rate_Reserve', 'title': 'HR Reserve', 'unit': 'BPM', 'color': Colors.purpleAccent},
    {'key': 'Cardiac_Output_mL', 'title': 'Cardiac Output', 'unit': 'mL', 'color': Colors.pinkAccent},
    {'key': 'Blood_Oxygen_Status', 'title': 'O2 Status', 'unit': '', 'color': Colors.cyanAccent},
    {'key': 'Temp_F', 'title': 'Temp (F)', 'unit': '°F', 'color': Colors.amberAccent},
    {'key': 'Altitude_m', 'title': 'Est Altitude', 'unit': 'm', 'color': Colors.blueGrey},
    {'key': 'Boiling_Point_C', 'title': 'Boiling Pt', 'unit': '°C', 'color': Colors.lightBlueAccent},
    {'key': 'BMR_Hourly_kcal', 'title': 'BMR Burn', 'unit': 'kCal/h', 'color': Colors.yellowAccent},
    {'key': 'Stress_Index', 'title': 'Stress Idx', 'unit': 'x', 'color': Colors.deepOrangeAccent},
    {'key': 'MAP_mmHg', 'title': 'MAP (Est)', 'unit': 'mmHg', 'color': Colors.red},
    {'key': 'Oxygen_Content_CaO2', 'title': 'Est CaO2', 'unit': 'mL/dL', 'color': Colors.tealAccent},
    {'key': 'Lung_Volume_L', 'title': 'Tidal Vol', 'unit': 'L', 'color': Colors.green},
    {'key': 'System_Latency_ms', 'title': 'Sys Latency', 'unit': 'ms', 'color': Colors.grey},
    {'key': 'Perfusion_Index', 'title': 'Perfusion Idx', 'unit': '%', 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    // 1000ms Polling Loop touching localhost as requested
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchVitals());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchVitals() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:7860/vitals'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          currentVitals = data['vitals'] ?? {};
          aiSuggestion = data['ai_suggestion'] ?? "";
          isConnected = true;
        });
      } else {
        setState(() => isConnected = false);
      }
    } catch (e) {
      setState(() => isConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive grid crossAxis count based on screen width
    int columns = MediaQuery.of(context).size.width > 900 ? 5 : (MediaQuery.of(context).size.width > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VITALBRIDGE PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Chip(
              backgroundColor: isConnected ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50),
              label: Row(
                children: [
                  Icon(Icons.circle, color: isConnected ? Colors.greenAccent : Colors.redAccent, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? "SYSTEM ONLINE" : "SENSOR OFFLINE", 
                    style: TextStyle(color: isConnected ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AI Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 18),
                      SizedBox(width: 8),
                      Text("GROQ NEURAL ASSESSMENT", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiSuggestion,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Vitals Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: metricsConfig.length,
                itemBuilder: (context, index) {
                  final metric = metricsConfig[index];
                  final val = currentVitals[metric['key']];
                  final displayVal = val != null ? val.toString() : '--';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(metric['title'], style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(displayVal, style: TextStyle(color: metric['color'], fontSize: 28, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 4),
                            Text(metric['unit'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
