import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      await _createSaranPesanTable(_database!);
      return _database!;
    }
    _database = await _initDB('bun_atelier.db');
    await _createSaranPesanTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 11,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Cached Products Table (Offline catalog support)
    await db.execute('''
      CREATE TABLE cached_products (
        id TEXT PRIMARY KEY,
        category_slug TEXT NOT NULL,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        description TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        price_idr INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        is_available INTEGER NOT NULL DEFAULT 1,
        is_spicy INTEGER NOT NULL DEFAULT 0,
        is_best_seller INTEGER NOT NULL DEFAULT 0,
        cached_at TEXT NOT NULL
      )
    ''');

    // 2. Local Cart Table (Persistent cart items across app restarts)
    await db.execute('''
      CREATE TABLE local_cart (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        addons_json TEXT NOT NULL DEFAULT '[]',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. User Preferences Table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await createRewardTables(db);
    await _createOrderTables(db);
    await _createBranchTables(db);
    await _createVoucherTables(db);
    await _createSaranPesanTable(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await createRewardTables(db);
    }
    if (oldVersion < 3) {
      await _createOrderTables(db);
    }
    if (oldVersion < 4) {
      await _createBranchTables(db);
      try {
        await db.execute('ALTER TABLE cached_orders ADD COLUMN branch_id TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN branch_name TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE cached_branches ADD COLUMN timezone TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_branches ADD COLUMN currency_code TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN branch_timezone TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN branch_currency TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await _createVoucherTables(db);
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_code TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_discount_amount INTEGER',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_tx_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_reference_id TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN receipt_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN receipt_previous_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN receipt_tx_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN receipt_explorer_url TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN receipt_is_simulated INTEGER DEFAULT 1',
        );
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_redemption_tx_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_usage_tx_hash TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN voucher_is_simulated INTEGER DEFAULT 1',
        );
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN customer_name TEXT',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN customer_phone TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute(
          'ALTER TABLE cached_orders ADD COLUMN user_id TEXT',
        );
      } catch (_) {}
    }
    if (oldVersion < 11) {
      await _createSaranPesanTable(db);
    }
  }

  Future<void> _createOrderTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_orders (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        order_number TEXT NOT NULL,
        created_at TEXT NOT NULL,
        order_type TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        status TEXT NOT NULL,
        subtotal INTEGER NOT NULL,
        tax INTEGER NOT NULL,
        delivery_fee INTEGER NOT NULL,
        total INTEGER NOT NULL,
        items_summary TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        delivery_address TEXT,
        notes TEXT,
        branch_id TEXT,
        branch_name TEXT,
        branch_timezone TEXT,
        branch_currency TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _createBranchTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_branches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        maps_query TEXT,
        maps_url TEXT,
        operating_hours TEXT,
        phone TEXT,
        timezone TEXT DEFAULT 'Asia/Jakarta',
        currency_code TEXT DEFAULT 'IDR',
        is_active INTEGER NOT NULL DEFAULT 1,
        is_verified INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _createSaranPesanTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS course_saran_pesan (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT,
        user_email TEXT,
        saran TEXT NOT NULL,
        pesan TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_course_saran_pesan_user_id
      ON course_saran_pesan(user_id, created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_course_saran_pesan_created_at
      ON course_saran_pesan(created_at DESC)
    ''');
  }

  // ── SQFLITE CRUD: SARAN & PESAN (Mata Kuliah PAM) ─────────────────────────
  Future<int> insertSaranPesan(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(
      'course_saran_pesan',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSaranPesanByUser(String userId) async {
    final db = await database;
    return await db.query(
      'course_saran_pesan',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllSaranPesan() async {
    final db = await database;
    return await db.query(
      'course_saran_pesan',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteSaranPesan(String id) async {
    final db = await database;
    return await db.delete(
      'course_saran_pesan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── SQFLITE CRUD: ORDERS ──────────────────────────────────────────────────
  Future<void> insertCachedOrder(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      await db.insert(
        'cached_orders',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedOrders({String? userId}) async {
    try {
      final db = await instance.database;
      if (userId != null && userId.isNotEmpty) {
        return await db.query(
          'cached_orders',
          where: 'user_id = ? OR user_id IS NULL',
          whereArgs: [userId],
          orderBy: 'created_at DESC',
        );
      }
      return await db.query('cached_orders', orderBy: 'created_at DESC');
    } catch (_) {
      return [];
    }
  }

  Future<void> updateCachedOrderStatus(String orderId, String newStatus) async {
    try {
      final db = await instance.database;
      await db.update(
        'cached_orders',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    } catch (_) {}
  }

  Future<void> updateOrderReceiptBlockchain({
    required String orderId,
    required String receiptHash,
    required String receiptPreviousHash,
    required String txHash,
    String? explorerUrl,
    required int isSimulated,
  }) async {
    try {
      final db = await instance.database;
      await db.update(
        'cached_orders',
        {
          'receipt_hash': receiptHash,
          'receipt_previous_hash': receiptPreviousHash,
          'receipt_tx_hash': txHash,
          'receipt_explorer_url': explorerUrl,
          'receipt_is_simulated': isSimulated,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    } catch (_) {}
  }

  Future<void> updateOrderVoucherUsage({
    required String orderId,
    required String usageTxHash,
    bool isSimulated = true,
  }) async {
    try {
      final db = await instance.database;
      await db.update(
        'cached_orders',
        {
          'voucher_usage_tx_hash': usageTxHash,
          'voucher_tx_hash': usageTxHash,
          'voucher_is_simulated': isSimulated ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    } catch (_) {}
  }

  // ── SQFLITE CRUD: BRANCHES ────────────────────────────────────────────────
  Future<void> insertCachedBranch(Map<String, dynamic> row) async {
    try {
      final db = await instance.database;
      await db.insert(
        'cached_branches',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedBranches() async {
    try {
      final db = await instance.database;
      return await db.query('cached_branches', orderBy: 'id ASC');
    } catch (_) {
      return [];
    }
  }

  Future<void> updateCachedBranch(
    String branchId,
    Map<String, dynamic> values,
  ) async {
    try {
      final db = await instance.database;
      await db.update(
        'cached_branches',
        values,
        where: 'id = ?',
        whereArgs: [branchId],
      );
    } catch (_) {}
  }

  // ── SQFLITE CRUD: USER PREFERENCES ──────────────────────────────────────
  Future<void> setUserPreference(String key, String value) async {
    try {
      final db = await instance.database;
      await db.insert('user_preferences', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<String?> getUserPreference(String key) async {
    try {
      final db = await instance.database;
      final results = await db.query(
        'user_preferences',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first['value']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Helper method to close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

Future<void> createRewardTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS game_reward_sessions (
      session_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      score INTEGER NOT NULL,
      stacked_ingredients INTEGER NOT NULL,
      precision_hits INTEGER NOT NULL,
      victory INTEGER NOT NULL,
      points_awarded INTEGER NOT NULL,
      played_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS game_reward_sessions_user_played
    ON game_reward_sessions (user_id, played_at DESC)
  ''');
  await createVoucherTables(db);
}

Future<void> _createVoucherTables(DatabaseExecutor db) async {
  await createVoucherTables(db);
}

Future<void> createVoucherTables(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS user_vouchers (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      voucher_type TEXT NOT NULL,
      discount_percent INTEGER NOT NULL,
      points_cost INTEGER NOT NULL,
      status TEXT NOT NULL,
      issued_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      used_at TEXT,
      used_order_id TEXT,
      redemption_reference_id TEXT NOT NULL,
      redemption_tx_hash TEXT,
      blockchain_status TEXT NOT NULL,
      usage_tx_hash TEXT,
      usage_reference_id TEXT
    )
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_user_vouchers_user_status
    ON user_vouchers (user_id, status)
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS user_point_redemptions (
      redemption_id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      voucher_id TEXT NOT NULL,
      points_spent INTEGER NOT NULL,
      redeemed_at TEXT NOT NULL,
      reference_id TEXT NOT NULL UNIQUE,
      blockchain_status TEXT NOT NULL,
      tx_hash TEXT
    )
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_user_point_redemptions_user
    ON user_point_redemptions (user_id)
  ''');
}
