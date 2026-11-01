import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../profile/providers/settings_provider.dart';
import '../domain/models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isId = settings.languageCode == 'id';
    final notifState = ref.watch(notificationProvider);
    final notifNotifier = ref.read(notificationProvider.notifier);

    final bg = AppColors.background(context);
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardBg,
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: textColor),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Text(
              isId ? 'Notifikasi' : 'Notifications',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (notifState.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifState.unreadCount} ${isId ? 'BARU' : 'NEW'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () => notifNotifier.markAllAsRead(),
              child: Text(
                isId ? 'Baca Semua' : 'Read All',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filter Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(
                    context: context,
                    label: isId ? 'Semua' : 'All',
                    icon: Icons.all_inclusive_rounded,
                    category: NotificationCategory.all,
                    isSelected: notifState.selectedCategory == NotificationCategory.all,
                    onTap: () => notifNotifier.selectCategory(NotificationCategory.all),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    context: context,
                    label: isId ? 'Promo & Diskon' : 'Promos',
                    icon: Icons.local_fire_department_rounded,
                    category: NotificationCategory.promo,
                    isSelected: notifState.selectedCategory == NotificationCategory.promo,
                    onTap: () => notifNotifier.selectCategory(NotificationCategory.promo),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    context: context,
                    label: isId ? 'Pesanan' : 'Orders',
                    icon: Icons.lunch_dining_rounded,
                    category: NotificationCategory.order,
                    isSelected: notifState.selectedCategory == NotificationCategory.order,
                    onTap: () => notifNotifier.selectCategory(NotificationCategory.order),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    context: context,
                    label: isId ? 'Hadiah & Poin' : 'Rewards',
                    icon: Icons.workspace_premium_rounded,
                    category: NotificationCategory.rewards,
                    isSelected: notifState.selectedCategory == NotificationCategory.rewards,
                    onTap: () => notifNotifier.selectCategory(NotificationCategory.rewards),
                  ),
                ],
              ),
            ),
          ),

          // ── Notifications List or Empty State ─────────────────────────────
          Expanded(
            child: notifState.filteredItems.isEmpty
                ? _buildEmptyState(context, isId, textColor, subtextColor)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: notifState.filteredItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = notifState.filteredItems[index];
                      return _buildNotificationCard(
                        context: context,
                        item: item,
                        isId: isId,
                        cardBg: cardBg,
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => notifNotifier.markAsRead(item.id),
                        onDelete: () => notifNotifier.deleteNotification(item.id),
                      );
                    },
                  ),
          ),

          // ── Bottom Action to Activate Double Date / Special Promos ────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                top: BorderSide(color: AppColors.border(context), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.coral, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.celebration_rounded,
                        size: 18, color: AppColors.coral),
                    label: Text(
                      isId ? '🎉 AKTIFKAN PROMO TANGGAL KEMBAR' : '🎉 ACTIVATE DOUBLE DATE PROMO',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                    onPressed: () {
                      notifNotifier.triggerDoubleDatePromo();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.forestGreen,
                          content: Text(
                            isId
                                ? '🎉 Pesta Tanggal Kembar Aktif! Cek promo diskon 50% di atas.'
                                : '🎉 Double Date Promo Activated! Enjoy 50% discount.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required NotificationCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestGreen : AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.forestGreen
                : AppColors.border(context),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.butterYellow : AppColors.forestGreen,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required AppNotification item,
    required bool isId,
    required Color cardBg,
    required Color textColor,
    required Color subtextColor,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final (icon, iconBg, iconColor) = switch (item.category) {
      NotificationCategory.promo => (
          Icons.local_fire_department_rounded,
          AppColors.coral.withValues(alpha: 0.12),
          AppColors.coral,
        ),
      NotificationCategory.order => (
          Icons.lunch_dining_rounded,
          AppColors.forestGreen.withValues(alpha: 0.12),
          AppColors.forestGreen,
        ),
      NotificationCategory.rewards => (
          Icons.workspace_premium_rounded,
          AppColors.butterYellow.withValues(alpha: 0.3),
          const Color(0xFFB45309),
        ),
      NotificationCategory.all => (
          Icons.notifications_rounded,
          AppColors.forestGreen.withValues(alpha: 0.12),
          AppColors.forestGreen,
        ),
    };

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: item.isRead
                ? cardBg
                : cardBg.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppColors.border(context)
                  : AppColors.coral.withValues(alpha: 0.4),
              width: item.isRead ? 1.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top line: Category Icon, Title, and Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title(isId),
                                style: GoogleFonts.dmSans(
                                  fontWeight: item.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.time(isId),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                item.message(isId),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),

              // Voucher Promo Box if code exists
              if (item.promoCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.butterYellow,
                      style: BorderStyle.solid,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_num_outlined,
                          size: 16, color: AppColors.espresso),
                      const SizedBox(width: 8),
                      Text(
                        '${isId ? 'KODE PROMO' : 'VOUCHER'}: ',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.espresso,
                        ),
                      ),
                      Text(
                        item.promoCode!,
                        style: GoogleFonts.dmMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.promoCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.espresso,
                              content: Text(
                                isId
                                    ? 'Kode promo ${item.promoCode} disalin!'
                                    : 'Promo code ${item.promoCode} copied!',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isId ? 'SALIN' : 'COPY',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action button (e.g. PESAN BURGER, LIHAT PESANAN)
              if (item.actionLabel(isId) != null &&
                  item.actionRoute != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      backgroundColor:
                          AppColors.forestGreen.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      onTap();
                      context.push(item.actionRoute!);
                    },
                    icon: Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.forestGreen),
                    label: Text(
                      item.actionLabel(isId)!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool isId, Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isId ? 'Belum Ada Notifikasi' : 'No Notifications Yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isId
                  ? 'Semua update pesanan, promo burger, dan reward spesialmu akan muncul di sini.'
                  : 'All order status updates, burger promos, and special perks will show up here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }
}
