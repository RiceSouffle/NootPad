import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nootpad.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT DEFAULT '',
            category TEXT DEFAULT 'General',
            color TEXT DEFAULT 'cream',
            isPinned INTEGER DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }
}
