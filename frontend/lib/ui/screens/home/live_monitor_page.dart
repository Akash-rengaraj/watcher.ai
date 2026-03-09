import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';

class LiveMonitorPage extends StatelessWidget {
  const LiveMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Monitor"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          GestureDetector(
            onDoubleTap: () {
              context.read<AppProvider>().triggerEmergency();
            },
            child: Container(
              width: 50,
              color: Colors.transparent, // Invisible wide trigger 
            ),
          )
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final vitals = provider.currentVitals;
          final score = provider.healthScore;
          
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildOverallHealthIndicator(context, score),
                  const SizedBox(height: 40),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate a responsive aspect ratio
                      final double itemWidth = (constraints.maxWidth - 16) / 2;
                      final double itemHeight = 120; // Target height
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: itemWidth / itemHeight,
                        children: [
                          _MetricCard(
                            title: "Heart Rate",
                            value: "${vitals.heartRate}",
                            unit: "bpm",
                            icon: Icons.favorite,
                            color: vitals.isCritical ? AppTheme.neonRed : (vitals.isWarning ? AppTheme.harshAmber : AppTheme.mistyGreen),
                          ),
                          _MetricCard(
                            title: "SpO2",
                            value: "${vitals.spO2}",
                            unit: "%",
                            icon: Icons.air,
                            color: vitals.isCritical ? AppTheme.neonRed : (vitals.isWarning ? AppTheme.harshAmber : AppTheme.mistyGreen),
                          ),
                          _MetricCard(
                            title: "Temperature",
                            value: vitals.temperature.toStringAsFixed(1),
                            unit: "°C",
                            icon: Icons.thermostat,
                            color: vitals.isWarning ? AppTheme.harshAmber : AppTheme.mistyGreen,
                          ),
                          _MetricCard(
                            title: "Blood Pressure",
                            value: "${vitals.systolicBP}/${vitals.diastolicBP}",
                            unit: "mmHg",
                            icon: Icons.bloodtype,
                            color: vitals.isCritical ? AppTheme.neonRed : (vitals.isWarning ? AppTheme.harshAmber : AppTheme.mistyGreen),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "ESP32 Connected | Last synced: Just now",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallHealthIndicator(BuildContext context, int score) {
    Color glowColor = score > 80 ? AppTheme.mistyGreen : (score > 60 ? AppTheme.harshAmber : AppTheme.neonRed);

    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: AppTheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(glowColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "$score",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: glowColor,
                      shadows: [
                        Shadow(color: glowColor.withOpacity(0.5), blurRadius: 10),
                      ]
                    ),
                  ),
                ),
                Text(
                  "Overall Stable",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
