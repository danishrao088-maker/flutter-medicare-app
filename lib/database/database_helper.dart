import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/medicine.dart';
import '../models/profile.dart';
import '../models/reminder.dart';
import '../models/user.dart';

/// SQLite-backed persistence layer.
///
/// Schema versioning is handled in `_onUpgrade` so the database can be
/// migrated cleanly on app updates instead of silently breaking.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'medicare.db';
  static const _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);
    return openDatabase(
      fullPath,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce FK constraints so cascaded deletes are reliable.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        avatar TEXT NOT NULL DEFAULT '👤',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        age INTEGER NOT NULL,
        avatar TEXT NOT NULL,
        userId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        type TEXT NOT NULL,
        totalStock INTEGER NOT NULL,
        currentStock INTEGER NOT NULL,
        lowStockAlert INTEGER NOT NULL,
        color TEXT NOT NULL,
        profileId INTEGER NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        time TEXT NOT NULL,
        days TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        dose TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicineId) REFERENCES medicines(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE medicine_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicineId INTEGER NOT NULL,
        medicineName TEXT NOT NULL,
        profileId INTEGER NOT NULL,
        profileName TEXT NOT NULL,
        status TEXT NOT NULL,
        takenAt TEXT NOT NULL,
        dose TEXT NOT NULL
      )
    ''');

    // Helpful indexes
    await db.execute('CREATE INDEX idx_medicines_profile ON medicines(profileId)');
    await db.execute('CREATE INDEX idx_reminders_medicine ON reminders(medicineId)');
    await db.execute('CREATE INDEX idx_logs_medicine ON medicine_logs(medicineId)');
    await db.execute('CREATE INDEX idx_logs_profile ON medicine_logs(profileId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For a clean state when upgrading from v1 (which had no auth schema).
    // In production you would write a proper migration; here we recreate.
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS reminders');
      await db.execute('DROP TABLE IF EXISTS medicine_logs');
      await db.execute('DROP TABLE IF EXISTS medicines');
      await db.execute('DROP TABLE IF EXISTS profiles');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    }
  }

  // ===========================================================================
  // USERS
  // ===========================================================================
  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert(
      'users',
      user.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // ===========================================================================
  // PROFILES
  // ===========================================================================
  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    return db.insert('profiles', profile.toMap()..remove('id'));
  }

  Future<List<Profile>> getProfilesByUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'profiles',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Profile.fromMap).toList();
  }

  Future<int> updateProfile(Profile profile) async {
    final db = await database;
    return db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteProfile(int id) async {
    final db = await database;
    return db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // MEDICINES
  // ===========================================================================
  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    return db.insert('medicines', medicine.toMap()..remove('id'));
  }

  Future<List<Medicine>> getMedicinesByUser(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT m.* FROM medicines m
      INNER JOIN profiles p ON p.id = m.profileId
      WHERE p.userId = ?
      ORDER BY m.name ASC
    ''', [userId]);
    return rows.map(Medicine.fromMap).toList();
  }

  Future<int> updateMedicine(Medicine medicine) async {
    final db = await database;
    return db.update(
      'medicines',
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  Future<int> updateMedicineStock(int id, int newStock) async {
    final db = await database;
    return db.update(
      'medicines',
      {'currentStock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicine(int id) async {
    final db = await database;
    // FK ON DELETE CASCADE handles reminders. medicine_logs are kept as history.
    return db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // REMINDERS
  // ===========================================================================
  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return db.insert('reminders', reminder.toMap()..remove('id'));
  }

  Future<List<Reminder>> getRemindersByUser(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.* FROM reminders r
      INNER JOIN medicines m ON m.id = r.medicineId
      INNER JOIN profiles p ON p.id = m.profileId
      WHERE p.userId = ?
      ORDER BY r.time ASC
    ''', [userId]);
    return rows.map(Reminder.fromMap).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> toggleReminder(int id, bool isActive) async {
    final db = await database;
    return db.update(
      'reminders',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ===========================================================================
  // LOGS
  // ===========================================================================
  Future<int> insertLog(MedicineLog log) async {
    final db = await database;
    return db.insert('medicine_logs', log.toMap()..remove('id'));
  }

  Future<List<MedicineLog>> getLogsByUser(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT l.* FROM medicine_logs l
      INNER JOIN profiles p ON p.id = l.profileId
      WHERE p.userId = ?
      ORDER BY l.takenAt DESC
      LIMIT 200
    ''', [userId]);
    return rows.map(MedicineLog.fromMap).toList();
  }

  Future<Map<String, int>> getLogStatsByUser(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT l.status, COUNT(*) AS count FROM medicine_logs l
      INNER JOIN profiles p ON p.id = l.profileId
      WHERE p.userId = ?
      GROUP BY l.status
    ''', [userId]);

    final stats = <String, int>{'taken': 0, 'skipped': 0, 'missed': 0};
    for (final row in result) {
      final status = row['status'] as String?;
      final count = (row['count'] as int?) ?? 0;
      if (status != null && stats.containsKey(status)) {
        stats[status] = count;
      }
    }
    return stats;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
