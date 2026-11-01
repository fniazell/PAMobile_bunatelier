import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/secure_storage_service.dart';

class SettingsState {
  final String languageCode; // 'en' or 'id'
  final ThemeMode themeMode; // ThemeMode.light or ThemeMode.dark
  final bool notificationsEnabled;

  const SettingsState({
    this.languageCode = 'en',
    this.themeMode = ThemeMode.light,
    this.notificationsEnabled = true,
  });

  Locale get locale => Locale(languageCode);
  bool get isDark => themeMode == ThemeMode.dark;
  String get languageName =>
      languageCode == 'id' ? 'Bahasa Indonesia' : 'English';
  String get themeName => themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  String get notificationsLabel =>
      notificationsEnabled ? 'Enabled' : 'Disabled';

  String t(String key) => AppStrings.tr(key, languageCode);

  SettingsState copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SecureStorageService _storage;
  final NotificationService _notificationService = NotificationService();

  SettingsNotifier(this._storage) : super(const SettingsState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final lang = await _storage.getLanguage();
      final theme = await _storage.getThemeMode();
      final notifs = await _storage.isNotificationsEnabled();

      ThemeMode mode = state.themeMode;
      if (theme == 'dark') {
        mode = ThemeMode.dark;
      } else if (theme == 'light') {
        mode = ThemeMode.light;
      }

      state = state.copyWith(
        languageCode: lang != null ? ((lang == 'id') ? 'id' : 'en') : state.languageCode,
        themeMode: mode,
        notificationsEnabled: notifs,
      );

      if (notifs) {
        await _notificationService.init();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    final validCode = (code == 'id') ? 'id' : 'en';
    state = state.copyWith(languageCode: validCode);
    try {
      await _storage.setLanguage(validCode);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      await _storage.setThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final next = state.isDark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    try {
      await _storage.setNotificationsEnabled(enabled);
      if (enabled) {
        await _notificationService.init();
        await _notificationService.requestPermissions();
      } else {
        await _notificationService.cancelAll();
      }
    } catch (_) {}
  }

  Future<void> toggleNotifications() async {
    await setNotificationsEnabled(!state.notificationsEnabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(SecureStorageService());
});
