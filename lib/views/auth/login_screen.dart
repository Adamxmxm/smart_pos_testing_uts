import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../widgets/smart_pos_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Login gagal. Cek kembali data Anda.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Brand
                      const Center(
                        child: SmartPosLogo(
                          iconSize: 52,
                          fontSize: 22,
                          showSubtitle: false,
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOut),

                      const SizedBox(height: 18),

                      const Text(
                        'Masuk ke TokaPOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Silakan masukkan kredensial kasir Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Email Field
                      const Text(
                        'Alamat Email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'nama@domain.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      const Text(
                        'Kata Sandi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (v.length < 6) return 'Password minimal 6 karakter';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Masuk Sekarang'),
                      ),

                      const SizedBox(height: 16),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun kasir? ',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Daftar Baru',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
