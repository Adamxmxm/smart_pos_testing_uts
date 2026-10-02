import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/open_nota_provider.dart';
import 'smart_pos_logo.dart';

class ResponsiveSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const ResponsiveSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final openNotaState = ref.watch(openNotaProvider);

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(
          right: BorderSide(color: AppColors.primaryNavyDark, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // App Logo / Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: const SmartPosLogo(
              iconSize: 36,
              fontSize: 16,
              isDarkBackground: true,
              showSubtitle: true,
            ),
          ),

          const Divider(color: AppColors.navyBorder, height: 1),
          const SizedBox(height: 16),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.storefront_rounded,
                  label: 'Kasir POS',
                  badgeCount: openNotaState.count > 0 ? openNotaState.count : null,
                  badgeColor: AppColors.pastelYellow,
                  badgeTextColor: AppColors.primaryNavyDark,
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 1,
                  icon: Icons.inventory_2_rounded,
                  label: 'Katalog Produk',
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 2,
                  icon: Icons.analytics_rounded,
                  label: 'Laporan Penjualan',
                ),
                const SizedBox(height: 6),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'Akun & Profil',
                ),
              ],
            ),
          ),

          // User Profile & Logout section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryNavyDark,
              border: Border(
                top: BorderSide(color: AppColors.navyBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accentOrange,
                  radius: 18,
                  child: Text(
                    (authState.userProfile?.fullName.isNotEmpty ?? false)
                        ? authState.userProfile!.fullName[0].toUpperCase()
                        : 'K',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        authState.userProfile?.fullName ?? 'Kasir POS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        authState.userProfile?.role.toUpperCase() ?? 'CASHIER',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
                  tooltip: 'Keluar',
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    final isSelected = selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      color: badgeTextColor ?? Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
