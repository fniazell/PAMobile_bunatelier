import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/profile/providers/settings_provider.dart';
import 'package:mobile/features/support/presentation/support_chat_screen.dart';
import 'package:mobile/features/support/services/support_chat_service.dart';

void main() {
  group('SupportChat Feature Unit & Widget Tests', () {
    test('SupportChatMessage creates history payload accurately for Gemini', () {
      final userMsg = SupportChatMessage(
        text: 'Berapa harga OG Main Character?',
        isUser: true,
        timestamp: DateTime(2026, 10, 22, 10, 30),
      );

      final modelMsg = SupportChatMessage(
        text: 'OG Main Character harganya Rp 72.000.',
        isUser: false,
        timestamp: DateTime(2026, 10, 22, 10, 31),
      );

      expect(userMsg.toHistoryMap(), {'role': 'user', 'text': 'Berapa harga OG Main Character?'});
      expect(modelMsg.toHistoryMap(), {'role': 'model', 'text': 'OG Main Character harganya Rp 72.000.'});
    });

    test('SupportChatMessage copyWith preserves or modifies fields', () {
      final msg = SupportChatMessage(
        text: 'Halo',
        isUser: true,
        timestamp: DateTime.now(),
        isSending: true,
        hasError: false,
      );

      final updated = msg.copyWith(isSending: false, hasError: true);
      expect(updated.text, 'Halo');
      expect(updated.isUser, true);
      expect(updated.isSending, false);
      expect(updated.hasError, true);
    });

    testWidgets('SupportChatScreen renders app bar, welcome message and quick chips (Indonesian)', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set language to Indonesian
      await container.read(settingsProvider.notifier).setLanguage('id');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // App bar title & status
      expect(find.text('Customer Support'), findsOneWidget);
      expect(find.textContaining('Gemini AI Concierge'), findsOneWidget);

      // Welcome message (rendered inside _buildRichText / RichText)
      expect(find.textContaining('Bun Atelier Support', findRichText: true), findsOneWidget);

      // Quick action chips in Indonesian
      expect(find.textContaining('Status Pesanan'), findsOneWidget);
      expect(find.textContaining('Lokasi Outlet'), findsOneWidget);
      expect(find.textContaining('Pembayaran'), findsOneWidget);

      // Input field
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
