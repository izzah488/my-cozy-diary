import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DiaryDatabase {
  static final DiaryDatabase instance = DiaryDatabase._init();
  static Database? _database;

  DiaryDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE diary (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      title TEXT,
      content TEXT,
      emoji TEXT,
      imagePath TEXT
    )
    ''');
  }

  Future<int> insertEntry(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('diary', entry);
  }

  Future<List<Map<String, dynamic>>> fetchEntries() async {
    final db = await instance.database;
    return await db.query('diary', orderBy: 'date DESC');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
  Future<int> getTotalEntryCount() async {
  final db = await instance.database;
  final result = await db.rawQuery('SELECT COUNT(*) as count FROM diary_entries');
  return Sqflite.firstIntValue(result) ?? 0;
}

}
