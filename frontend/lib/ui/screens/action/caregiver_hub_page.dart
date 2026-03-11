import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_provider.dart';

class CaregiverHubPage extends StatelessWidget {
  const CaregiverHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Caregiver Hub"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
          children: [
            _buildActionButtons(context),
            const SizedBox(height: 32),
            Text("First-Aid Playbooks", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildPlaybookAccordion(
              context,
              "Cardiac Anomaly (Abnormal HR)",
              [
                "1. Check patient responsiveness and breathing.",
                "2. If HR is extremely high, keep patient seated and calm.",
                "3. If HR is low and patient is dizzy, lay them flat and elevate legs.",
                "4. Prepare for CPR if patient becomes unresponsive."
              ],
            ),
            _buildPlaybookAccordion(
               context,
              "Respiratory Distress (Low SpO2)",
               [
                "1. Immediately sit the patient upright.",
                "2. Loosen any tight clothing around the neck/chest.",
                "3. Instruct patient to take slow, deep breaths.",
                "4. Administer supplemental oxygen if prescribed and available."
              ]
            ),
             _buildPlaybookAccordion(
               context,
              "Hemorrhage / Shock (Low BP)",
               [
                "1. Have patient lie flat immediately.",
                "2. Elevate legs 12 inches if no head/neck injury.",
                "3. Keep patient warm with a blanket to maintain core temperature.",
                "4. Do not offer food or drink. Call emergency services."
              ]
            ),
             _buildPlaybookAccordion(
               context,
              "High Fever (Temperature Anomaly)",
               [
                "1. Remove heavy blankets; keep room well-ventilated.",
                "2. Apply cool, damp cloths to forehead or neck.",
                "3. Offer clear fluids if patient is responsive.",
                "4. Monitor temperature continuously."
              ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.call, size: 32, color: Colors.white),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("Call Doctor", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            onPressed: () async {
              final phone = context.read<AppProvider>().settings.doctorPhone;
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.neonRed, width: 2),
              ),
            ),
            icon: const Icon(Icons.local_hospital, size: 32, color: AppTheme.neonRed),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("Emergency Services", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.neonRed)),
            ),
            onPressed: () {
               context.read<AppProvider>().triggerEmergency(
                 contextMsg: "MANUAL PANIC BUTTON TRIGGERED\nInitiating Emergency Protocols",
                 injectMock: false
               );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybookAccordion(BuildContext context, String title, List<String> instructions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: instructions.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(e, style: Theme.of(context).textTheme.bodyMedium),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }
}
