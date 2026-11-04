import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/features/branch/models/branch_model.dart';
import 'package:mobile/features/checkout/presentation/order_confirmation_screen.dart';
import 'package:mobile/features/checkout/presentation/widgets/checkout_currency_card.dart';
import 'package:mobile/features/converter/services/currency_service.dart';
import 'package:mobile/features/orders/models/order_model.dart';
import 'package:mobile/features/orders/presentation/orders_screen.dart';
import 'package:mobile/features/orders/providers/orders_provider.dart';
import 'package:mobile/features/orders/services/receipt_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    CurrencyService.instance.setCachedRatesForTesting({
      'USD': 1.0,
      'IDR': 16100.0,
      'GBP': 0.77,
      'MYR': 4.30,
      'SGD': 1.32,
    });
  });

  group('E-Receipt Model & isConfirmed Status Tests', () {
    test('isConfirmed returns true only for confirmed or progressed orders', () {
      final base = OrderItemModel(
        id: 'ord-test-1',
        orderNumber: 'BA-20261027-001',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 100000,
        tax: 10000,
        total: 110000,
        itemsSummary: '1x Truffle Burger, 1x Fries',
        branchName: 'Bun Atelier — Senopati Flagship',
      );

      expect(base.copyWith(status: 'CONFIRMED').isConfirmed, isTrue);
      expect(base.copyWith(status: 'PREPARING').isConfirmed, isTrue);
      expect(base.copyWith(status: 'READY_FOR_PICKUP').isConfirmed, isTrue);
      expect(base.copyWith(status: 'OUT_FOR_DELIVERY').isConfirmed, isTrue);
      expect(base.copyWith(status: 'COMPLETED').isConfirmed, isTrue);

      // Pending and Cancelled must return false
      expect(base.copyWith(status: 'PENDING').isConfirmed, isFalse);
      expect(base.copyWith(status: 'CANCELLED').isConfirmed, isFalse);
    });
  });

  group('ReceiptDownloadService Unit Tests', () {
    setUp(() {
      ReceiptDownloadService.instance.testSaverOverride = null;
    });

    tearDown(() {
      ReceiptDownloadService.instance.testSaverOverride = null;
    });

    test('saveReceiptToGallery returns success when saver succeeds', () async {
      String? capturedName;
      Uint8List? capturedBytes;

      ReceiptDownloadService.instance.testSaverOverride =
          (bytes, {String? name}) async {
        capturedBytes = bytes;
        capturedName = name;
      };

      final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await ReceiptDownloadService.instance.saveReceiptToGallery(
        imageBytes: fakeBytes,
        orderNumber: 'BA-20261027-099',
      );

      expect(result.isSuccess, isTrue);
      expect(result.message, contains('berhasil disimpan'));
      expect(capturedName, 'BunAtelier_Receipt_BA-20261027-099');
      expect(capturedBytes, fakeBytes);
    });

    test('saveReceiptToGallery fails gracefully when imageBytes is empty', () async {
      final result = await ReceiptDownloadService.instance.saveReceiptToGallery(
        imageBytes: Uint8List(0),
        orderNumber: 'BA-20261027-099',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('kosong'));
    });

    test('saveReceiptToGallery handles GalException accessDenied with friendly message',
        () async {
      ReceiptDownloadService.instance.testSaverOverride =
          (bytes, {String? name}) async {
        throw GalException(
          type: GalExceptionType.accessDenied,
          platformException: PlatformException(code: 'ACCESS_DENIED'),
          stackTrace: StackTrace.current,
        );
      };

      final result = await ReceiptDownloadService.instance.saveReceiptToGallery(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        orderNumber: 'BA-20261027-001',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isPermissionDenied, isTrue);
      expect(result.message, contains('Izin galeri ditolak'));
    });

    test('saveReceiptToGallery handles GalException notEnoughSpace', () async {
      ReceiptDownloadService.instance.testSaverOverride =
          (bytes, {String? name}) async {
        throw GalException(
          type: GalExceptionType.notEnoughSpace,
          platformException: PlatformException(code: 'NOT_ENOUGH_SPACE'),
          stackTrace: StackTrace.current,
        );
      };

      final result = await ReceiptDownloadService.instance.saveReceiptToGallery(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        orderNumber: 'BA-20261027-001',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('tidak mencukupi'));
    });
  });

  group('OrderConfirmationScreen & E-Receipt UI Widget Tests', () {
    late OrderItemModel confirmedOrder;
    late OrderItemModel pendingOrder;

    setUp(() {
      confirmedOrder = OrderItemModel(
        id: 'ord-100',
        orderNumber: 'BA-20261027-100',
        createdAt: DateTime(2026, 10, 27, 14, 30),
        orderType: 'DELIVERY',
        deliveryAddress: 'Jl. Senopati No. 45, Jakarta Selatan',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 150000,
        tax: 15000,
        deliveryFee: 12000,
        total: 177000,
        itemsSummary: '2x OG Main Character, 1x Truffle Mac n Cheese',
        branchName: 'Bun Atelier — Senopati Flagship',
        branchCurrency: 'IDR',
        branchTimezone: 'Asia/Jakarta',
      );

      pendingOrder = confirmedOrder.copyWith(status: 'PENDING');
    });

    tearDown(() {
      ReceiptDownloadService.instance.testSaverOverride = null;
      ReceiptDownloadService.instance.testPngBytesOverride = null;
    });

    testWidgets('Renders all required e-receipt fields for Confirmed order',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: confirmedOrder),
        ),
      );

      await tester.pump();

      // Header Brand
      expect(find.text('BUN ATELIER'), findsOneWidget);
      expect(find.text('WORTH THE MESS.'), findsOneWidget);
      expect(find.text('Bun Atelier — Senopati Flagship'), findsOneWidget);

      // Order number and details
      expect(find.text('BA-20261027-100'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Jl. Senopati No. 45, Jakarta Selatan'), findsOneWidget);
      expect(find.text('QRIS (PAID)'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);

      // Items list
      expect(find.text('2x OG Main Character'), findsOneWidget);
      expect(find.text('1x Truffle Mac n Cheese'), findsOneWidget);

      // Financial breakdown (Formatted with Indonesian locale)
      expect(find.text('Rp 150.000'), findsOneWidget); // Subtotal
      expect(find.text('Rp 15.000'), findsOneWidget); // Tax
      expect(find.text('Rp 12.000'), findsOneWidget); // Delivery Fee
      expect(find.text('Rp 177.000'), findsOneWidget); // Total Amount

      // Download button active
      final downloadBtn = find.widgetWithText(
          ElevatedButton, 'DOWNLOAD E-RECEIPT (SIMPAN KE GALERI)');
      expect(downloadBtn, findsOneWidget);
      final elevatedWidget = tester.widget<ElevatedButton>(downloadBtn);
      expect(elevatedWidget.onPressed, isNotNull);
    });

    testWidgets('Download button is disabled for PENDING orders',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: pendingOrder),
        ),
      );

      await tester.pump();

      // Download button disabled
      final downloadBtn =
          find.widgetWithText(ElevatedButton, 'E-RECEIPT BELUM TERSEDIA');
      expect(downloadBtn, findsOneWidget);
      final elevatedWidget = tester.widget<ElevatedButton>(downloadBtn);
      expect(elevatedWidget.onPressed, isNull);

      // Advisory note present
      expect(
        find.text('E-Receipt hanya dapat diunduh setelah pesanan dikonfirmasi.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping download button saves to gallery and shows success feedback',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool saverCalled = false;
      ReceiptDownloadService.instance.testPngBytesOverride =
          Uint8List.fromList([1, 2, 3]);
      ReceiptDownloadService.instance.testSaverOverride =
          (bytes, {String? name}) async {
        saverCalled = true;
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: confirmedOrder),
        ),
      );

      await tester.pump();

      final downloadBtn = find.widgetWithText(
          ElevatedButton, 'DOWNLOAD E-RECEIPT (SIMPAN KE GALERI)');
      await tester.tap(downloadBtn);

      // Pump to process async capture and save
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(saverCalled, isTrue);
      expect(find.text('E-Receipt berhasil disimpan ke galeri foto!'),
          findsOneWidget);
    });
  });

  group('Regional Currency E-Receipt Integration Tests', () {
    testWidgets('London branch order converts receipt amounts to GBP (£)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final londonOrder = OrderItemModel(
        id: 'ord-london-1',
        orderNumber: 'BA-20261027-LON',
        createdAt: DateTime(2026, 10, 27, 14, 0),
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 150000,
        tax: 15000,
        deliveryFee: 0,
        total: 165000,
        itemsSummary: '2x OG Main Character',
        branchName: 'Bun Atelier — London',
        branchTimezone: 'Europe/London',
        branchCurrency: 'GBP',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: londonOrder),
        ),
      );

      await tester.pump();

      // Converted GBP totals and symbols
      expect(find.textContaining('£'), findsWidgets);
      // Regional Currency section
      expect(find.text('KONVERSI MATA UANG: GBP'), findsOneWidget);
      expect(find.text('Setara Nilai Asal (IDR)'), findsOneWidget);
      expect(find.text('Rp 165.000'), findsOneWidget);
      expect(find.textContaining('Kurs acuan: 1 GBP ≈ Rp'), findsOneWidget);
    });

    testWidgets('Malaysia branch order converts receipt amounts to MYR (RM)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final myrOrder = OrderItemModel(
        id: 'ord-myr-1',
        orderNumber: 'BA-20261027-KL',
        createdAt: DateTime(2026, 10, 27, 14, 0),
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 100000,
        tax: 10000,
        deliveryFee: 0,
        total: 110000,
        itemsSummary: '1x Truffle Burger',
        branchName: 'Bun Atelier — Kuala Lumpur',
        branchTimezone: 'Asia/Kuala_Lumpur',
        branchCurrency: 'MYR',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: myrOrder),
        ),
      );

      await tester.pump();

      expect(find.textContaining('RM'), findsWidgets);
      expect(find.text('KONVERSI MATA UANG: MYR'), findsOneWidget);
    });

    testWidgets('Singapore branch order converts receipt amounts to SGD (S\$)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sgdOrder = OrderItemModel(
        id: 'ord-sgd-1',
        orderNumber: 'BA-20261027-SG',
        createdAt: DateTime(2026, 10, 27, 14, 0),
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 100000,
        tax: 10000,
        deliveryFee: 0,
        total: 110000,
        itemsSummary: '1x Truffle Burger',
        branchName: 'Bun Atelier — Singapore',
        branchTimezone: 'Asia/Singapore',
        branchCurrency: 'SGD',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderConfirmationScreen(order: sgdOrder),
        ),
      );

      await tester.pump();

      expect(find.textContaining('S\$'), findsWidgets);
      expect(find.text('KONVERSI MATA UANG: SGD'), findsOneWidget);
    });
  });

  group('CheckoutCurrencyCard Automatic Branch Tests', () {
    testWidgets('Renders clean domestic IDR card for Indonesia branch without dropdown or chips',
        (tester) async {
      final indonesiaBranch = BranchModel.defaultBranches.first; // Senopati (IDR)

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CheckoutCurrencyCard(
              totalInIdr: 71500,
              branch: indonesiaBranch,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('MATA UANG CABANG: INDONESIA'), findsOneWidget);
      expect(find.text('IDR — Rupiah Indonesia'), findsOneWidget);
      expect(find.text('Rp 71.500'), findsOneWidget);
      // No manual dropdown or quick choice chips
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('USD'), findsNothing);
    });

    testWidgets('Renders automatic London GBP conversion card without dropdown or chips',
        (tester) async {
      final londonBranch = BranchModel.defaultBranches.firstWhere((b) => b.id == 'out-3');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CheckoutCurrencyCard(
              totalInIdr: 71500,
              branch: londonBranch,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('KONVERSI MATA UANG OTOMATIS: LONDON'), findsOneWidget);
      expect(find.text('GBP — British Pound'), findsOneWidget);
      expect(find.textContaining('£'), findsWidgets);
      // No manual choice chips
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('OrdersScreen Integration Tests', () {
    testWidgets('OrdersScreen renders "Lihat & Unduh E-Receipt" button',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleOrder = OrderItemModel(
        id: 'ord-receipt-test',
        orderNumber: 'BA-20261104-001',
        createdAt: DateTime.now(),
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 100000,
        tax: 10000,
        total: 110000,
        itemsSummary: '1x Truffle Burger',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith((ref) => _MockOrdersNotifier([sampleOrder])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const OrdersScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Lihat & Unduh E-Receipt'), findsWidgets);
    });
  });
}

class _MockOrdersNotifier extends OrdersNotifier {
  final List<OrderItemModel> initialOrders;
  _MockOrdersNotifier(this.initialOrders) : super(null) {
    state = OrdersState(orders: initialOrders);
  }
}
