import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medicare_v7.db'); // Bumped to v7
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT,
        name TEXT,
        phone TEXT,
        language_preference TEXT,
        last_login TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_name TEXT,
        age INTEGER,
        location TEXT,
        selected_symptoms TEXT,
        predicted_disease TEXT,
        severity_score INTEGER,
        disease_description TEXT,
        mcq_answers TEXT,
        created_at TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute('DROP TABLE IF EXISTS user_activities');
      await _createDB(db, newVersion);
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    await db.insert('users', {
      'id': user['id'].toString(),
      'firebase_uid': user['firebase_uid'],
      'name': user['name'],
      'phone': user['phone'],
      'language_preference': user['language'] ?? 'english',
      'last_login': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'phone = ?', whereArgs: [phone]);
    if (maps.isNotEmpty) return Map<String, dynamic>.from(maps.first);
    return null;
  }

  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete('users');
    await db.delete('user_activities');
  }

  Future<List<Map<String, dynamic>>> getAllActivities() async {
    final db = await instance.database;
    return await db.query('user_activities', orderBy: 'created_at DESC');
  }
}
