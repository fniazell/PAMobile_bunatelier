import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/inventory/presentation/admin_inventory_tab.dart';
import 'package:mobile/features/admin/analytics/presentation/admin_analytics_tab.dart';
import 'package:mobile/features/admin/promotions/presentation/admin_promotions_tab.dart';
import 'package:mobile/features/admin/menu/presentation/admin_menu_tab.dart';
import 'package:mobile/features/admin/dashboard/presentation/admin_dashboard_tab.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:mobile/features/admin/orders/presentation/admin_orders_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Admin Panel Bug Fixes & UI Refinements', () {
    testWidgets('1. Admin Inventory Tab uses CustomScrollView and does not overflow on 360px width', (tester) async {
      // Simulate narrow mobile screen (360x780)
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminInventoryTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify CustomScrollView is present for single main scroll mechanism
      expect(find.byType(CustomScrollView), findsOneWidget);

      // Verify header contents
      expect(find.text('Manajemen Inventaris & Bahan'), findsOneWidget);
      expect(find.text('Restock Masuk'), findsOneWidget);
      expect(find.text('Total SKU'), findsOneWidget);

      // Verify stock card content is present
      expect(find.textContaining('Stok Tersedia:'), findsWidgets);
      expect(find.text('Sesuaikan'), findsWidgets);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Admin Analytics Tab Rekomendasi Menu & Evaluasi Penjualan renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminAnalyticsTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rekomendasi Menu & Evaluasi Penjualan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Admin Promotions Tab voucher cards render without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminPromotionsTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manajemen Voucher & Promosi'), findsOneWidget);
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Hapus'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Admin Menu Tab uses CustomScrollView for unified scrolling and renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminMenuTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Manajemen Menu & Katalog'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('Tambah Menu Baru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Admin Orders Tab uses CustomScrollView for unified scrolling and renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminOrdersTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Antrean Pesanan'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Admin Dashboard Tab renders enriched KPI cards, best seller image, financial trend strip, and sales chart', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminDashboardTab(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ringkasan Bisnis & Dapur'), findsOneWidget);
      expect(find.text('TOTAL OMSET 7 HARI'), findsOneWidget);
      expect(find.text('Grafik Penjualan Ringkas'), findsOneWidget);
      expect(find.text('Lihat Detail →'), findsOneWidget);
      expect(find.text('PRODUK TERLARIS MINGGU INI'), findsOneWidget);
      // Verify images are present in the top products section and best seller card
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
