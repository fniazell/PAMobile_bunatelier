class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Navigation
      'nav_home': 'HOME',
      'nav_menu': 'MENU',
      'nav_orders': 'ORDERS',
      'nav_rewards': 'REWARDS',
      'nav_profile': 'PROFILE',

      // Profile Screen
      'user_profile': 'USER PROFILE',
      'edit_profile': 'Edit Profile',
      'security_prefs': 'SECURITY & PREFERENCES',
      'biometrics_title': 'Biometric Authentication',
      'biometrics_subtitle': 'Unlock app using Fingerprint / Face',
      'my_orders': 'My Orders',
      'our_outlets': 'Our Outlets',
      'academic_tools': 'ACADEMIC UTILITIES & TOOLS',
      'blockchain_audit': 'Blockchain Audit Trail',
      'blockchain_subtitle': 'SHA-256 Hash Chain verification',
      'mini_game': 'Stack Your Bun Mini-game',
      'mini_game_subtitle': 'Sensors_plus physics gameplay',
      'sign_out': 'SIGN OUT',
      'confirm_sign_out': 'Confirm Sign Out',
      'sign_out_message': 'Are you sure you want to sign out from Bun Atelier?',
      'cancel': 'CANCEL',
      'log_out': 'LOG OUT',

      // Settings Section
      'settings_title': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'notifications': 'Notifications',
      'contact_support': 'Contact support',
      'lang_en': 'English',
      'lang_id': 'Bahasa Indonesia',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'enabled': 'Enabled',
      'disabled': 'Disabled',

      // Dialogs & Modals
      'select_language': 'Select Language',
      'select_theme': 'Select Theme',
      'theme_light_desc': 'Warm paper cream editorial aesthetic',
      'theme_dark_desc': 'Rich dark espresso roast aesthetic',
      'notifications_dialog_title': 'Push Notifications',
      'notifications_dialog_desc':
          'Receive real-time order updates, chef tasting specials, and atelier dining perks.',
      'support_title': 'Concierge & Customer Support',
      'support_subtitle':
          'We are delighted to assist your dining and ordering experience.',
      'support_email_label': 'Official Concierge Email',
      'support_outlets_header': 'Our Atelier Outlets',
      'view_outlets_button': 'VIEW OUTLETS ON MAP',
      'copied_email': 'Concierge email copied to clipboard',

      // Feedback
      'lang_changed_en': 'Language set to English',
      'lang_changed_id': 'Bahasa diubah ke Bahasa Indonesia',
      'theme_set_light': 'Switched to Light Theme',
      'theme_set_dark': 'Switched to Dark Theme',
      'notif_enabled': 'Notifications enabled',
      'notif_disabled': 'Notifications disabled',
    },
    'id': {
      // Navigation
      'nav_home': 'BERANDA',
      'nav_menu': 'MENU',
      'nav_orders': 'PESANAN',
      'nav_rewards': 'HADIAH',
      'nav_profile': 'PROFIL',

      // Profile Screen
      'user_profile': 'PROFIL PENGGUNA',
      'edit_profile': 'Ubah Profil',
      'security_prefs': 'KEAMANAN & PREFERENSI',
      'biometrics_title': 'Autentikasi Biometrik',
      'biometrics_subtitle': 'Buka aplikasi dengan Sidik Jari / Wajah',
      'my_orders': 'Pesanan Saya',
      'our_outlets': 'Outlet Kami',
      'academic_tools': 'UTILITAS & ALAT AKADEMIK',
      'blockchain_audit': 'Audit Trail Blockchain',
      'blockchain_subtitle': 'Verifikasi SHA-256 Hash Chain',
      'mini_game': 'Mini-game Susun Bun',
      'mini_game_subtitle': 'Fisika gerak sensor & gameplay',
      'sign_out': 'KELUAR',
      'confirm_sign_out': 'Konfirmasi Keluar',
      'sign_out_message': 'Apakah Anda yakin ingin keluar dari Bun Atelier?',
      'cancel': 'BATAL',
      'log_out': 'KELUAR',

      // Settings Section
      'settings_title': 'Pengaturan',
      'language': 'Bahasa',
      'theme': 'Tema',
      'notifications': 'Notifikasi',
      'contact_support': 'Layanan Bantuan',
      'lang_en': 'English',
      'lang_id': 'Bahasa Indonesia',
      'theme_light': 'Terang',
      'theme_dark': 'Gelap',
      'enabled': 'Aktif',
      'disabled': 'Nonaktif',

      // Dialogs & Modals
      'select_language': 'Pilih Bahasa',
      'select_theme': 'Pilih Tema',
      'theme_light_desc': 'Estetika editorial krem kertas hangat',
      'theme_dark_desc': 'Estetika espresso roast mewah gelap',
      'notifications_dialog_title': 'Notifikasi Aplikasi',
      'notifications_dialog_desc':
          'Dapatkan info status pesanan terkini, promo menu spesial chef, dan promo atelier.',
      'support_title': 'Layanan Concierge & Bantuan',
      'support_subtitle':
          'Kami dengan senang hati membantu pengalaman bersantap dan pesanan Anda.',
      'support_email_label': 'Email Resmi Concierge',
      'support_outlets_header': 'Outlet Atelier Kami',
      'view_outlets_button': 'LIHAT OUTLET DI PETA',
      'copied_email': 'Email Concierge disalin ke clipboard',

      // Feedback
      'lang_changed_en': 'Bahasa diubah ke English',
      'lang_changed_id': 'Bahasa berhasil diubah ke Bahasa Indonesia',
      'theme_set_light': 'Beralih ke Tema Terang (Light)',
      'theme_set_dark': 'Beralih ke Tema Gelap (Dark)',
      'notif_enabled': 'Notifikasi diaktifkan',
      'notif_disabled': 'Notifikasi dinonaktifkan',
    },
  };

  static String tr(String key, String langCode) {
    final lang = _localizedValues.containsKey(langCode) ? langCode : 'en';
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}
