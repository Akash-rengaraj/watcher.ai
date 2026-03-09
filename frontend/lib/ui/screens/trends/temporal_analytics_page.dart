import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../data/mock_data.dart';

class TemporalAnalyticsPage extends StatefulWidget {
  const TemporalAnalyticsPage({super.key});

  @override
  State<TemporalAnalyticsPage> createState() => _TemporalAnalyticsPageState();
}

class _TemporalAnalyticsPageState extends State<TemporalAnalyticsPage> {
  String _selectedRange = "12H";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Temporal Analytics"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
           builder: (context, provider, _) {
            final allVitals = provider.vitals;
            
            // Filter based on toggle
            int itemsToTake = allVitals.length;
            if (_selectedRange == "12H") itemsToTake = 20;
            if (_selectedRange == "24H") itemsToTake = 60;
            if (_selectedRange == "7D") itemsToTake = allVitals.length;
            
            // Ensure we don't take more than exists
            if (itemsToTake > allVitals.length) itemsToTake = allVitals.length;
            
            final vitals = allVitals.sublist(allVitals.length - itemsToTake);

            return Column(
              children: [
                _buildToggleButtons(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                    children: [
                      _buildChartCard(context, "Heart Rate", vitals, (v) => v.heartRate.toDouble(), AppTheme.harshAmber),
                      const SizedBox(height: 24),
                      _buildChartCard(context, "SpO2 Levels", vitals, (v) => v.spO2.toDouble(), AppTheme.mistyGreen),
                      const SizedBox(height: 24),
                      _buildChartCard(context, "Temperature", vitals, (v) => v.temperature, Colors.blueAccent),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
           return SizedBox(
             width: constraints.maxWidth,
             child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "12H", label: Text("12H")),
                ButtonSegment(value: "24H", label: Text("24H")),
                ButtonSegment(value: "7D", label: Text("7D")),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedRange = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                selectedForegroundColor: AppTheme.background,
                selectedBackgroundColor: AppTheme.textPrimary,
              ),
                     ),
           );
        }
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, List<VitalData> data, double Function(VitalData) valueSelector, Color color) {
    
    // Safety check
    if (data.isEmpty) return const SizedBox.shrink();

    // Map data to FlSpots
    double minX = 0;
    double maxX = (data.length - 1).toDouble();
    double minY = valueSelector(data.first);
    double maxY = valueSelector(data.first);

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
        double val = valueSelector(data[i]);
        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
        spots.add(FlSpot(i.toDouble(), val));
    }
    
    // Add some padding to Y axis
    minY = minY - ((maxY - minY).abs() * 0.1) - 1;
    maxY = maxY + ((maxY - minY).abs() * 0.1) + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // give fl_chart breathing room
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
                    ),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppTheme.surface.withAlpha(200),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              spot.y.toStringAsFixed(1),
                              TextStyle(color: color, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.white54));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (data.length / 5).ceil().toDouble() > 0 ? (data.length / 5).ceil().toDouble() : 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < data.length) {
                                // Calculate hours ago based on the timestamp
                                final hoursDiff = DateTime.now().difference(data[index].timestamp).inHours;
                                if (hoursDiff == 0) return const Padding(padding: EdgeInsets.only(top: 8), child: Text("Now", style: TextStyle(fontSize: 10, color: Colors.white54)));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text("-$hoursDiff h", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.3),
                              color.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
