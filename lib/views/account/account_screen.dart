import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Dialog',
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 10),
              Text(
                'Keluar Akun Kasir?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari sesi kasir ini? Pastikan seluruh tagihan transaksi telah selesai diproses.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textDark),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final reportState = ref.watch(reportProvider);
    final profile = authState.userProfile;
    final initialLetter = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName[0].toUpperCase()
        : 'K';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Akun & Profil Kasir',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavy, AppColors.primaryNavyDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.accentOrange,
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile?.fullName ?? 'Kasir POS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (profile?.role.toUpperCase() ?? 'CASHIER'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile?.email ?? 'kasir@smartpos.id',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Connection Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SupabaseConfig.isConfigured
                                ? Colors.green.withValues(alpha: 0.25)
                                : Colors.amber.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SupabaseConfig.isConfigured ? Colors.greenAccent : Colors.amberAccent,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3.5,
                                backgroundColor:
                                    SupabaseConfig.isConfigured ? Colors.greenAccent : Colors.amberAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                SupabaseConfig.isConfigured ? 'Supabase Online' : 'Demo Mode (Offline)',
                                style: TextStyle(
                                  color: SupabaseConfig.isConfigured ? Colors.greenAccent : Colors.amberAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),

            const SizedBox(height: 18),

            // Shift & Performance Summary
            const Text(
              'Ringkasan Sesi Operasional',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaksi Selesai',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reportState.totalTransactions} Struk',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Omset',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(reportState.totalOmset),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Store & Terminal Information
            const Text(
              'Informasi Kasir & Toko',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.storefront_rounded,
                    title: 'Nama Toko / Outlet',
                    value: 'TokaPOS - Cabang Utama',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.badge_outlined,
                    title: 'ID Pengguna',
                    value: profile?.id.isNotEmpty ?? false ? profile!.id.substring(0, 8) : 'CASHIER-01',
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.access_time_rounded,
                    title: 'Waktu Sesi Saat Ini',
                    value: DateFormatter.formatDateTime(DateTime.now()),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Versi Aplikasi',
                    value: 'TokaPOS v1.2.0 (Mobile Ready)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Action Button
            ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Keluar dari Akun (Logout)',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavy),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
