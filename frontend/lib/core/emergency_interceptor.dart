import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class EmergencyInterceptor extends StatelessWidget {
  final Widget child;

  const EmergencyInterceptor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<AppProvider>(
          builder: (context, provider, _) {
            if (!provider.isEmergencyActive) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: const _EmergencyOverlay(),
            );
          },
        ),
      ],
    );
  }
}

class _EmergencyOverlay extends StatefulWidget {
  const _EmergencyOverlay();

  @override
  State<_EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<_EmergencyOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Return a Scaffold here to ensure it overlays everything properly.
    // If it's already inside a MaterialApp, wrapping it in Material is crucial.
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            color: AppTheme.neonRed.withOpacity(_pulseAnimation.value * 0.9),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      provider.emergencyContext.isNotEmpty ? provider.emergencyContext : "CRITICAL ANOMALY\nDETECTED",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.neonRed,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 28),
                      label: const Text("EMERGENCY DIAL DOCTOR", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final phone = provider.settings.doctorPhone;
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.read<AppProvider>().dismissEmergency();
                      },
                      child: Text("DISMISS ALERT", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
