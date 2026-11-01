import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/branch/models/branch_model.dart';
import 'package:mobile/features/orders/models/order_model.dart';

void main() {
  group('Multi-Branch Location Feature Tests', () {
    test('Official branches list contains exactly 7 branches', () {
      final branches = BranchModel.defaultBranches;
      expect(branches.length, 7);
    });

    test('Customer branch display list adheres to exact canonical order with Maluku directly below PIK', () {
      final branches = BranchModel.defaultBranches;
      final branchIds = branches.map((b) => b.id).toList();

      // Canonical customer order:
      // 1. Senopati (out-1)
      // 2. PIK (out-2)
      // 3. Maluku (out-7)
      // 4. Bali (out-4)
      // 5. London (out-3)
      // 6. Malaysia (out-5)
      // 7. Singapore (out-6)
      expect(branchIds, ['out-1', 'out-2', 'out-7', 'out-4', 'out-3', 'out-5', 'out-6']);

      // Explicitly check Maluku position
      expect(branches[0].id, 'out-1'); // Senopati
      expect(branches[1].id, 'out-2'); // PIK
      expect(branches[2].id, 'out-7'); // Maluku immediately below PIK
      expect(branches[2].name, 'Bun Atelier — Maluku');
    });

    test('Senopati and PIK branches retain their exact existing IDs, names, and verified coordinates', () {
      final branches = BranchModel.defaultBranches;

      final senopati = branches.firstWhere((b) => b.id == 'out-1');
      expect(senopati.name, 'Bun Atelier — Senopati Flagship');
      expect(senopati.city, 'Jakarta Selatan');
      expect(senopati.country, 'Indonesia');
      expect(senopati.address, 'Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan');
      expect(senopati.timezone, 'Asia/Jakarta');
      expect(senopati.timezoneLabel, 'WIB (UTC+7)');
      expect(senopati.currencyCode, 'IDR');
      expect(senopati.isVerified, isTrue);
      expect(senopati.latitude, -6.2298);
      expect(senopati.longitude, 106.8097);
      expect(senopati.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=-6.2298,106.8097');

      final pik = branches.firstWhere((b) => b.id == 'out-2');
      expect(pik.name, 'Bun Atelier — PIK 2 Waterfront');
      expect(pik.city, 'Jakarta Utara');
      expect(pik.country, 'Indonesia');
      expect(pik.address, 'Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara');
      expect(pik.timezone, 'Asia/Jakarta');
      expect(pik.timezoneLabel, 'WIB (UTC+7)');
      expect(pik.currencyCode, 'IDR');
      expect(pik.isVerified, isTrue);
      expect(pik.latitude, -6.1089);
      expect(pik.longitude, 106.7410);
      expect(pik.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=-6.1089,106.741');
    });

    test('All 7 branches have complete addresses and specific Google Maps URLs, with only Senopati and PIK having verified badges', () {
      final branches = BranchModel.defaultBranches;
      expect(branches.length, 7);

      for (final branch in branches) {
        expect(branch.address, isNotNull, reason: '${branch.name} must have a non-null address');
        expect(branch.address!.isNotEmpty, isTrue, reason: '${branch.name} must have a non-empty address');
        expect(branch.latitude, isNotNull, reason: '${branch.name} must have latitude');
        expect(branch.longitude, isNotNull, reason: '${branch.name} must have longitude');
        expect(branch.effectiveMapsUrl, contains('https://www.google.com/maps/search/?api=1&query='));
      }

      // Check verified badge status: Only Senopati and PIK are verified
      final verifiedBranches = branches.where((b) => b.isVerified).map((b) => b.id).toList();
      expect(verifiedBranches, ['out-1', 'out-2']);

      // 3. Maluku (Replaced Papua)
      final maluku = branches.firstWhere((b) => b.id == 'out-7');
      expect(maluku.name, 'Bun Atelier — Maluku');
      expect(maluku.city, 'Kota Ambon, Maluku');
      expect(maluku.country, 'Indonesia');
      expect(maluku.address, 'Jl. Jenderal Sudirman No. 88, Kel. Sirimau, Kec. Sirimau, Kota Ambon, Maluku, Indonesia');
      expect(maluku.timezone, 'Asia/Jayapura');
      expect(maluku.timezoneLabel, 'WIT (UTC+9)');
      expect(maluku.currencyCode, 'IDR');
      expect(maluku.currencyLabel, 'IDR (Rp)');
      expect(maluku.latitude, -3.6931);
      expect(maluku.longitude, 128.1884);
      expect(maluku.isVerified, isFalse);
      expect(maluku.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=-3.6931,128.1884');

      // 4. Bali
      final bali = branches.firstWhere((b) => b.id == 'out-4');
      expect(bali.name, 'Bun Atelier — Bali');
      expect(bali.city, 'Bali');
      expect(bali.country, 'Indonesia');
      expect(bali.address, contains('Seminyak'));
      expect(bali.timezone, 'Asia/Makassar');
      expect(bali.timezoneLabel, 'WITA (UTC+8)');
      expect(bali.currencyCode, 'IDR');
      expect(bali.isVerified, isFalse);
      expect(bali.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=-8.6882,115.1565');

      // 5. London
      final london = branches.firstWhere((b) => b.id == 'out-3');
      expect(london.name, 'Bun Atelier — London');
      expect(london.city, 'London');
      expect(london.country, 'United Kingdom');
      expect(london.address, contains('Soho'));
      expect(london.timezone, 'Europe/London');
      expect(london.timezoneLabel, 'GMT (UTC+0)');
      expect(london.currencyCode, 'GBP');
      expect(london.isVerified, isFalse);
      expect(london.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=51.5132,-0.1318');

      // 6. Kuala Lumpur
      final kl = branches.firstWhere((b) => b.id == 'out-5');
      expect(kl.name, 'Bun Atelier — Kuala Lumpur');
      expect(kl.city, 'Kuala Lumpur');
      expect(kl.country, 'Malaysia');
      expect(kl.address, contains('Bukit Bintang'));
      expect(kl.timezone, 'Asia/Kuala_Lumpur');
      expect(kl.timezoneLabel, 'MYT (UTC+8)');
      expect(kl.currencyCode, 'MYR');
      expect(kl.isVerified, isFalse);
      expect(kl.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=3.1466,101.7112');

      // 7. Singapore
      final singapore = branches.firstWhere((b) => b.id == 'out-6');
      expect(singapore.name, 'Bun Atelier — Singapore');
      expect(singapore.city, 'Singapore');
      expect(singapore.country, 'Singapore');
      expect(singapore.address, contains('Keong Saik'));
      expect(singapore.timezone, 'Asia/Singapore');
      expect(singapore.timezoneLabel, 'SGT (UTC+8)');
      expect(singapore.currencyCode, 'SGD');
      expect(singapore.isVerified, isFalse);
      expect(singapore.effectiveMapsUrl, 'https://www.google.com/maps/search/?api=1&query=1.2801,103.8415');
    });

    test('OrderItemModel retains branchId, branchName, timezone, currency, and formats WIT time correctly', () {
      // 08:00 UTC = 17:00 WIT (UTC+9 in Asia/Jayapura)
      final fixedUtc = DateTime.utc(2026, 10, 27, 8, 0);

      final orderMaluku = OrderItemModel(
        id: 'ord-test-maluku',
        orderNumber: 'BA-20261027-007',
        createdAt: fixedUtc,
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        status: 'CONFIRMED',
        subtotal: 72000,
        tax: 7200,
        total: 79200,
        itemsSummary: '1x OG Main Character',
        branchId: 'out-7',
        branchName: 'Bun Atelier — Maluku',
        branchTimezone: 'Asia/Jayapura',
        branchCurrency: 'IDR',
      );

      expect(orderMaluku.branchId, 'out-7');
      expect(orderMaluku.branchName, 'Bun Atelier — Maluku');
      expect(orderMaluku.branchTimezone, 'Asia/Jayapura');
      expect(orderMaluku.timezoneLabel, 'WIT (UTC+9)');
      expect(orderMaluku.branchCurrency, 'IDR');
      expect(orderMaluku.currencySymbol, 'Rp ');
      expect(orderMaluku.formattedTransactionTime(), '2026-10-27 17:00 WIT (UTC+9)');

      // Also verify Jakarta timezone (Senopati / PIK) formats as WIB (UTC+7)
      final orderJakarta = orderMaluku.copyWith(
        branchId: 'out-1',
        branchName: 'Bun Atelier — Senopati Flagship',
        branchTimezone: 'Asia/Jakarta',
      );
      expect(orderJakarta.timezoneLabel, 'WIB (UTC+7)');
      expect(orderJakarta.formattedTransactionTime(), '2026-10-27 15:00 WIB (UTC+7)');

      // And Bali formats as WITA (UTC+8)
      final orderBali = orderMaluku.copyWith(
        branchId: 'out-4',
        branchName: 'Bun Atelier — Bali',
        branchTimezone: 'Asia/Makassar',
      );
      expect(orderBali.timezoneLabel, 'WITA (UTC+8)');
      expect(orderBali.formattedTransactionTime(), '2026-10-27 16:00 WITA (UTC+8)');
    });
  });
}
