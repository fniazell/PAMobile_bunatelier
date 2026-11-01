import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/core/localization/app_strings.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/profile/providers/settings_provider.dart';

import 'package:mobile/core/storage/secure_storage_service.dart';

void main() {
  setUp(() async {
    await SecureStorageService().clearAll();
  });

  group('Settings Feature Tests', () {
    test('AppStrings provides correct translations for English and Indonesian', () {
      expect(AppStrings.tr('settings_title', 'en'), 'Settings');
      expect(AppStrings.tr('language', 'en'), 'Language');
      expect(AppStrings.tr('theme', 'en'), 'Theme');
      expect(AppStrings.tr('notifications', 'en'), 'Notifications');
      expect(AppStrings.tr('contact_support', 'en'), 'Contact support');

      // Indonesian
      expect(AppStrings.tr('settings_title', 'id'), 'Pengaturan');
      expect(AppStrings.tr('language', 'id'), 'Bahasa');
      expect(AppStrings.tr('theme', 'id'), 'Tema');
      expect(AppStrings.tr('notifications', 'id'), 'Notifikasi');
      expect(AppStrings.tr('contact_support', 'id'), 'Layanan Bantuan');
      expect(AppStrings.tr('nav_home', 'id'), 'BERANDA');
      expect(AppStrings.tr('nav_orders', 'id'), 'PESANAN');
      expect(AppStrings.tr('nav_rewards', 'id'), 'HADIAH');
      expect(AppStrings.tr('nav_profile', 'id'), 'PROFIL');
      expect(AppStrings.tr('theme_light', 'id'), 'Terang');
      expect(AppStrings.tr('theme_dark', 'id'), 'Gelap');
      expect(AppStrings.tr('enabled', 'id'), 'Aktif');
      expect(AppStrings.tr('disabled', 'id'), 'Nonaktif');
    });

    test('SettingsNotifier setLanguage switches language to Indonesian and updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(settingsProvider).languageCode, 'en');
      expect(container.read(settingsProvider).languageName, 'English');

      await container.read(settingsProvider.notifier).setLanguage('id');

      expect(container.read(settingsProvider).languageCode, 'id');
      expect(container.read(settingsProvider).languageName, 'Bahasa Indonesia');
      expect(container.read(settingsProvider).t('language'), 'Bahasa');
      expect(container.read(settingsProvider).t('settings_title'), 'Pengaturan');
    });

    testWidgets('Settings section renders with Language, Theme, Notifications, and Contact support',
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

      // Verify Settings Card exists
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);

      // Verify default values
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
    });

    testWidgets('Tapping Notifications toggles between Enabled and Disabled',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially Enabled
      expect(find.text('Enabled'), findsOneWidget);

      // Tap Notifications tile
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      // Toggled to Disabled
      expect(find.text('Disabled'), findsOneWidget);

      // Tap again -> Enabled
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Enabled'), findsOneWidget);
    });

    testWidgets('Tapping Language opens language dialog and switching to Indonesian updates UI',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/support-chat',
            builder: (context, state) => const Scaffold(body: Text('Customer Support Chat')),
          ),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Language tile
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);

      // Select Bahasa Indonesia
      await tester.tap(find.text('Bahasa Indonesia'));
      await tester.pumpAndSettle();

      // Dialog closed and profile page updated to Indonesian
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Bahasa'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsOneWidget);
    });
  });
}
