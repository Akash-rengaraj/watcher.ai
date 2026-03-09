import 'package:flutter/material.dart';
import '../../core/emergency_interceptor.dart';
import 'home/live_monitor_page.dart';
import 'trends/temporal_analytics_page.dart';
import 'assistant/ai_insights_page.dart';
import 'action/caregiver_hub_page.dart';
import 'settings/settings_calibration_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const LiveMonitorPage(),
    const TemporalAnalyticsPage(),
    const AIInsightsPage(),
    const CaregiverHubPage(),
    const SettingsCalibrationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // The EmergencyInterceptor wraps the Scaffold. 
    // This allows the interceptor to cover the BottomNavigationBar as well.
    return EmergencyInterceptor(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: "Live"),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Trends"),
            BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Logs"),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "Action"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
        ),
      ),
    );
  }
}
