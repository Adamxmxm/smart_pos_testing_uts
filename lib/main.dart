import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/supabase_service.dart';
import 'views/auth/login_screen.dart';
import 'views/pos/pos_main_layout.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — always live, no demo mode
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: SmartPOSApp()));
}

class SmartPOSApp extends StatelessWidget {
  const SmartPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart POS - Point of Sale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppRootRouter(),
    );
  }
}

class AppRootRouter extends StatefulWidget {
  const AppRootRouter({super.key});

  @override
  State<AppRootRouter> createState() => _AppRootRouterState();
}

class _AppRootRouterState extends State<AppRootRouter> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onSplashFinished: () {
          setState(() {
            _showSplash = false;
          });
        },
      );
    }

    return const AuthGate();
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return const PosMainLayout();
    }

    // Jika isLoading true tapi belum terautentikasi, kita tetap tampilkan
    // LoginScreen. LoginScreen sudah punya logika untuk me-disable tombol
    // dan menampilkan spinner di dalam tombolnya.
    // Ini mencegah LoginScreen ter-unmount saat proses login berjalan
    // yang menyebabkan pesan error (SnackBar) gagal ditampilkan.
    return const LoginScreen();
  }
}
