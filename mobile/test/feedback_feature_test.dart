import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/feedback/models/feedback_model.dart';
import 'package:mobile/features/feedback/presentation/give_feedback_screen.dart';
import 'package:mobile/features/feedback/presentation/widgets/feedback_success_dialog.dart';
import 'package:mobile/features/feedback/providers/feedback_provider.dart';
import 'package:mobile/features/feedback/services/feedback_service.dart';
import 'package:mobile/features/orders/models/order_model.dart';
import 'package:mobile/features/orders/presentation/orders_screen.dart';
import 'package:mobile/features/orders/providers/orders_provider.dart';
import 'package:mobile/features/admin/reports/presentation/admin_reports_tab.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';

void main() {
  setUp(() async {
    await SecureStorageService().clearAll();
  });

  group('Feedback Feature - Unit & Widget Tests', () {
    test('FeedbackModel converts to and from Map correctly', () {
      final now = DateTime.utc(2026, 11, 4, 10, 0, 0);
      final model = FeedbackModel(
        id: 'fb-01',
        orderId: 'BA-20261104-001',
        userId: 'user-123',
        customerName: 'Jane Customer',
        rating: 5,
        comment: 'Burger was incredible!',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['order_id'], 'BA-20261104-001');
      expect(map['user_id'], 'user-123');
      expect(map['customer_name'], 'Jane Customer');
      expect(map['rating'], 5);
      expect(map['comment'], 'Burger was incredible!');
      expect(map['created_at'], now.toIso8601String());

      final parsed = FeedbackModel.fromMap(map);
      expect(parsed.orderId, 'BA-20261104-001');
      expect(parsed.userId, 'user-123');
      expect(parsed.customerName, 'Jane Customer');
      expect(parsed.rating, 5);
      expect(parsed.comment, 'Burger was incredible!');
    });

    test('FeedbackModel handles null/empty comment as optional', () {
      final now = DateTime.utc(2026, 11, 4, 10, 0, 0);
      final model = FeedbackModel(
        orderId: 'BA-20261104-002',
        userId: 'user-456',
        rating: 4,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map.containsKey('comment'), false);
      expect(map['rating'], 4);
      expect(map['order_id'], 'BA-20261104-002');
      expect(map['user_id'], 'user-456');
    });

    test('FeedbackService rejects empty orderId', () async {
      final service = FeedbackService();
      final noOrder = FeedbackModel(
        orderId: '',
        userId: 'user-1',
        rating: 5,
        createdAt: DateTime.now(),
      );
      final result = await service.submitFeedback(noOrder);
      expect(result.success, false);
      expect(result.errorMessage, contains('Order ID'));
    });

    test('FeedbackService rejects invalid ratings (< 1 or > 5)', () async {
      final service = FeedbackService();
      final invalidLow = FeedbackModel(
        orderId: 'BA-01',
        userId: 'user-1',
        rating: 0,
        createdAt: DateTime.now(),
      );
      final resultLow = await service.submitFeedback(invalidLow);
      expect(resultLow.success, false);
      expect(resultLow.errorMessage, contains('Rating harus antara 1 sampai 5'));

      final invalidHigh = FeedbackModel(
        orderId: 'BA-01',
        userId: 'user-1',
        rating: 6,
        createdAt: DateTime.now(),
      );
      final resultHigh = await service.submitFeedback(invalidHigh);
      expect(resultHigh.success, false);
      expect(resultHigh.errorMessage, contains('Rating harus antara 1 sampai 5'));
    });

    test('FeedbackService rejects empty userId', () async {
      final service = FeedbackService();
      final noUser = FeedbackModel(
        orderId: 'BA-01',
        userId: '',
        rating: 5,
        createdAt: DateTime.now(),
      );
      final result = await service.submitFeedback(noUser);
      expect(result.success, false);
      expect(result.errorMessage, contains('Pengguna harus masuk/login'));
    });

    testWidgets('Settings section no longer has Feedback menu, preserves Contact support',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Contact support and Bun Buddy AI exist
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('Bun Buddy AI'), findsOneWidget);

      // Feedback menu should NO LONGER be present in Profile settings
      expect(find.text('Feedback'), findsNothing);
    });

    testWidgets('OrdersScreen renders Give Feedback button only for COMPLETED orders',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedOrder = OrderItemModel(
        id: 'ord-completed-1',
        orderNumber: 'BA-20261104-001',
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'CASHIER',
        paymentStatus: 'PAID',
        subtotal: 50000,
        tax: 5000,
        total: 55000,
        itemsSummary: '1x Classic Smash Burger',
      );

      final pendingOrder = OrderItemModel(
        id: 'ord-pending-1',
        orderNumber: 'BA-20261104-002',
        status: 'PREPARING',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'CASHIER',
        paymentStatus: 'PAID',
        subtotal: 50000,
        tax: 5000,
        total: 55000,
        itemsSummary: '1x Truffle Melt Burger',
      );

      final mockService = _MockFeedbackService(feedbacksToReturn: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWithValue(mockService),
            ordersProvider.overrideWith((ref) => _MockOrdersNotifier([completedOrder, pendingOrder])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const OrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Give Feedback is shown for completed order
      expect(find.text('Give Feedback'), findsOneWidget);

      // Both orders show e-receipt button
      expect(find.text('Lihat & Unduh E-Receipt'), findsNWidgets(2));
    });

    testWidgets('OrdersScreen renders View Feedback button if order has already been rated',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedOrder = OrderItemModel(
        id: 'ord-completed-rated',
        orderNumber: 'BA-20261104-003',
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'CASHIER',
        paymentStatus: 'PAID',
        subtotal: 50000,
        tax: 5000,
        total: 55000,
        itemsSummary: '1x Golden Truffle Burger',
      );

      final existingFeedback = FeedbackModel(
        id: 'fb-rated-1',
        orderId: 'ord-completed-rated',
        userId: 'user-mock-123',
        customerName: 'Jane Customer',
        rating: 5,
        comment: 'Rasa sangat enak dan juicy!',
        createdAt: DateTime.now(),
      );

      final mockService = _MockFeedbackService(feedbacksToReturn: [existingFeedback]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWithValue(mockService),
            ordersProvider.overrideWith((ref) => _MockOrdersNotifier([completedOrder])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const OrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Since feedback exists, shows View Feedback (5★)
      expect(find.text('View Feedback (5★)'), findsOneWidget);
      expect(find.text('Give Feedback'), findsNothing);
    });

    testWidgets('GiveFeedbackScreen renders rating stars and publish feedback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final order = OrderItemModel(
        id: 'ord-test-feedback',
        orderNumber: 'BA-20261104-009',
        status: 'COMPLETED',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'CASHIER',
        paymentStatus: 'PAID',
        subtotal: 64900,
        tax: 6490,
        total: 71390,
        itemsSummary: '1x Crunch Culture',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: GiveFeedbackScreen(order: order),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // AppBar & headings
      expect(find.text('Give Feedback'), findsOneWidget);
      expect(find.text('How did we do?'), findsOneWidget);
      expect(find.text('Care to share more about it?'), findsOneWidget);

      // Order info banner
      expect(find.text('BA-20261104-009'), findsOneWidget);
      expect(find.text('1x Crunch Culture'), findsOneWidget);

      // Tap 5th star
      final starIcons = find.byIcon(Icons.star_outline_rounded);
      expect(starIcons, findsNWidgets(5));
      await tester.tap(starIcons.at(4));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
      expect(find.text('Exceptional!'), findsOneWidget);

      // Button exists
      expect(find.text('PUBLISH FEEDBACK'), findsOneWidget);
    });

    testWidgets('FeedbackSuccessDialog renders Thank You, description, and DONE button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FeedbackSuccessDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thank You!'), findsOneWidget);
      expect(
        find.text('Your feedback helps us make Bun Atelier even better.'),
        findsOneWidget,
      );
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('AdminReportsTab includes 6. Customer Feedback tab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleFeedbacks = [
        FeedbackModel(
          id: 'fb-admin-1',
          orderId: 'BA-20261104-ADMIN',
          userId: 'user-admin-1',
          customerName: 'Budi Santoso',
          rating: 5,
          comment: 'Burger terenak di Jakarta!',
          createdAt: DateTime.now(),
        ),
      ];

      final mockService = _MockFeedbackService(feedbacksToReturn: sampleFeedbacks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AdminReportsTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the 6th tab exists
      expect(find.text('6. Customer Feedback'), findsOneWidget);

      // Tap on 6. Customer Feedback tab
      await tester.ensureVisible(find.text('6. Customer Feedback'));
      await tester.tap(find.text('6. Customer Feedback'));
      await tester.pumpAndSettle();

      // Verify statistics & feedback card
      expect(find.text('Customer Satisfaction & Ratings'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Burger terenak di Jakarta!'), findsOneWidget);
    });
  });
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier() {
    state = const AuthState(
      isAuthenticated: true,
      user: AuthUser(
        id: 'user-mock-123',
        fullName: 'Jane Customer',
        email: 'customer@bunatelier.com',
      ),
    );
  }
}

class _MockFeedbackService extends FeedbackService {
  final List<FeedbackModel> feedbacksToReturn;

  _MockFeedbackService({this.feedbacksToReturn = const []});

  @override
  Future<List<FeedbackModel>> fetchFeedbacks() async {
    return feedbacksToReturn;
  }
}

class _MockOrdersNotifier extends OrdersNotifier {
  final List<OrderItemModel> initialOrders;
  _MockOrdersNotifier(this.initialOrders) : super(null) {
    state = OrdersState(orders: initialOrders);
  }
}
