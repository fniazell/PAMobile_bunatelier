import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../domain/models/app_notification.dart';

class NotificationState {
  final List<AppNotification> items;
  final NotificationCategory selectedCategory;

  const NotificationState({
    required this.items,
    this.selectedCategory = NotificationCategory.all,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  List<AppNotification> get filteredItems {
    if (selectedCategory == NotificationCategory.all) {
      return items;
    }
    return items.where((n) => n.category == selectedCategory).toList();
  }

  NotificationState copyWith({
    List<AppNotification>? items,
    NotificationCategory? selectedCategory,
  }) {
    return NotificationState(
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService = NotificationService();

  NotificationNotifier()
    : super(
        NotificationState(
          items: [
            const AppNotification(
              id: 'notif-1',
              titleId: '🔥 Flash Sale Akhir Pekan: Diskon 30%!',
              titleEn: '🔥 Weekend Flash Sale: 30% Off!',
              messageId: 'Potongan 30% khusus pemesanan Truffle Double Angus Smash dengan roti brioche emas. Gunakan kupon saat checkout!',
              messageEn: 'Get 30% off our Truffle Double Angus Smash with golden brioche buns. Apply voucher at checkout!',
              timeId: 'Baru saja',
              timeEn: 'Just now',
              category: NotificationCategory.promo,
              isRead: false,
              promoCode: 'BUNTRUFFLE30',
              actionLabelId: 'PESAN BURGER',
              actionLabelEn: 'ORDER BURGER',
              actionRoute: '/menu',
            ),
            const AppNotification(
              id: 'notif-2',
              titleId: '🍔 Buy 1 Get 1: Wagyu Brioche Smash',
              titleEn: '🍔 Buy 1 Get 1: Wagyu Brioche Smash',
              messageId: 'Setiap pembelian 1 paket Wagyu Brioche Combo, dapatkan 1 Cheeseburger Staple & Golden Fries secara gratis!',
              messageEn: 'Buy 1 Wagyu Brioche Combo, get a free Cheeseburger Staple and Golden Truffle Fries!',
              timeId: '2 jam lalu',
              timeEn: '2 hrs ago',
              category: NotificationCategory.promo,
              isRead: false,
              promoCode: 'B1G1WAGYU',
              actionLabelId: 'KLAIM PROMO',
              actionLabelEn: 'CLAIM PROMO',
              actionRoute: '/menu',
            ),
            const AppNotification(
              id: 'notif-3',
              titleId: '👨‍🍳 Pesanan #BA-8921 Sedang Dirakit di Kitchen',
              titleEn: '👨‍🍳 Order #BA-8921 is Being Assembled',
              messageId: 'Chef di Bun Atelier Senopati sedang memanggang patty Angus segar dan memanggang brioche Anda. Estimasi siap: 8 menit.',
              messageEn: 'Our Chef at Bun Atelier Senopati is grilling your fresh Angus patty and toasting your brioche. Ready in 8 mins.',
              timeId: 'Hari ini, 12:45',
              timeEn: 'Today, 12:45 PM',
              category: NotificationCategory.order,
              isRead: false,
              actionLabelId: 'LIHAT PESANAN',
              actionLabelEn: 'VIEW ORDER',
              actionRoute: '/orders',
            ),
            const AppNotification(
              id: 'notif-4',
              titleId: '🍞 Fresh Batch Alert! Oven Baru Saja Keluar',
              titleEn: '🍞 Fresh Batch Alert! Fresh from the Oven',
              messageId: 'Batch roti brioche artisanal baru selesai dipanggang di outlet Senopati & PIK. Selalu hangat, renyah di luar, lembut di dalam!',
              messageEn: 'A fresh batch of artisanal brioche buns just left the oven at Senopati & PIK ateliers. Warm, crispy, and fluffy!',
              timeId: 'Kemarin',
              timeEn: 'Yesterday',
              category: NotificationCategory.promo,
              isRead: true,
              actionLabelId: 'KUNJUNGI MENU',
              actionLabelEn: 'EXPLORE MENU',
              actionRoute: '/menu',
            ),
            const AppNotification(
              id: 'notif-6',
              titleId: '🎨 Rancang Burger Impianmu di Custom Burger',
              titleEn: '🎨 Craft Your Dream Burger in Custom Atelier',
              messageId: 'Pilih kombinasi roti, jumlah smash patty, keju lumer, saus truffle mayo, dan topping lezat sesukamu sekarang.',
              messageEn: 'Mix and match brioche buns, smash patties, molten cheese, truffle mayo, and gourmet toppings now.',
              timeId: '3 hari lalu',
              timeEn: '3 days ago',
              category: NotificationCategory.promo,
              isRead: true,
              actionLabelId: 'BUAT BURGER',
              actionLabelEn: 'BUILD BURGER',
              actionRoute: '/custom-burger',
            ),
          ],
        ),
      );

  void selectCategory(NotificationCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void markAsRead(String id) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList(),
    );
  }

  void markAllAsRead() {
    state = state.copyWith(
      items: state.items.map((item) => item.copyWith(isRead: true)).toList(),
    );
  }

  void deleteNotification(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  Future<void> sendTestPromoNotification(bool isId) async {
    final newId = 'notif-${DateTime.now().millisecondsSinceEpoch}';
    final newNotif = AppNotification(
      id: newId,
      titleId: '🎁 Promo Spesial Baru Saja Datang!',
      titleEn: '🎁 New Special Offer Just Arrived!',
      messageId: 'Nikmati diskon 25% untuk pemesanan burger berikutnya dengan kode "BUNSPECIAL25". Selamat menikmati santapanmu!',
      messageEn: 'Enjoy 25% off your next burger order with code "BUNSPECIAL25". Savor the flavor!',
      timeId: 'Baru saja',
      timeEn: 'Just now',
      category: NotificationCategory.promo,
      isRead: false,
      promoCode: 'BUNSPECIAL25',
      actionLabelId: 'PESAN BURGER',
      actionLabelEn: 'ORDER BURGER',
      actionRoute: '/menu',
    );

    state = state.copyWith(items: [newNotif, ...state.items]);

    // Also trigger system local notification if supported
    try {
      await _notificationService.init();
      await _notificationService.showNotification(
        id: DateTime.now().millisecond,
        title: isId ? newNotif.titleId : newNotif.titleEn,
        body: isId ? newNotif.messageId : newNotif.messageEn,
      );
    } catch (_) {}
  }

  /// Dipicu langsung ketika pesanan berhasil dibuat & dikonfirmasi
  Future<void> triggerOrderConfirmedNotification({
    required String orderNumber,
    required String itemsSummary,
    required int total,
  }) async {
    final newId = 'order-conf-${DateTime.now().millisecondsSinceEpoch}';
    final notif = AppNotification(
      id: newId,
      titleId: '🎉 Pesanan #$orderNumber Dikonfirmasi!',
      titleEn: '🎉 Order #$orderNumber Confirmed!',
      messageId: 'Pesananmu ($itemsSummary) senilai Rp ${(total / 1000).toInt()}.000 telah masuk antrean kitchen dan sedang disiapkan!',
      messageEn: 'Your order ($itemsSummary) totaling Rp ${(total / 1000).toInt()}.000 is confirmed and being prepared by our kitchen!',
      timeId: 'Baru saja',
      timeEn: 'Just now',
      category: NotificationCategory.order,
      isRead: false,
      actionLabelId: 'LACAK PESANAN',
      actionLabelEn: 'TRACK ORDER',
      actionRoute: '/orders',
    );

    state = state.copyWith(items: [notif, ...state.items]);

    try {
      await _notificationService.init();
      await _notificationService.showNotification(
        id: DateTime.now().millisecond,
        title: notif.titleId,
        body: notif.messageId,
      );
    } catch (_) {}
  }

  /// Dipicu ketika status pesanan berubah di dapur (Preparing, Ready, Delivering, Completed)
  Future<void> triggerOrderStatusNotification({
    required String orderNumber,
    required String newStatus,
  }) async {
    String titleId;
    String titleEn;
    String messageId;
    String messageEn;

    switch (newStatus.toUpperCase()) {
      case 'PREPARING':
        titleId = '👨‍🍳 Kitchen Update: Pesanan #$orderNumber Sedang Dimasak';
        titleEn = '👨‍🍳 Kitchen Update: Order #$orderNumber is Sizzling';
        messageId = 'Patty Angus dan roti brioche emas Anda sedang dipanggang hangat oleh Chef Bun Atelier.';
        messageEn = 'Your Angus patty and golden brioche buns are being freshly grilled by our Chef.';
        break;
      case 'READY':
        titleId = '🔔 Pesanan #$orderNumber Sudah Siap!';
        titleEn = '🔔 Order #$orderNumber is Ready!';
        messageId = 'Pesanan Anda sudah selesai dikemas dan siap diambil di counter pick-up.';
        messageEn = 'Your order is neatly packed and ready at the pick-up counter.';
        break;
      case 'DELIVERING':
        titleId = '🛵 Pesanan #$orderNumber Sedang Diantar!';
        titleEn = '🛵 Order #$orderNumber is on the Way!';
        messageId = 'Kurir Bun Atelier sedang dalam perjalanan menuju alamat Anda. Siapkan selera makanmu!';
        messageEn = 'Bun Atelier delivery partner is on the way to your address. Get ready!';
        break;
      case 'COMPLETED':
        titleId = '✅ Pesanan #$orderNumber Selesai. Selamat Menikmati!';
        titleEn = '✅ Order #$orderNumber Completed. Enjoy Your Meal!';
        messageId = 'Terima kasih telah bersantap di Bun Atelier. Tagline kami: Worth the Mess!';
        messageEn = 'Thank you for choosing Bun Atelier. Remember: Worth the Mess!';
        break;
      default:
        titleId = '📦 Update Status Pesanan #$orderNumber';
        titleEn = '📦 Order #$orderNumber Status Update';
        messageId = 'Status pesanan Anda kini diperbarui menjadi: $newStatus.';
        messageEn = 'Your order status has been updated to: $newStatus.';
    }

    final newId = 'order-stat-${DateTime.now().millisecondsSinceEpoch}';
    final notif = AppNotification(
      id: newId,
      titleId: titleId,
      titleEn: titleEn,
      messageId: messageId,
      messageEn: messageEn,
      timeId: 'Baru saja',
      timeEn: 'Just now',
      category: NotificationCategory.order,
      isRead: false,
      actionLabelId: 'LIHAT PESANAN',
      actionLabelEn: 'VIEW ORDER',
      actionRoute: '/orders',
    );

    state = state.copyWith(items: [notif, ...state.items]);

    try {
      await _notificationService.init();
      await _notificationService.showNotification(
        id: DateTime.now().millisecond,
        title: titleId,
        body: messageId,
      );
    } catch (_) {}
  }

  /// Memeriksa & memicu promo otomatis berdasarkan kalender (Tanggal Kembar, Payday, Weekend)
  Future<void> checkAndTriggerCalendarPromos() async {
    final now = DateTime.now();

    // 1. Cek Tanggal Kembar (misal: 1.1, 2.2, 10.10, 11.11, 12.12)
    final isDoubleDate = now.day == now.month;
    if (isDoubleDate) {
      await triggerDoubleDatePromo(day: now.day, month: now.month);
      return;
    }

    // 2. Cek Tanggal Gajian / Payday (Tanggal 25 s/d 28)
    if (now.day >= 25 && now.day <= 28) {
      await triggerPaydayPromo();
      return;
    }
  }

  /// Pemicu promo Tanggal Kembar (dapat dipanggil otomatis atau disimulasikan kapan saja)
  Future<void> triggerDoubleDatePromo({int? day, int? month}) async {
    final d = day ?? DateTime.now().day;
    final m = month ?? DateTime.now().month;
    final campaignTag = '$d.$m';
    final code = 'DOUBLE$d$m';

    // Hindari duplikasi jika notifikasi kembar sudah pernah ditambahkan hari ini
    final exists = state.items.any((item) => item.promoCode == code);
    if (exists) return;

    final notif = AppNotification(
      id: 'double-date-$d-$m-${DateTime.now().millisecondsSinceEpoch}',
      titleId: '🎉 PESTA TANGGAL KEMBAR $campaignTag: DISKON 50%!',
      titleEn: '🎉 DOUBLE DATE $campaignTag CARNIVAL: 50% OFF!',
      messageId: 'Spesial pesta kembar $campaignTag! Nikmati diskon potongan 50% untuk Truffle Wagyu Croissant & Artisan Gelato Cup. Masukkan voucher "$code"!',
      messageEn: 'Special Double Date $campaignTag! Enjoy 50% discount on Truffle Wagyu Croissant & Artisan Gelato Cup with voucher "$code"!',
      timeId: 'Baru saja',
      timeEn: 'Just now',
      category: NotificationCategory.promo,
      isRead: false,
      promoCode: code,
      actionLabelId: 'KLAIM 50% SEKARANG',
      actionLabelEn: 'CLAIM 50% NOW',
      actionRoute: '/menu',
    );

    state = state.copyWith(items: [notif, ...state.items]);

    try {
      await _notificationService.init();
      await _notificationService.showNotification(
        id: 7777 + d,
        title: notif.titleId,
        body: notif.messageId,
      );
    } catch (_) {}
  }

  /// Pemicu promo Payday (Gajian)
  Future<void> triggerPaydayPromo() async {
    const code = 'PAYDAYBUN';
    final exists = state.items.any((item) => item.promoCode == code);
    if (exists) return;

    final notif = AppNotification(
      id: 'payday-${DateTime.now().millisecondsSinceEpoch}',
      titleId: '💸 GAJIAN TIBA: PAYDAY CASHBACK RP 50.000!',
      titleEn: '💸 PAYDAY PARTY: RP 50.000 CASHBACK!',
      messageId: 'Rayakan gajianmu dengan burger sultan! Dapatkan potongan cashback Rp 50.000 untuk pesanan minimal Rp 100.000. Kode: PAYDAYBUN.',
      messageEn: 'Celebrate your payday with gourmet smash burgers! Get Rp 50.000 cashback on orders above Rp 100.000. Code: PAYDAYBUN.',
      timeId: 'Baru saja',
      timeEn: 'Just now',
      category: NotificationCategory.promo,
      isRead: false,
      promoCode: code,
      actionLabelId: 'PAKAI VOUCHER GAJIAN',
      actionLabelEn: 'USE PAYDAY VOUCHER',
      actionRoute: '/menu',
    );

    state = state.copyWith(items: [notif, ...state.items]);

    try {
      await _notificationService.init();
      await _notificationService.showNotification(
        id: 8888,
        title: notif.titleId,
        body: notif.messageId,
      );
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier();
    });
