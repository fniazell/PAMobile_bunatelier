import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/saran_pesan/models/saran_pesan_model.dart';
import 'package:mobile/features/saran_pesan/services/saran_pesan_service.dart';
import 'package:mobile/features/saran_pesan/presentation/widgets/saran_pesan_history_card.dart';

void main() {
  group('Saran & Pesan Feature - Unit Tests', () {
    test('SaranPesanModel toSqliteMap and fromMap conversion works correctly', () {
      final now = DateTime.utc(2026, 11, 9, 10, 0, 0);
      final model = SaranPesanModel(
        id: 'SP-12345',
        userId: 'USER-999',
        userName: 'Mahasiswa Bun',
        userEmail: 'mahasiswa@bunatelier.com',
        saran: 'Praktikum mobile dibuat lebih variatif dan menantang.',
        pesan: 'Terima kasih kepada dosen pengampu atas bimbingannya.',
        createdAt: now,
        isSynced: true,
      );

      final sqliteMap = model.toSqliteMap();
      expect(sqliteMap['id'], 'SP-12345');
      expect(sqliteMap['user_id'], 'USER-999');
      expect(sqliteMap['saran'], contains('Praktikum mobile'));
      expect(sqliteMap['pesan'], contains('Terima kasih'));
      expect(sqliteMap['is_synced'], 1);

      final restored = SaranPesanModel.fromMap(sqliteMap);
      expect(restored.id, 'SP-12345');
      expect(restored.userId, 'USER-999');
      expect(restored.userName, 'Mahasiswa Bun');
      expect(restored.saran, model.saran);
      expect(restored.pesan, model.pesan);
      expect(restored.isSynced, true);
    });

    test('SaranPesanModel toSupabaseMap excludes sqlite-only flags', () {
      final now = DateTime.utc(2026, 11, 9, 10, 0, 0);
      final model = SaranPesanModel(
        id: 'SP-12345',
        userId: 'USER-999',
        saran: 'Saran mata kuliah',
        pesan: 'Pesan dosen',
        createdAt: now,
      );

      final supabaseMap = model.toSupabaseMap();
      expect(supabaseMap['id'], 'SP-12345');
      expect(supabaseMap['user_id'], 'USER-999');
      expect(supabaseMap['saran'], 'Saran mata kuliah');
      expect(supabaseMap['pesan'], 'Pesan dosen');
      expect(supabaseMap.containsKey('is_synced'), false);
    });

    test('SaranPesanService validates empty userId', () async {
      final service = SaranPesanService();
      final item = SaranPesanModel(
        id: 'SP-1',
        userId: '',
        saran: 'Saran',
        pesan: 'Pesan',
        createdAt: DateTime.now(),
      );

      final res = await service.submitSaranPesan(item);
      expect(res.success, false);
      expect(res.errorMessage, contains('login terlebih dahulu'));
    });

    test('SaranPesanService validates empty saran', () async {
      final service = SaranPesanService();
      final item = SaranPesanModel(
        id: 'SP-1',
        userId: 'USER-1',
        saran: '   ',
        pesan: 'Pesan',
        createdAt: DateTime.now(),
      );

      final res = await service.submitSaranPesan(item);
      expect(res.success, false);
      expect(res.errorMessage, contains('Saran untuk Mata Kuliah Pemrograman Aplikasi Mobile wajib diisi'));
    });

    test('SaranPesanService validates empty pesan', () async {
      final service = SaranPesanService();
      final item = SaranPesanModel(
        id: 'SP-1',
        userId: 'USER-1',
        saran: 'Saran yang baik',
        pesan: '   ',
        createdAt: DateTime.now(),
      );

      final res = await service.submitSaranPesan(item);
      expect(res.success, false);
      expect(res.errorMessage, contains('Pesan untuk Dosen Pengampu wajib diisi'));
    });

    testWidgets('SaranPesanHistoryCard renders saran and pesan cleanly', (tester) async {
      final item = SaranPesanModel(
        id: 'SP-1',
        userId: 'USER-1',
        saran: 'Tambahkan materi Flutter testing lebih mendalam.',
        pesan: 'Dosen sangat komunikatif dan jelas dalam mengajar.',
        createdAt: DateTime.now(),
        isSynced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaranPesanHistoryCard(item: item),
          ),
        ),
      );

      expect(find.text('Saran untuk Mata Kuliah:'), findsOneWidget);
      expect(find.text('Tambahkan materi Flutter testing lebih mendalam.'), findsOneWidget);
      expect(find.text('Pesan untuk Dosen Pengampu:'), findsOneWidget);
      expect(find.text('Dosen sangat komunikatif dan jelas dalam mengajar.'), findsOneWidget);
      expect(find.text('TERKIRIM (CLOUD)'), findsOneWidget);
    });
  });
}

