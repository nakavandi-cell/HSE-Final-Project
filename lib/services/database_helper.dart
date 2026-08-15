import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async => _database ??= await _initDB('hse_database.db');

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE assets (id INTEGER PRIMARY KEY AUTOINCREMENT, assetCode TEXT, name TEXT, type TEXT, location TEXT)''');
    await db.execute('''CREATE TABLE checklists (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, assetType TEXT)''');
    await db.execute('''CREATE TABLE checklist_items (id INTEGER PRIMARY KEY AUTOINCREMENT, checklistId INTEGER, question TEXT)''');
    await db.execute('''CREATE TABLE inspections (id INTEGER PRIMARY KEY AUTOINCREMENT, assetId INTEGER, date TEXT, inspectorName TEXT, shift TEXT, overallStatus TEXT)''');
    await db.execute('''CREATE TABLE inspection_answers (id INTEGER PRIMARY KEY AUTOINCREMENT, inspectionId INTEGER, checklistItemId INTEGER, result TEXT)''');
  }
}
