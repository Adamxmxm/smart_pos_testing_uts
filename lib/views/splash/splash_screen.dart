import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/smart_pos_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onSplashFinished;

  const SplashScreen({super.key, required this.onSplashFinished});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Supabase already initialized in main() — just show animation
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      widget.onSplashFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated App Logo with Scale & Fade Up
            SmartPosLogoIcon(
              size: 110,
              navyColor: Colors.white,
              orangeColor: AppColors.accentOrange,
            )
                .animate()
                .scale(
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 28),

            // Title
            const SmartPosLogo(
              iconSize: 0,
              fontSize: 32,
              isDarkBackground: true,
              showSubtitle: true,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

            const SizedBox(height: 48),

            // Circular progress indicator with orange accent
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
