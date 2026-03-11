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
                  const SizedBox(height: 24),
                  Text("Live Vitals", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallHealthIndicator(BuildContext context, int score) {
    Color statusColor = score > 80 ? AppTheme.mistyGreen : (score > 60 ? AppTheme.harshAmber : AppTheme.neonRed);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                       Container(
                         width: 48,
                         height: 48,
                         decoration: BoxDecoration(
                           color: AppTheme.primary.withOpacity(0.1),
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.person, color: AppTheme.primary),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             FittedBox(
                               fit: BoxFit.scaleDown,
                               alignment: Alignment.centerLeft,
                               child: Text("John Doe", style: Theme.of(context).textTheme.titleLarge),
                             ),
                             FittedBox(
                               fit: BoxFit.scaleDown,
                               alignment: Alignment.centerLeft,
                               child: Row(
                                 children: [
                                   Container(
                                     width: 8, height: 8,
                                     decoration: const BoxDecoration(color: AppTheme.mistyGreen, shape: BoxShape.circle),
                                   ),
                                   const SizedBox(width: 6),
                                   Text("Device: Connected", style: Theme.of(context).textTheme.bodyMedium),
                                 ],
                               ),
                             )
                           ],
                         ),
                       ),
                    ]
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "$score",
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: statusColor),
                      ),
                      const SizedBox(width: 4),
                      Text("Health\nScore", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text("AI Health Status", style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score > 80 
                      ? "John's vitals are currently within the normal optimal range. No immediate action is required." 
                      : "Warning: Vitals are experiencing abnormal fluctuations. Please prepare to review playbooks.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
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
