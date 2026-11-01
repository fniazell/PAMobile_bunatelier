import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Can be set at runtime (e.g. for testing on physical devices)
  static String? customBaseUrl;

  // Configurable base URL
  // On Android emulator: 10.0.2.2 connects to host machine's localhost
  // On Web / Windows Desktop: localhost works directly
  // Override with --dart-define=API_BASE_URL=... for a physical device or deployment.
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!.replaceFirst(RegExp(r'/+$'), '');
    }
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      return 'http://192.168.100.32:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  // Endpoints
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String categories = '/categories';
  static const String products = '/products';
  static const String addons = '/addons';
  static const String orders = '/orders';
  static const String cashierOrders = '/cashier/orders';
  static const String outlets = '/outlets';
  static const String aiChat = '/ai/chat';
  static const String supportChat = '/support/chat';
  static const String feedback = '/feedback';
  static const String blockchainChain = '/blockchain/chain';
  static const String blockchainVerify = '/blockchain/verify';

  // External APIs
  static const String frankfurterBaseUrl = 'https://api.frankfurter.dev/v1';
}
