import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'menu_tokens.dart';

class MenuBottomNavBar extends StatelessWidget {
  const MenuBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MenuTokens.background,
        border: const Border(
          top: BorderSide(color: MenuTokens.borderLight, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                context,
                icon: Icons.home_outlined,
                label: 'HOME',
                isActive: false,
                onTap: () => context.go('/main'),
              ),
              _buildNavItem(
                context,
                icon: Icons.menu_rounded,
                label: 'MENU',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_outlined,
                label: 'ORDERS',
                isActive: false,
                onTap: () => context.push('/orders'),
              ),
              _buildNavItem(
                context,
                icon: Icons.workspace_premium_outlined,
                label: 'REWARDS',
                isActive: false,
                onTap: () => context.push('/game'),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline_rounded,
                label: 'PROFILE',
                isActive: false,
                onTap: () => context.go('/main'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: MenuTokens.activeNavHalo,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: MenuTokens.deepGreen,
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
                    color: MenuTokens.mutedText.withValues(alpha: 0.85),
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              label,
              style: MenuTokens.sansUI(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? MenuTokens.deepGreen : MenuTokens.mutedText,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
