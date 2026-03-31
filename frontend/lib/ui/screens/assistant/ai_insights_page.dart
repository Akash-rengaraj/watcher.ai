import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';

class AIInsightsPage extends StatelessWidget {
  const AIInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
           builder: (context, provider, _) {
            final logs = provider.aiLogs;

            return Column(
              children: [
                _buildDailyBriefing(context),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100.0),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      // Reverse sort intuitively for display
                      return _buildLogCard(context, item.title, item.description, item.isWarning, item.timestamp);
                    },
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildDailyBriefing(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text("Daily Briefing", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Provider.of<AppProvider>(context).aiDailyBriefing,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, String title, String body, bool isWarning, DateTime time) {
    String timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWarning ? AppTheme.harshAmber : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Card(
                elevation: 0,
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isWarning ? AppTheme.harshAmber.withAlpha(100) : const Color(0xFFE2E8F0),
                    width: 1,
                  )
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
                          Text(timeStr, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(body, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
