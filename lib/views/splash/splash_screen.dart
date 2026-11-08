import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';

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
    // Show splash animation smoothly then transition
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      widget.onSplashFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C2340), // Premium Dark Navy
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0C2340), // Deep TokaPOS Navy
              Color(0xFF071526), // Darker base
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background glow
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                  ),
                ),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TokaPOS App Badge Card with 3D drop shadow
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.accentOrange.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/tokapos_icon.png',
                        fit: BoxFit.contain,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 850.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1.0, 1.0),
                        )
                        .fadeIn(duration: 600.ms)
                        .shimmer(delay: 900.ms, duration: 1100.ms, color: Colors.white54),

                    const SizedBox(height: 28),

                    // TokaPOS Big Wordmark
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Toka',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'POS',
                            style: TextStyle(color: AppColors.accentOrange),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 600.ms)
                        .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Sistem Kasir Pintar & Modern',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 48),

                    // Modern Linear & Circular Loading Indicator
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                      ),
                    ).animate().fadeIn(delay: 750.ms, duration: 400.ms),
                  ],
                ),
              ),

              // Bottom footer tagline
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'TokaPOS • Versi 1.2.0',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
