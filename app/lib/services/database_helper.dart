import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'joint_saathi.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone_number TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        health_center_id TEXT,
        location TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Patients table
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        contact TEXT,
        village TEXT,
        address TEXT,
        occupation TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        synced INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0
      )
    ''');

    // Screenings table
    await db.execute('''
      CREATE TABLE screenings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        patient_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        screening_date TEXT DEFAULT CURRENT_TIMESTAMP,
        pain_level INTEGER,
        stiffness_duration TEXT,
        swelling INTEGER,
        past_injury TEXT,
        gait_data TEXT,
        risk_level TEXT,
        confidence REAL,
        contributing_factors TEXT,
        ai_reasoning TEXT,
        doctor_recommendations TEXT,
        synced INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Preventive care articles table
    await db.execute('''
      CREATE TABLE preventive_care (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Insert default preventive care articles
    await _insertDefaultPreventiveCare(db);
  }

  Future<void> _insertDefaultPreventiveCare(Database db) async {
    final articles = [
      {
        'category': 'exercises',
        'title': 'Knee Strengthening Exercises',
        'content': 'Simple exercises to strengthen knee muscles and reduce OA risk. Include quad sets, straight leg raises, and hamstring stretches.',
        'image_url': 'assets/images/exercise1.png'
      },
      {
        'category': 'exercises',
        'title': 'Low Impact Aerobics',
        'content': 'Walking, swimming, and cycling are excellent low-impact activities that maintain joint health without excessive stress.',
        'image_url': 'assets/images/exercise2.png'
      },
      {
        'category': 'diet',
        'title': 'Anti-Inflammatory Foods',
        'content': 'Include foods rich in omega-3 fatty acids like fish, walnuts, and flaxseeds. Add turmeric, ginger, and colorful vegetables to your diet.',
        'image_url': 'assets/images/diet1.png'
      },
      {
        'category': 'diet',
        'title': 'Calcium and Vitamin D',
        'content': 'Ensure adequate calcium and vitamin D intake through dairy products, leafy greens, and fortified foods for bone health.',
        'image_url': 'assets/images/diet2.png'
      },
      {
        'category': 'lifestyle',
        'title': 'Weight Management',
        'content': 'Maintaining a healthy weight reduces stress on weight-bearing joints and slows OA progression.',
        'image_url': 'assets/images/lifestyle1.png'
      },
      {
        'category': 'lifestyle',
        'title': 'Posture and Ergonomics',
        'content': 'Practice good posture and use ergonomic furniture to reduce joint strain during daily activities.',
        'image_url': 'assets/images/lifestyle2.png'
      }
    ];

    for (var article in articles) {
      await db.insert('preventive_care', article);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades when schema changes
    if (oldVersion < 2) {
      // Add server_id column to patients table if it doesn't exist
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN server_id TEXT');
      } catch (e) {
        // Column might already exist, ignore error
      }
      // Add server_id column to screenings table if it doesn't exist
      try {
        await db.execute('ALTER TABLE screenings ADD COLUMN server_id TEXT');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
    
    if (oldVersion < 3) {
      // Add deleted column to patients table if it doesn't exist
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN deleted INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }
      // Add deleted column to screenings table if it doesn't exist
      try {
        await db.execute('ALTER TABLE screenings ADD COLUMN deleted INTEGER DEFAULT 0');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }

    if (oldVersion < 4) {
      // Add created_at and updated_at columns to screenings table if they don't exist
      try {
        await db.execute('ALTER TABLE screenings ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (e) {
        // Column might already exist, ignore error
      }
      try {
        await db.execute('ALTER TABLE screenings ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }

    if (oldVersion < 5) {
      // Add updated_at column to sync_queue table if it doesn't exist
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN updated_at TEXT DEFAULT CURRENT_TIMESTAMP');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }

    if (oldVersion < 6) {
      // Recreate sync_queue with the full schema to ensure all columns exist.
      // Backup existing data first, then drop and recreate.
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_queue_backup AS SELECT * FROM sync_queue
        ''');
      } catch (e) {
        // ignore if backup fails
      }
      try {
        await db.execute('DROP TABLE IF EXISTS sync_queue');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT NOT NULL,
            record_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
            retry_count INTEGER DEFAULT 0
          )
        ''');
        // Restore backed-up rows (only columns that exist in old schema)
        await db.execute('''
          INSERT OR IGNORE INTO sync_queue (id, table_name, record_id, action, data, created_at, retry_count)
          SELECT id, table_name, record_id, action, data, created_at, retry_count
          FROM sync_queue_backup
        ''');
      } catch (e) {
        // ignore errors during recreation
      }
      try {
        await db.execute('DROP TABLE IF EXISTS sync_queue_backup');
      } catch (e) {
        // ignore
      }
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    // Only add timestamps if not already present
    if (!data.containsKey('created_at')) {
      data['created_at'] = DateTime.now().toIso8601String();
    }
    if (!data.containsKey('updated_at')) {
      data['updated_at'] = DateTime.now().toIso8601String();
    }
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Specific operations for sync status
  Future<int> getUnsyncedCount(String table) async {
    final results = await query(
      table,
      where: 'synced = ?',
      whereArgs: [0],
    );
    return results.length;
  }

  Future<void> markAsSynced(String table, int id) async {
    await update(
      table,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync queue operations
  Future<int> addToSyncQueue(String tableName, int recordId, String action, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeFromSyncQueue(int id) async {
    await delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('users');
    await db.delete('patients');
    await db.delete('screenings');
    await db.delete('sync_queue');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADVANCED PATIENT QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    final db = await database;
    return await db.query(
      'patients',
      where: 'name LIKE ? OR village LIKE ? OR contact LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> filterPatients(Map<String, dynamic> filters) async {
    final db = await database;
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (filters.containsKey('gender')) {
      whereConditions.add('gender = ?');
      whereArgs.add(filters['gender']);
    }

    if (filters.containsKey('minAge')) {
      whereConditions.add('age >= ?');
      whereArgs.add(filters['minAge']);
    }

    if (filters.containsKey('maxAge')) {
      whereConditions.add('age <= ?');
      whereArgs.add(filters['maxAge']);
    }

    if (filters.containsKey('village')) {
      whereConditions.add('village = ?');
      whereArgs.add(filters['village']);
    }

    final whereClause = whereConditions.isNotEmpty 
        ? whereConditions.join(' AND ') 
        : null;

    return await db.query(
      'patients',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPatientsByVillage(String village) async {
    final db = await database;
    return await db.query(
      'patients',
      where: 'village = ?',
      whereArgs: [village],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getPatientsByAgeRange(int min, int max) async {
    final db = await database;
    return await db.query(
      'patients',
      where: 'age >= ? AND age <= ?',
      whereArgs: [min, max],
      orderBy: 'age ASC',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADVANCED SCREENING QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getScreeningsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'screenings',
      where: 'screening_date >= ? AND screening_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'screening_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getHighRiskPatients() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT DISTINCT p.* 
      FROM patients p
      INNER JOIN screenings s ON p.id = s.patient_id
      WHERE s.risk_level = 'high'
      ORDER BY p.name ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPatientsNeedingFollowUp() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return await db.rawQuery('''
      SELECT DISTINCT p.*, MAX(s.screening_date) as last_screening
      FROM patients p
      INNER JOIN screenings s ON p.id = s.patient_id
      WHERE s.risk_level IN ('medium', 'high')
      GROUP BY p.id
      HAVING last_screening < ?
      ORDER BY last_screening ASC
    ''', [thirtyDaysAgo.toIso8601String()]);
  }

  Future<Map<String, dynamic>> getPatientRiskTrend(int patientId) async {
    final db = await database;
    final screenings = await db.query(
      'screenings',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'screening_date ASC',
    );

    return {
      'patientId': patientId,
      'totalScreenings': screenings.length,
      'screenings': screenings,
      'trend': _calculateRiskTrend(screenings),
    };
  }

  Map<String, dynamic> _calculateRiskTrend(List<Map<String, dynamic>> screenings) {
    if (screenings.isEmpty) {
      return {'trend': 'no_data', 'improving': false};
    }

    final riskLevels = screenings.map((s) => s['risk_level'] as String?).toList();
    final riskScores = riskLevels.map((level) {
      switch (level?.toLowerCase()) {
        case 'low': return 1;
        case 'medium': return 2;
        case 'high': return 3;
        default: return 0;
      }
    }).toList();

    if (riskScores.length < 2) {
      return {'trend': 'insufficient_data', 'improving': false};
    }

    final firstHalf = riskScores.sublist(0, (riskScores.length / 2).ceil());
    final secondHalf = riskScores.sublist((riskScores.length / 2).floor());

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final improving = secondAvg < firstAvg;
    final trend = improving ? 'improving' : (secondAvg > firstAvg ? 'worsening' : 'stable');

    return {
      'trend': trend,
      'improving': improving,
      'firstAverage': firstAvg,
      'secondAverage': secondAvg,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PREVENTIVE CARE QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPreventiveCareArticles() async {
    final db = await database;
    return await db.query('preventive_care', orderBy: 'category ASC');
  }

  Future<List<Map<String, dynamic>>> getArticlesByCategory(String category) async {
    final db = await database;
    return await db.query(
      'preventive_care',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> saveArticleProgress(String articleId, Map<String, dynamic> progress) async {
    final db = await database;
    // Check if article_progress table exists, if not create it
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS article_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          article_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          progress INTEGER DEFAULT 0,
          completed INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(article_id, user_id)
        )
      ''');
    } catch (e) {
      // Table might already exist
    }

    await db.insert(
      'article_progress',
      {
        'article_id': articleId,
        'user_id': progress['user_id'] ?? 1,
        'progress': progress['progress'] ?? 0,
        'completed': progress['completed'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // USER SETTINGS QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserSettings(int userId) async {
    final db = await database;
    // Check if user_settings table exists
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          settings TEXT NOT NULL,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id)
        )
      ''');
    } catch (e) {
      // Table might already exist
    }

    final settings = await db.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (settings.isNotEmpty) {
      return {'settings': settings.first['settings'], 'updated_at': settings.first['updated_at']};
    }

    return {};
  }

  Future<void> updateUserSettings(int userId, Map<String, dynamic> settings) async {
    final db = await database;
    final settingsJson = settings.toString();

    await db.insert(
      'user_settings',
      {
        'user_id': userId,
        'settings': settingsJson,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC MANAGEMENT QUERIES
  // ─────────────────────────────────────────────────────────────────────────

  Future<DateTime> getLastSyncTime() async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          last_sync_time TEXT NOT NULL,
          sync_status TEXT DEFAULT 'idle'
        )
      ''');
    } catch (e) {
      // Table might already exist
    }

    final metadata = await db.query('sync_metadata', limit: 1);
    if (metadata.isNotEmpty && metadata.first['last_sync_time'] != null) {
      return DateTime.parse(metadata.first['last_sync_time'] as String);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> updateLastSyncTime(DateTime time) async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_metadata (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          last_sync_time TEXT NOT NULL,
          sync_status TEXT DEFAULT 'idle'
        )
      ''');
    } catch (e) {
      // Table might already exist
    }

    await db.insert(
      'sync_metadata',
      {
        'last_sync_time': time.toIso8601String(),
        'sync_status': 'completed',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'retry_count < 3',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSyncItemComplete(int syncId) async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AUDIT LOGGING
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logAuditEvent(Map<String, dynamic> event) async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          action TEXT NOT NULL,
          table_name TEXT NOT NULL,
          record_id INTEGER,
          old_values TEXT,
          new_values TEXT,
          ip_address TEXT,
          user_agent TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    } catch (e) {
      // Table might already exist
    }

    await db.insert('audit_logs', {
      'user_id': event['user_id'],
      'action': event['action'],
      'table_name': event['table_name'],
      'record_id': event['record_id'],
      'old_values': event['old_values']?.toString(),
      'new_values': event['new_values']?.toString(),
      'ip_address': event['ip_address'],
      'user_agent': event['user_agent'],
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs(Map<String, dynamic> filters) async {
    final db = await database;
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (filters.containsKey('userId')) {
      whereConditions.add('user_id = ?');
      whereArgs.add(filters['userId']);
    }

    if (filters.containsKey('action')) {
      whereConditions.add('action = ?');
      whereArgs.add(filters['action']);
    }

    if (filters.containsKey('tableName')) {
      whereConditions.add('table_name = ?');
      whereArgs.add(filters['tableName']);
    }

    if (filters.containsKey('startDate')) {
      whereConditions.add('created_at >= ?');
      whereArgs.add(filters['startDate']);
    }

    if (filters.containsKey('endDate')) {
      whereConditions.add('created_at <= ?');
      whereArgs.add(filters['endDate']);
    }

    final whereClause = whereConditions.isNotEmpty 
        ? whereConditions.join(' AND ') 
        : null;

    return await db.query(
      'audit_logs',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
      limit: filters['limit'] ?? 100,
    );
  }
}
