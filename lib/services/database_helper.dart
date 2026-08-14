import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inspection_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hse_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        inspectorName TEXT NOT NULL,
        shift TEXT NOT NULL,
        unit TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // ثبت بازرسی جدید
  Future<int> insertInspection(Inspection inspection) async {
    final db = await instance.database;
    return await db.insert('inspections', inspection.toMap());
  }

  // دریافت تمام بازرسی‌ها
  Future<List<Inspection>> getAllInspections() async {
    final db = await instance.database;
    final result = await db.query('inspections', orderBy: 'id DESC');

    return result.map((json) => Inspection.fromMap(json)).toList();
  }

  // حذف یک بازرسی
  Future<int> deleteInspection(int id) async {
    final db = await instance.database;
    return await db.delete(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // بستن دیتابیس
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
