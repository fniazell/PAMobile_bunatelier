import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local/app_database.dart';
import 'data/remote/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

  // Initialize SQLite database on mobile platforms (Android/iOS)
  if (!kIsWeb) {
    try {
      await AppDatabase.instance.database;
    } catch (e) {
      debugPrint('Database initialization warning: $e');
    }
  }

  runApp(const ProviderScope(child: BunAtelierApp()));
}
