import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../branch/providers/branch_provider.dart';
import 'menu_tokens.dart';

class MenuFloatingCartBar extends ConsumerWidget {
  const MenuFloatingCartBar({super.key});

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(price).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final branchState = ref.watch(branchProvider);
    final selectedBranch = branchState.selectedBranch;

    if (cartState.totalItemCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MenuTokens.deepGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: MenuTokens.deepGreen.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => context.push('/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Coral Circular Count Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: MenuTokens.coral,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${cartState.totalItemCount}',
                      style: MenuTokens.sansUI(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Items text and Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${cartState.totalItemCount} ITEMS · ${selectedBranch.city}',
                        style: MenuTokens.sansUI(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatPrice(cartState.subtotal),
                        style: MenuTokens.sansUI(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: MenuTokens.butterYellow,
                        ),
                      ),
                    ],
                  ),
                ),

                // "VIEW CART →" in butter yellow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW CART →',
                      style: MenuTokens.sansUI(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: MenuTokens.butterYellow,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
