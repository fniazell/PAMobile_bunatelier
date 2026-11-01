import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/domain/models/app_notification.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:mobile/features/notifications/providers/notification_provider.dart';

void main() {
  group('Notifications Feature Tests', () {
    test('NotificationNotifier initial state has unread items and computes unreadCount', () {
      final container = ProviderContainer();
      final state = container.read(notificationProvider);

      expect(state.items.isNotEmpty, isTrue);
      expect(state.unreadCount, greaterThan(0));
      expect(state.selectedCategory, equals(NotificationCategory.all));
    });

    test('Filtering by category returns only matching notifications', () {
      final container = ProviderContainer();
      final notifier = container.read(notificationProvider.notifier);

      notifier.selectCategory(NotificationCategory.promo);
      final promoItems = container.read(notificationProvider).filteredItems;
      expect(promoItems.every((item) => item.category == NotificationCategory.promo), isTrue);

      notifier.selectCategory(NotificationCategory.order);
      final orderItems = container.read(notificationProvider).filteredItems;
      expect(orderItems.every((item) => item.category == NotificationCategory.order), isTrue);
    });

    test('markAsRead updates item state and markAllAsRead clears unread count', () {
      final container = ProviderContainer();
      final notifier = container.read(notificationProvider.notifier);

      final initialUnread = container.read(notificationProvider).unreadCount;
      final firstUnread = container.read(notificationProvider).items.firstWhere((n) => !n.isRead);

      notifier.markAsRead(firstUnread.id);
      expect(container.read(notificationProvider).unreadCount, equals(initialUnread - 1));

      notifier.markAllAsRead();
      expect(container.read(notificationProvider).unreadCount, equals(0));
    });

    test('deleteNotification removes item from list', () {
      final container = ProviderContainer();
      final notifier = container.read(notificationProvider.notifier);

      final initialCount = container.read(notificationProvider).items.length;
      notifier.deleteNotification('notif-1');

      expect(container.read(notificationProvider).items.length, equals(initialCount - 1));
      expect(container.read(notificationProvider).items.any((n) => n.id == 'notif-1'), isFalse);
    });

    test('sendTestPromoNotification adds new promo item', () async {
      final container = ProviderContainer();
      final notifier = container.read(notificationProvider.notifier);

      final initialCount = container.read(notificationProvider).items.length;
      await notifier.sendTestPromoNotification(true);

      final updatedState = container.read(notificationProvider);
      expect(updatedState.items.length, equals(initialCount + 1));
      expect(updatedState.items.first.category, equals(NotificationCategory.promo));
      expect(updatedState.items.first.promoCode, isNotNull);
    });

    testWidgets('NotificationsScreen renders category chips and notification cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Promos'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);

      // Verify promo vouchers are displayed
      expect(find.text('BUNTRUFFLE30'), findsOneWidget);
      expect(find.text('COPY'), findsWidgets);
    });
  });
}
