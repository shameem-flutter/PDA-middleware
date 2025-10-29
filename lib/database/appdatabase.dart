import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pda/models/count_session.dart';
import 'package:sqflite/sqflite.dart';
import '../models/products.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Stream control
  final Map<int, bool> _pausedStreams = {};

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory.db');

    return await openDatabase(
      path,
      version: 8, // ✅ Increment version to 8
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT,
        barcode TEXT,
        erpQuantity INTEGER DEFAULT 0,
        imageUrl TEXT,
        category_name TEXT,
        category_id INTEGER DEFAULT 0,
        sale_price REAL DEFAULT 0,
        cost REAL DEFAULT 0,
        uom_name TEXT,
        reference TEXT,
        product_id TEXT,  -- ✅ Changed to TEXT
        company_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE counting_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        countedQuantity INTEGER DEFAULT 0,
        productName TEXT,
        sku TEXT,
        company_name TEXT,
        erpQuantity INTEGER DEFAULT 0,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_barcode ON products(barcode)');
    await db.execute(
      'CREATE INDEX idx_productId ON counting_sessions(productId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE counting_sessions ADD COLUMN productName TEXT;',
      );
      await db.execute('ALTER TABLE counting_sessions ADD COLUMN sku TEXT;');
      await db.execute(
        'ALTER TABLE counting_sessions ADD COLUMN erpQuantity INTEGER DEFAULT 0;',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE counting_sessions ADD COLUMN erpProductId INTEGER DEFAULT 0;',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        "UPDATE products SET sku = 'SKU_' || product_id WHERE sku = ''",
      );
    }
    if (oldVersion < 6) {
      final cols = await db.rawQuery('PRAGMA table_info(products)');
      final hasCompany = cols.any((c) => c['name'] == 'company_name');
      if (!hasCompany) {
        await db.execute('ALTER TABLE products ADD COLUMN company_name TEXT;');
      }

      final csCols = await db.rawQuery('PRAGMA table_info(counting_sessions)');
      final hasCsCompany = csCols.any((c) => c['name'] == 'company_name');
      if (!hasCsCompany) {
        await db.execute(
          'ALTER TABLE counting_sessions ADD COLUMN company_name TEXT;',
        );
      }
    }

    // Version 7: Remove CASCADE constraint
    if (oldVersion < 7) {
      debugPrint("🔄 Upgrading to version 7: Removing CASCADE constraint");

      await db.execute('''
        CREATE TABLE counting_sessions_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          countedQuantity INTEGER DEFAULT 0,
          productName TEXT,
          sku TEXT,
          company_name TEXT,
          erpQuantity INTEGER DEFAULT 0,
          timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
          status TEXT DEFAULT 'pending',
          FOREIGN KEY(productId) REFERENCES products(id)
        )
      ''');

      await db.execute('''
        INSERT INTO counting_sessions_new 
        SELECT id, productId, countedQuantity, productName, sku, 
               company_name, erpQuantity, timestamp, status
        FROM counting_sessions
      ''');

      await db.execute('DROP TABLE counting_sessions');

      await db.execute(
        'ALTER TABLE counting_sessions_new RENAME TO counting_sessions',
      );

      await db.execute(
        'CREATE INDEX idx_productId ON counting_sessions(productId)',
      );

      debugPrint("✅ Successfully removed CASCADE constraint");
    }

    // ✅ Version 8: Fix product_id column type
    if (oldVersion < 8) {
      debugPrint("🔄 Upgrading to version 8: Changing product_id to TEXT");

      // Create new products table with correct schema
      await db.execute('''
        CREATE TABLE products_new(
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          sku TEXT,
          barcode TEXT,
          erpQuantity INTEGER DEFAULT 0,
          imageUrl TEXT,
          category_name TEXT,
          category_id INTEGER DEFAULT 0,
          sale_price REAL DEFAULT 0,
          cost REAL DEFAULT 0,
          uom_name TEXT,
          reference TEXT,
          product_id TEXT,
          company_name TEXT
        )
      ''');

      // Copy data (product_id will be converted to TEXT automatically)
      await db.execute('''
        INSERT INTO products_new 
        SELECT id, name, sku, barcode, erpQuantity, imageUrl, 
               category_name, category_id, sale_price, cost, 
               uom_name, reference, product_id, company_name
        FROM products
      ''');

      // Drop old table
      await db.execute('DROP TABLE products');

      // Rename new table
      await db.execute('ALTER TABLE products_new RENAME TO products');

      // Recreate index
      await db.execute('CREATE INDEX idx_barcode ON products(barcode)');

      debugPrint("✅ Successfully changed product_id to TEXT");
    }
  }

  // ... rest of your methods remain the same

  // ---------------- Products ----------------
  Future<List<Product>> getProducts() async {
    final db = await database;
    final res = await db.query('products', orderBy: 'name');
    return res.map((row) => Product.fromMap(row)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final res = await db.query('products', where: 'id=?', whereArgs: [id]);
    return res.isNotEmpty ? Product.fromMap(res.first) : null;
  }

  Future<Product?> getProductByBarcode(String rawCode) async {
    final db = await database;
    String code = rawCode
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');

    final res = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (res.isNotEmpty) return Product.fromMap(res.first);

    final skuRes = await db.query(
      'products',
      where: 'sku = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (skuRes.isNotEmpty) return Product.fromMap(skuRes.first);

    final partialRes = await db.query(
      'products',
      where: 'barcode LIKE ? OR sku LIKE ?',
      whereArgs: ['%$code%', '%$code%'],
      limit: 1,
    );
    if (partialRes.isNotEmpty) return Product.fromMap(partialRes.first);

    return null;
  }

  Future<void> insertOrUpdateProduct(Product product) async {
    final db = await database;
    final map = product.toMap();
    if (map['sku'] == null || map['sku'].trim().isEmpty) {
      map['sku'] = 'SKU_${product.productId}';
    }

    final count = await db.update(
      'products',
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    if (count == 0) {
      await db.insert('products', map);
    }
  }

  Future<void> syncProducts(List<Product> products) async {
    final db = await database;
    const int chunkSize = 200;
    for (var i = 0; i < products.length; i += chunkSize) {
      final batch = db.batch();
      final end = (i + chunkSize < products.length)
          ? i + chunkSize
          : products.length;
      final chunk = products.sublist(i, end);
      for (final product in chunk) {
        final map = product.toMap();
        if (map['sku'] == null || map['sku'].toString().trim().isEmpty) {
          map['sku'] = 'SKU_${product.productId}';
        }
        batch.insert(
          'products',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  // ---------------- Counting Sessions ----------------
  Future<List<CountingSession>> getCountingSessions() async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT cs.*, p.name AS productName, p.erpQuantity, p.sku
      FROM counting_sessions cs
      INNER JOIN products p ON cs.productId = p.id
      ORDER BY cs.timestamp DESC
    ''');
    return res.map((row) => CountingSession.fromMap(row)).toList();
  }

  Future<CountingSession?> getCountingSessionByProductId(int productId) async {
    final db = await database;
    final res = await db.rawQuery(
      '''
      SELECT cs.*, p.name AS productName, p.erpQuantity, p.sku
      FROM counting_sessions cs
      INNER JOIN products p ON cs.productId = p.id
      WHERE cs.productId = ?
      LIMIT 1
    ''',
      [productId],
    );
    return res.isNotEmpty ? CountingSession.fromMap(res.first) : null;
  }

  Future<void> insertOrUpdateCountingSession(CountingSession session) async {
    final db = await database;

    // Check if session already exists
    final existing = await db.query(
      'counting_sessions',
      where: 'productId = ?',
      whereArgs: [session.productId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Update existing session
      await db.update(
        'counting_sessions',
        {
          'countedQuantity': session.countedQuantity,
          'productName': session.productName,
          'erpQuantity': session.erpQuantity,
          'status': session.countedQuantity > 0 ? 'completed' : 'pending',
          'timestamp':
              session.timestamp?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        },
        where: 'productId = ?',
        whereArgs: [session.productId],
      );
    } else {
      // Insert new session
      await db.insert('counting_sessions', {
        'productId': session.productId,
        'countedQuantity': session.countedQuantity,
        'productName': session.productName,
        'erpQuantity': session.erpQuantity,
        'status': session.countedQuantity > 0 ? 'completed' : 'pending',
        'timestamp':
            session.timestamp?.toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
    }
  }

  // ✅ Fixed delete method with better error handling
  Future<int> deleteCountingSession(int id) async {
    debugPrint("🗑️ DatabaseHelper: Attempting to delete session id: $id");

    try {
      final db = await database;

      // ✅ Verify session exists before deletion
      final existingSession = await db.query(
        'counting_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (existingSession.isEmpty) {
        debugPrint("⚠️ Session id: $id not found");
        return 0;
      }

      debugPrint("✅ Found session: ${existingSession.first}");

      // Count before deletion
      final countBefore = await db.rawQuery(
        'SELECT COUNT(*) as count FROM counting_sessions',
      );
      debugPrint("📊 Sessions before deletion: ${countBefore[0]['count']}");

      // ✅ Delete ONLY by id (not by productId or anything else)
      final result = await db.delete(
        'counting_sessions',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Count after deletion
      final countAfter = await db.rawQuery(
        'SELECT COUNT(*) as count FROM counting_sessions',
      );
      debugPrint("📊 Sessions after deletion: ${countAfter[0]['count']}");
      debugPrint("✅ Rows deleted: $result");

      return result;
    } catch (e, stackTrace) {
      debugPrint("❌ Error deleting session: $e");
      debugPrint("Stack trace: $stackTrace");
      return 0;
    }
  }

  Future<int> deleteAllCountingSessions() async {
    final db = await database;
    return db.delete('counting_sessions');
  }

  Future<void> clearCountingSessions() async {
    await deleteAllCountingSessions();
  }

  // ---------------- Streams for Riverpod ----------------
  Stream<CountingSession?> watchCountingSessionByProductId(int productId) {
    final controller = StreamController<CountingSession?>.broadcast();
    bool isClosed = false;

    Future<void> queryAndEmit() async {
      if (isClosed || (_pausedStreams[productId] ?? false)) return;
      try {
        final db = await database;
        final res = await db.rawQuery(
          '''
          SELECT cs.*, p.name AS productName, p.erpQuantity, p.sku
          FROM counting_sessions cs
          INNER JOIN products p ON cs.productId = p.id
          WHERE cs.productId = ?
          LIMIT 1
        ''',
          [productId],
        );
        if (!controller.isClosed) {
          controller.add(
            res.isNotEmpty ? CountingSession.fromMap(res.first) : null,
          );
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Initial emit
    database.then((_) => queryAndEmit());

    final timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => queryAndEmit(),
    );

    controller.onCancel = () {
      isClosed = true;
      timer.cancel();
      if (!controller.isClosed) controller.close();
    };

    return controller.stream;
  }

  void pauseStream(int productId) => _pausedStreams[productId] = true;
  void resumeStream(int productId) => _pausedStreams[productId] = false;

  Future<void> insertCountingSession(CountingSession session) async {
    await insertOrUpdateCountingSession(session);
  }

  Future<void> updateCountingSession(int productId, int countedQuantity) async {
    final existing = await getCountingSessionByProductId(productId);
    if (existing != null) {
      final session = CountingSession(
        id: existing.id,
        productId: existing.productId,
        countedQuantity: countedQuantity,
        productName: existing.productName,
        erpQuantity: existing.erpQuantity,
        timestamp: DateTime.now(),
      );
      await insertOrUpdateCountingSession(session);
    }
  }
}
