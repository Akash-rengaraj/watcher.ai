import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_provider.dart';
import '../../../theme/app_theme.dart';

class SettingsCalibrationPage extends StatelessWidget {
  const SettingsCalibrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings & Calibration"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;

          return ListView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
            children: [
              _buildSectionTitle(context, "Hardware Management"),
              _buildHardwareCard(context),
              
              const SizedBox(height: 32),
              _buildSectionTitle(context, "Patient Baselines"),
              _buildCalibrationCard(
                context, 
                "Target Resting HR", 
                "${settings.targetRestingHR} bpm",
                () => _showEditDialog(context, "Target Resting HR", settings.targetRestingHR.toString(), (val) {
                  int? parsed = int.tryParse(val);
                  if (parsed != null) provider.updateRestingHR(parsed);
                })
              ),
              const SizedBox(height: 12),
              _buildCalibrationCard(
                context, 
                "Target Blood Pressure", 
                "${settings.targetSystolicBP}/${settings.targetDiastolicBP}",
                () => _showEditDialog(context, "Target Blood Pressure (Sys/Dia)", "${settings.targetSystolicBP}/${settings.targetDiastolicBP}", (val) {
                  List<String> parts = val.split('/');
                  if (parts.length == 2) {
                     int? sys = int.tryParse(parts[0]);
                     int? dia = int.tryParse(parts[1]);
                     if (sys != null && dia != null) provider.updateTargetBP(sys, dia);
                  }
                })
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(context, "Emergency Contacts"),
              _buildCalibrationCard(
                context, 
                "Primary Doctor", 
                settings.doctorPhone,
                () => _showEditDialog(context, "Doctor's Phone", settings.doctorPhone, (val) {
                  provider.updateContacts(val, settings.familyPhone1, settings.familyPhone2);
                })
              ),
              const SizedBox(height: 12),
              _buildCalibrationCard(
                context, 
                "Family Member 1", 
                settings.familyPhone1,
                () => _showEditDialog(context, "Family Member 1 Phone", settings.familyPhone1, (val) {
                  provider.updateContacts(settings.doctorPhone, val, settings.familyPhone2);
                })
              ),
              const SizedBox(height: 12),
              _buildCalibrationCard(
                context, 
                "Family Member 2", 
                settings.familyPhone2,
                () => _showEditDialog(context, "Family Member 2 Phone", settings.familyPhone2, (val) {
                  provider.updateContacts(settings.doctorPhone, settings.familyPhone1, val);
                })
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(context, "Preferences"),
              Card(
                child: SwitchListTile(
                  title: Text("Push Notifications", style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text("Alerts for abnormal vitals", style: Theme.of(context).textTheme.bodyMedium),
                  value: settings.enableNotifications,
                  activeColor: AppTheme.mistyGreen,
                  onChanged: (val) => provider.toggleNotifications(val),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildHardwareCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mistyGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.developer_board, color: AppTheme.mistyGreen, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ESP32 Sensor Unit", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.mistyGreen)),
                       const SizedBox(width: 6),
                       Text("Connected", style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.battery_5_bar, color: AppTheme.mistyGreen),
                const SizedBox(height: 4),
                Text("84%", style: Theme.of(context).textTheme.labelSmall),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationCard(BuildContext context, String title, String value, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.mistyGreen)),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 18, color: AppTheme.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text("Edit $title", style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textPrimary),
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.mistyGreen)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: AppTheme.mistyGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }
}
