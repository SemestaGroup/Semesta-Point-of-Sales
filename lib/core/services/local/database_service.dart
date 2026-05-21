import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static Completer<Database>? _dbCompleter;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    // If already ready and open, return immediately
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    // If it was set but then closed or crashed, clear it
    if (_database != null && !_database!.isOpen) {
      debugPrint('DatabaseService: _database was CLOSED, resetting...');
      _database = null;
    }

    debugPrint(
        'DatabaseService: database getter called. _database ready: false, _dbCompleter active: ${_dbCompleter != null}');

    // Safety check to prevent multiple concurrent initializations
    if (_dbCompleter != null) {
      debugPrint(
          'DatabaseService: waiting for existing _dbCompleter future...');
      return _dbCompleter!.future.timeout(const Duration(seconds: 10),
          onTimeout: () {
        debugPrint(
            'DatabaseService: TIMEOUT waiting for _dbCompleter! Creating new one...');
        _dbCompleter = null;
        throw Exception('Database initialization timeout');
      });
    }

    _dbCompleter = Completer<Database>();
    try {
      debugPrint('DatabaseService: Starting _initDatabase...');
      final db = await _initDatabase();
      _database = db;
      debugPrint(
          'DatabaseService: _initDatabase completed and _database instance set (isOpen: ${db.isOpen})');
      _dbCompleter!.complete(db);
      _dbCompleter = null;
      return db;
    } catch (e) {
      debugPrint('DatabaseService: _initDatabase FAILED: $e');
      if (_dbCompleter != null && !_dbCompleter!.isCompleted) {
        _dbCompleter!.completeError(e);
      }
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    debugPrint('SQLite: Opening database at $path with version 43');
    return await openDatabase(
      path,
      version: 43,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 43) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cash_flow(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expense_name TEXT DEFAULT '',
            note TEXT DEFAULT '',
            amount INTEGER NOT NULL DEFAULT 0,
            direction TEXT DEFAULT 'out',
            staff_name TEXT DEFAULT '',
            staff_email TEXT DEFAULT '',
            date TEXT,
            created_at TEXT,
            id_shift INTEGER DEFAULT 0,
            is_synced INTEGER DEFAULT 0,
            remote_id INTEGER
          )
        ''');
      } catch (e) {/* table might already exist */}
    }
    if (oldVersion < 42) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN description TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE transaction_details ADD COLUMN description TEXT');
      } catch (e) {}
    }
    if (oldVersion < 32) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS staff(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firstname TEXT,
          lastname TEXT,
          phonenumber TEXT,
          role TEXT,
          active TEXT,
          password TEXT
        )
      ''');
    }
    if (oldVersion < 33) {
      try {
        await db.execute('ALTER TABLE staff ADD COLUMN email TEXT');
      } catch (e) {
        // column might already exist
      }
    }
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS brands(
          id_brand INTEGER PRIMARY KEY,
          nama_brand TEXT
        )
      ''');
      try {
        await db.execute('ALTER TABLE products ADD COLUMN id_brand INTEGER');
      } catch (e) {
        // column might already exist
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN merk TEXT');
      } catch (e) {
        // column might already exist
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN brand_name TEXT');
        await db
            .execute('ALTER TABLE categories ADD COLUMN commodity_code TEXT');
        await db
            .execute('ALTER TABLE brands ADD COLUMN commodity_group_code TEXT');
      } catch (e) {
        // columns might already exist
      }
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE members ADD COLUMN email TEXT');
        await db.execute('ALTER TABLE members ADD COLUMN jenis_kel TEXT');
        await db.execute('ALTER TABLE members ADD COLUMN kategori_cust TEXT');
        await db.execute('ALTER TABLE members ADD COLUMN points TEXT');
      } catch (e) {
        // columns might already exist
      }
    }

    if (oldVersion < 6) {
      // Add indexes for performance optimization
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_category ON products(id_kategori)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_brand ON products(id_brand)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_name ON products(nama_produk)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(nama_kategori)');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          method TEXT,
          base_url TEXT,
          endpoint TEXT,
          body TEXT,
          is_form_data INTEGER DEFAULT 0,
          status TEXT DEFAULT 'pending',
          retry_count INTEGER DEFAULT 0,
          last_error TEXT,
          created_at TEXT,
          local_id TEXT
        )
      ''');
    }
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE members ADD COLUMN id_pos TEXT');
      } catch (e) {
        // column might already exist
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN id_pos TEXT');
      } catch (e) {
        // column might already exist
      }
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_pos TEXT,
          invoiceid TEXT,
          amount TEXT,
          paymentmode TEXT,
          paymentmethod TEXT,
          date TEXT,
          daterecorded TEXT,
          note TEXT,
          transactionid TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 12) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN note TEXT DEFAULT ""');
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN order_type TEXT DEFAULT ""');
      } catch (e) {/* columns might already exist */}
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN order_note TEXT DEFAULT ""');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN order_type TEXT DEFAULT ""');
      } catch (e) {/* columns might already exist */}
    }
    if (oldVersion < 13) {
      // Add missing local_id column to sync_queue for devices that had the broken v7 migration
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN local_id TEXT');
      } catch (e) {/* column might already exist from v13 fresh install */}
    }
    if (oldVersion < 15) {
      try {
        await db
            .execute('ALTER TABLE transactions ADD COLUMN remote_number TEXT');
        await db.execute('ALTER TABLE transactions ADD COLUMN label TEXT');
      } catch (e) {/* columns might already exist */}
    }
    if (oldVersion < 16) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN remote_item_id INTEGER');
      } catch (e) {/* column might already exist */}
    }
    if (oldVersion < 17) {
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN status INTEGER DEFAULT 1');
      } catch (e) {/* column might already exist */}
    }
    if (oldVersion < 18) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN order_types TEXT');
      } catch (e) {/* column might already exist */}
    }
    if (oldVersion < 19) {
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN queue_number INTEGER DEFAULT 0');
      } catch (e) {/* column might already exist */}
    }
    if (oldVersion < 20) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_options(
          option_name TEXT PRIMARY KEY,
          option_value TEXT
        )
      ''');
    }
    if (oldVersion < 21) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_session(
          id INTEGER PRIMARY KEY DEFAULT 1,
          staff TEXT,
          email TEXT,
          location TEXT,
          base_url TEXT,
          auth_token TEXT,
          device_id TEXT
        )
      ''');
    }
    if (oldVersion < 22) {
      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN discount_total INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE products ADD COLUMN discount_type TEXT DEFAULT "percent"');
      } catch (e) {/* columns might already exist */}
    }
    if (oldVersion < 23) {
      try {
        await db.execute(
            'ALTER TABLE products ADD COLUMN status TEXT DEFAULT "active"');
      } catch (e) {/* columns might already exist */}
    }
    if (oldVersion < 24) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN orderTypesJson TEXT DEFAULT ""');
      } catch (e) {/* columns might already exist */}
    }
    if (oldVersion < 25) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN discountTotal INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN discountType TEXT DEFAULT "percent"');
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN hargaAwal INTEGER DEFAULT 0');
      } catch (e) {/* columns might already exist */}
    }

    if (oldVersion < 26) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_modes(
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          active TEXT,
          selected_by_default TEXT
        )
      ''');
    }

    if (oldVersion < 27) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shift_sessions(
          id_shift INTEGER PRIMARY KEY AUTOINCREMENT,
          shift_name TEXT,
          user_id TEXT,
          start_time TEXT,
          end_time TEXT,
          starting_balance INTEGER DEFAULT 0,
          closing_balance INTEGER DEFAULT 0,
          total_cash_expected INTEGER DEFAULT 0,
          total_cash_actual INTEGER DEFAULT 0,
          total_non_cash INTEGER DEFAULT 0,
          status INTEGER DEFAULT 0,
          note TEXT
        )
      ''');
    }

    if (oldVersion < 28) {
      // Safety check for version 28 to ensure all tables exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_modes(
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          active TEXT,
          selected_by_default TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shift_sessions(
          id_shift INTEGER PRIMARY KEY AUTOINCREMENT,
          shift_name TEXT,
          user_id TEXT,
          start_time TEXT,
          end_time TEXT,
          starting_balance INTEGER DEFAULT 0,
          closing_balance INTEGER DEFAULT 0,
          total_cash_expected INTEGER DEFAULT 0,
          total_cash_actual INTEGER DEFAULT 0,
          total_non_cash INTEGER DEFAULT 0,
          status INTEGER DEFAULT 0,
          note TEXT
        )
      ''');
    }

    if (oldVersion < 29) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN kitchen_status INTEGER DEFAULT 0');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 30) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN product_name TEXT DEFAULT ""');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 31) {
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN id_shift INTEGER DEFAULT 0');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 34) {
      try {
        await db.execute(
            'ALTER TABLE shift_sessions ADD COLUMN reconciliation_data TEXT');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 35) {
      try {
        await db.execute('ALTER TABLE staff ADD COLUMN pin TEXT');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 36) {
      try {
        await db.execute(
            'ALTER TABLE shift_sessions ADD COLUMN is_synced INTEGER DEFAULT 0');
        await db
            .execute('ALTER TABLE shift_sessions ADD COLUMN id_remote INTEGER');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 37) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_credit_notes(
          id_credit_note INTEGER PRIMARY KEY,
          clientid TEXT,
          formatted_number TEXT,
          datecreated TEXT,
          date TEXT,
          subtotal INTEGER,
          total INTEGER,
          status TEXT,
          reference_no TEXT
        )
      ''');
    }

    if (oldVersion < 38) {
      try {
        await db.execute(
            'ALTER TABLE transaction_details ADD COLUMN is_refund INTEGER DEFAULT 0');
      } catch (e) {
        /* column might already exist */
      }
    }

    if (oldVersion < 39) {
      // Add payment_method & tgl_bayar to transactions.
      // This lets shift reconciliation query payment data directly from
      // transactions without relying on pos_payments.daterecorded format.
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN payment_method TEXT DEFAULT ""');
      } catch (e) {/* column might already exist */}
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN tgl_bayar TEXT DEFAULT ""');
      } catch (e) {/* column might already exist */}
    }

    if (oldVersion < 40) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN parent TEXT');
      } catch (e) {/* column might already exist */}
      try {
        await db.execute('ALTER TABLE products ADD COLUMN children TEXT');
      } catch (e) {/* column might already exist */}
    }

    if (oldVersion < 41) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pos_promotions(
          id TEXT PRIMARY KEY,
          name TEXT,
          promo_type TEXT,
          brands TEXT,
          locations TEXT,
          description TEXT,
          terms_conditions TEXT,
          items TEXT,
          order_types TEXT,
          start_date TEXT,
          end_date TEXT,
          is_multiplied TEXT,
          is_stackable TEXT,
          status TEXT,
          created_at TEXT
        )
      ''');
    }
  }

  Future _onCreate(Database db, int version) async {
    // Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id_kategori INTEGER PRIMARY KEY,
        nama_kategori TEXT,
        brand_name TEXT,
        commodity_code TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(nama_kategori)');

    // Brands Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS brands(
        id_brand INTEGER PRIMARY KEY,
        nama_brand TEXT,
        commodity_group_code TEXT
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id_produk INTEGER PRIMARY KEY,
        id_kategori INTEGER,
        id_brand INTEGER,
        nama_produk TEXT,
        kode_produk TEXT,
        harga_beli INTEGER,
        harga_jual INTEGER,
        stok INTEGER,
        img TEXT,
        merk TEXT,
        description TEXT,
        order_types TEXT,
        discount_total INTEGER DEFAULT 0,
        discount_type TEXT DEFAULT "percent",
        status TEXT DEFAULT "active",
        parent TEXT,
        children TEXT,
        is_synced INTEGER DEFAULT 1,
        FOREIGN KEY (id_kategori) REFERENCES categories (id_kategori),
        FOREIGN KEY (id_brand) REFERENCES brands (id_brand)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category ON products(id_kategori)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_brand ON products(id_brand)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(nama_produk)');

    // Members Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members(
        id_member INTEGER PRIMARY KEY,
        nama TEXT,
        telepon TEXT,
        alamat TEXT,
        email TEXT,
        jenis_kel TEXT,
        kategori_cust TEXT,
        points TEXT,
        id_pos TEXT,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id_penjualan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penjualan_remote INTEGER,
        id_user INTEGER,
        id_member INTEGER,
        total_item INTEGER,
        total_harga INTEGER,
        diskon INTEGER,
        bayar INTEGER,
        diterima INTEGER,
        tgl_penjualan TEXT,
        id_pos TEXT,
        order_note TEXT DEFAULT "",
        order_type TEXT DEFAULT "",
        discount_type TEXT DEFAULT "percent",
        manual_discount_value INTEGER DEFAULT 0,
        remote_number TEXT,
        label TEXT,
        status INTEGER DEFAULT 1,
        id_shift INTEGER DEFAULT 0,
        queue_number INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        payment_method TEXT DEFAULT "",
        tgl_bayar TEXT DEFAULT ""
      )
    ''');

    // Transaction Details Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_details(
        id_penjualan_detail INTEGER PRIMARY KEY AUTOINCREMENT,
        id_penjualan INTEGER,
        id_produk INTEGER,
        harga_jual INTEGER,
        jumlah INTEGER,
        subtotal INTEGER,
        note TEXT DEFAULT "",
        order_type TEXT DEFAULT "",
        orderTypesJson TEXT DEFAULT "",
        remote_item_id INTEGER,
        discountTotal INTEGER DEFAULT 0,
        discountType TEXT DEFAULT "percent",
        hargaAwal INTEGER DEFAULT 0,
        kitchen_status INTEGER DEFAULT 0,
        product_name TEXT DEFAULT "",
        description TEXT,
        is_refund INTEGER DEFAULT 0,
        FOREIGN KEY (id_penjualan) REFERENCES transactions (id_penjualan)
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method TEXT,
        base_url TEXT,
        endpoint TEXT,
        body TEXT,
        is_form_data INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT,
        local_id TEXT
      )
    ''');

    // POS Payments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pos TEXT,
        invoiceid TEXT,
        amount TEXT,
        paymentmode TEXT,
        paymentmethod TEXT,
        date TEXT,
        daterecorded TEXT,
        note TEXT,
        transactionid TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // POS Options Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_options(
        option_name TEXT PRIMARY KEY,
        option_value TEXT
      )
    ''');

    // User Session Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_session(
        id INTEGER PRIMARY KEY DEFAULT 1,
        staff TEXT,
        email TEXT,
        location TEXT,
        base_url TEXT,
        auth_token TEXT,
        device_id TEXT
      )
    ''');

    // Payment Modes Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_modes(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        active TEXT,
        selected_by_default TEXT
      )
    ''');

    // Shift Sessions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shift_sessions(
        id_shift INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_name TEXT,
        user_id TEXT,
        start_time TEXT,
        end_time TEXT,
        starting_balance INTEGER DEFAULT 0,
        closing_balance INTEGER DEFAULT 0,
        total_cash_expected INTEGER DEFAULT 0,
        total_cash_actual INTEGER DEFAULT 0,
        total_non_cash INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        note TEXT,
        reconciliation_data TEXT,
        is_synced INTEGER DEFAULT 0,
        id_remote INTEGER
      )
    ''');

    // Staff Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstname TEXT,
        lastname TEXT,
        email TEXT,
        phonenumber TEXT,
        role TEXT,
        active TEXT,
        password TEXT,
        pin TEXT
      )
    ''');

    // Credit Notes Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_credit_notes(
        id_credit_note INTEGER PRIMARY KEY,
        clientid TEXT,
        formatted_number TEXT,
        datecreated TEXT,
        date TEXT,
        subtotal INTEGER,
        total INTEGER,
        status TEXT,
        reference_no TEXT
      )
    ''');

    // POS Promotions Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pos_promotions(
        id TEXT PRIMARY KEY,
        name TEXT,
        promo_type TEXT,
        brands TEXT,
        locations TEXT,
        description TEXT,
        terms_conditions TEXT,
        items TEXT,
        order_types TEXT,
        start_date TEXT,
        end_date TEXT,
        is_multiplied TEXT,
        is_stackable TEXT,
        status TEXT,
        created_at TEXT
      )
    ''');

    // Cash Flow Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_flow(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_name TEXT DEFAULT '',
        note TEXT DEFAULT '',
        amount INTEGER NOT NULL DEFAULT 0,
        direction TEXT DEFAULT 'out',
        staff_name TEXT DEFAULT '',
        staff_email TEXT DEFAULT '',
        date TEXT,
        created_at TEXT,
        id_shift INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        remote_id INTEGER
      )
    ''');
  }

  // --- CRUD Helper Methods ---

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      return await db.insert(table, data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (e.toString().contains('database_closed')) {
        debugPrint('DatabaseService: database_closed on insert, retrying...');
        _database = null;
        final db2 = await database;
        return await db2.insert(table, data,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where,
      List<dynamic>? whereArgs,
      List<String>? columns,
      bool? distinct,
      int? limit,
      String? orderBy}) async {
    debugPrint('DatabaseService: query called for table: $table');
    // Use synchronous check to skip await if possible
    final Database db;
    if (_database != null) {
      db = _database!;
    } else {
      debugPrint('DatabaseService: database not ready, awaiting...');
      db = await database;
    }

    debugPrint('DatabaseService: entry into sqflite query for $table...');
    try {
      final results = await db.query(table,
          where: where,
          whereArgs: whereArgs,
          columns: columns,
          distinct: distinct,
          limit: limit,
          orderBy: orderBy);
      debugPrint(
          'DatabaseService: query on $table SUCCESS, returned ${results.length} rows');
      return results;
    } catch (e) {
      if (e.toString().contains('database_closed')) {
        debugPrint(
            'DatabaseService: database_closed on query $table, retrying...');
        _database = null;
        final db2 = await database;
        return await db2.query(table,
            where: where,
            whereArgs: whereArgs,
            columns: columns,
            distinct: distinct,
            limit: limit,
            orderBy: orderBy);
      }
      debugPrint('DatabaseService: query on $table ERROR: $e');
      if (e.toString().contains('no such table: $table') && table == 'staff') {
        // Emergency recovery: create table if missing during query
        await db.execute('''
          CREATE TABLE IF NOT EXISTS staff(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firstname TEXT,
            lastname TEXT,
            email TEXT,
            phonenumber TEXT,
            role TEXT,
            active TEXT,
            password TEXT,
            pin TEXT
          )
        ''');
        return [];
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    try {
      final db = await database;
      return await db.rawQuery(sql, arguments);
    } catch (e) {
      if (e.toString().contains('database_closed')) {
        _database = null;
        final db2 = await database;
        return await db2.rawQuery(sql, arguments);
      }
      rethrow;
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<dynamic> whereArgs) async {
    try {
      final db = await database;
      return await db.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      if (e.toString().contains('database_closed')) {
        _database = null;
        final db2 = await database;
        return await db2.update(table, data,
            where: where, whereArgs: whereArgs);
      }
      rethrow;
    }
  }

  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    try {
      final db = await database;
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      if (e.toString().contains('database_closed')) {
        _database = null;
        final db2 = await database;
        return await db2.delete(table, where: where, whereArgs: whereArgs);
      }
      rethrow;
    }
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  Future<void> deleteDatabaseFile() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    String path = join(await getDatabasesPath(), 'pos_database.db');
    await deleteDatabase(path);
    debugPrint('DatabaseService: Deleted database file completely.');
  }

  // --- Cash Flow CRUD ---

  Future<int> insertCashFlow(Map<String, dynamic> data) async {
    return await insert('cash_flow', data);
  }

  Future<List<Map<String, dynamic>>> getCashFlowByDateRange(
      String startDate, String endDate) async {
    return await rawQuery(
      'SELECT * FROM cash_flow WHERE date >= ? AND date <= ? ORDER BY created_at DESC',
      [startDate, endDate],
    );
  }

  Future<List<Map<String, dynamic>>> getCashFlowByShift(int shiftId) async {
    return await query(
      'cash_flow',
      where: 'id_shift = ?',
      whereArgs: [shiftId],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCashFlowSince(String startTime) async {
    return await rawQuery(
      'SELECT * FROM cash_flow WHERE created_at >= ? ORDER BY created_at ASC',
      [startTime],
    );
  }

  Future<void> markCashFlowSynced(int id, int remoteId) async {
    await update(
      'cash_flow',
      {'is_synced': 1, 'remote_id': remoteId},
      'id = ?',
      [id],
    );
  }
}

