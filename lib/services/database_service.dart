import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/session.dart';
import '../models/task.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  /// Creates a [DatabaseService] backed by an in-memory SQLite database.
  /// Intended for use in tests only.
  static Future<DatabaseService> openInMemory() async {
    final service = DatabaseService._();
    service._db = await openDatabase(
      inMemoryDatabasePath,
      version: AppConstants.dbVersion,
      onCreate: service._onCreate,
    );
    return service;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tasksTable} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.sessionsTable} (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        comment TEXT,
        FOREIGN KEY (task_id) REFERENCES ${AppConstants.tasksTable}(id) ON DELETE CASCADE
      )
    ''');
  }

  // ---- Task CRUD ----

  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tasksTable,
      orderBy: 'created_at ASC',
    );
    return maps.map(Task.fromMap).toList();
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      AppConstants.tasksTable,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      AppConstants.tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.tasksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---- Session CRUD ----

  Future<List<Session>> getSessions() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.sessionsTable,
      orderBy: 'start_time DESC',
    );
    return maps.map(Session.fromMap).toList();
  }

  Future<List<Session>> getSessionsByTask(String taskId) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.sessionsTable,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'start_time DESC',
    );
    return maps.map(Session.fromMap).toList();
  }

  Future<List<Session>> getSessionsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.sessionsTable,
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return maps.map(Session.fromMap).toList();
  }

  Future<void> insertSession(Session session) async {
    final db = await database;
    await db.insert(
      AppConstants.sessionsTable,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    await db.update(
      AppConstants.sessionsTable,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.sessionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Wipes all locally cached tasks and sessions. Used on account deletion.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.sessionsTable);
    await db.delete(AppConstants.tasksTable);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
