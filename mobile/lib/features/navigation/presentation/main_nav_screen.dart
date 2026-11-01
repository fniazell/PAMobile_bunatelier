import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/presentation/widgets/menu_tokens.dart';
import '../../catalog/presentation/widgets/menu_floating_cart_bar.dart';
import '../../home/presentation/home_screen.dart';
import '../../catalog/presentation/menu_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../rewards/presentation/rewards_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../app/theme/app_colors.dart';
import '../../profile/providers/settings_provider.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    MenuScreen(),
    OrdersScreen(),
    RewardsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MenuFloatingCartBar(),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkCard : MenuTokens.background;
    final navBorder = isDark ? AppColors.darkBorder : MenuTokens.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: navBorder, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                label: settings.t('nav_home'),
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.menu_rounded,
                label: settings.t('nav_menu'),
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.receipt_long_outlined,
                label: settings.t('nav_orders'),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.workspace_premium_outlined,
                label: settings.t('nav_rewards'),
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: settings.t('nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHalo = isDark
        ? AppColors.coral.withValues(alpha: 0.22)
        : MenuTokens.activeNavHalo;
    final activeColor = isDark ? AppColors.coral : MenuTokens.deepGreen;
    final inactiveColor = isDark
        ? AppColors.darkMuted
        : MenuTokens.mutedText.withValues(alpha: 0.85);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          setState(() => _currentIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: activeHalo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: activeColor,
                  ),
                ),
              )
            else
              SizedBox(
                height: 32,
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: inactiveColor,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: MenuTokens.sansUI(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
