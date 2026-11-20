import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbHelper {
  LocalDbHelper._internal();
  static final LocalDbHelper instance = LocalDbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'odoo17_mobile_manager.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Assigned Geographic Zones for logged-in user
    await db.execute('''
      CREATE TABLE user_zones (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL
      )
    ''');

    // 2. Zone-Filtered Customers
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        street TEXT,
        city TEXT,
        zone_id INTEGER,
        zone_name TEXT,
        write_date TEXT
      )
    ''');

    // 3. Vendors (Suppliers for Purchase module)
    await db.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        write_date TEXT
      )
    ''');

    // 4. Products (with barcode index & base64 thumbnail)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        default_code TEXT,
        barcode TEXT,
        lst_price REAL DEFAULT 0.0,
        qty_available REAL DEFAULT 0.0,
        uom_name TEXT,
        image_base64 TEXT,
        write_date TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    // 5. Sales Taxes
    await db.execute('''
      CREATE TABLE taxes (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL DEFAULT 0.0
      )
    ''');

    // 6. Unified Offline Queue (supports 'sale_order', 'purchase_order', 'picking_validate')
    await db.execute('''
      CREATE TABLE offline_queue (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        partner_id INTEGER,
        partner_name TEXT,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== USER ZONES ====================

  Future<void> saveUserZones(List<Map<String, dynamic>> zones) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_zones');
      for (final z in zones) {
        await txn.insert('user_zones', {
          'id': z['id'],
          'name': z['name'] ?? '',
          'code': z['code'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getUserZones() async {
    final db = await database;
    return await db.query('user_zones', orderBy: 'name ASC');
  }

  // ==================== DELTA SYNC UPSERTS ====================

  Future<void> upsertMasterData({
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> vendors,
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> taxes,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final c in customers) {
        final zoneRaw = c['mobile_zone_id'];
        int? zoneId;
        String? zoneName;
        if (zoneRaw is List && zoneRaw.length >= 2) {
          zoneId = zoneRaw[0] as int?;
          zoneName = zoneRaw[1]?.toString();
        }
        await txn.insert('customers', {
          'id': c['id'],
          'name': _safeStr(c['name']),
          'email': _safeStr(c['email']),
          'phone': _safeStr(c['phone']),
          'street': _safeStr(c['street']),
          'city': _safeStr(c['city']),
          'zone_id': zoneId,
          'zone_name': zoneName ?? '',
          'write_date': _safeStr(c['write_date']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final v in vendors) {
        await txn.insert('vendors', {
          'id': v['id'],
          'name': _safeStr(v['name']),
          'email': _safeStr(v['email']),
          'phone': _safeStr(v['phone']),
          'write_date': _safeStr(v['write_date']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final p in products) {
        await txn.insert('products', {
          'id': p['id'],
          'name': _safeStr(p['name']),
          'default_code': _safeStr(p['default_code']),
          'barcode': _safeStr(p['barcode']),
          'lst_price': (p['lst_price'] as num?)?.toDouble() ?? 0.0,
          'qty_available': (p['qty_available'] as num?)?.toDouble() ?? 0.0,
          'uom_name': _safeStr(p['uom_name']),
          'image_base64': p['image'],
          'write_date': _safeStr(p['write_date']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      if (taxes.isNotEmpty) {
        await txn.delete('taxes');
        for (final t in taxes) {
          await txn.insert('taxes', {
            'id': t['id'],
            'name': _safeStr(t['name']),
            'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  // ==================== LOCAL QUERIES ====================

  Future<List<Map<String, dynamic>>> getCustomers({int? zoneId}) async {
    final db = await database;
    if (zoneId != null) {
      return await db.query(
        'customers',
        where: 'zone_id = ?',
        whereArgs: [zoneId],
        orderBy: 'name ASC',
      );
    }
    return await db.query('customers', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getVendors() async {
    final db = await database;
    return await db.query('vendors', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> findProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'barcode = ? OR default_code = ?',
      whereArgs: [barcode.trim(), barcode.trim()],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // ==================== OFFLINE QUEUE ====================

  Future<void> enqueueOfflineAction({
    required String id,
    required String actionType, // 'sale_order' | 'purchase_order' | 'picking_validate'
    int? partnerId,
    String? partnerName,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('offline_queue', {
      'id': id,
      'action_type': actionType,
      'partner_id': partnerId,
      'partner_name': partnerName ?? '',
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingQueue({String? actionType}) async {
    final db = await database;
    final rows = actionType != null
        ? await db.query(
            'offline_queue',
            where: 'action_type = ?',
            whereArgs: [actionType],
            orderBy: 'created_at ASC',
          )
        : await db.query('offline_queue', orderBy: 'created_at ASC');

    return rows.map((row) {
      final decoded = jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
      return {
        'id': row['id'],
        'action_type': row['action_type'],
        'partner_id': row['partner_id'],
        'partner_name': row['partner_name'],
        'created_at': row['created_at'],
        ...decoded,
      };
    }).toList();
  }

  Future<void> deleteQueueItem(String id) async {
    final db = await database;
    await db.delete('offline_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllOnLogout() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('user_zones');
      await txn.delete('customers');
      await txn.delete('vendors');
      await txn.delete('products');
      await txn.delete('taxes');
      await txn.delete('offline_queue');
    });
  }

  String _safeStr(dynamic val) {
    if (val == null || val is bool) return '';
    return val.toString();
  }
}
