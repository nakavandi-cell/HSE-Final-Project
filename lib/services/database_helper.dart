import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/checklist_item_model.dart';

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
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assetCode TEXT,
        name TEXT,
        type TEXT,
        location TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checklists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        assetType TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        checklistId INTEGER,
        question TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assetId INTEGER,
        date TEXT,
        inspectorName TEXT,
        location TEXT,
        shift TEXT,
        overallStatus TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE inspection_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionId INTEGER,
        checklistItemId INTEGER,
        result TEXT,
        comment TEXT,
        photoPath TEXT
      )
    ''');

    await _insertDefaultChecklists(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'inspections', 'location', 'TEXT');
      await _addColumnIfNotExists(db, 'inspections', 'shift', 'TEXT');
      await _addColumnIfNotExists(db, 'inspection_answers', 'comment', 'TEXT');
      await _addColumnIfNotExists(db, 'inspection_answers', 'photoPath', 'TEXT');

      final checklistCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM checklists'),
      );

      if (checklistCount == 0) {
        await _insertDefaultChecklists(db);
      }
    }
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);

    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  Future<void> _insertDefaultChecklists(Database db) async {
    final extinguisherChecklistId = await db.insert('checklists', {
      'title': 'چک لیست کپسول آتش نشانی',
      'assetType': 'Extinguisher',
    });

    final electricalPanelChecklistId = await db.insert('checklists', {
      'title': 'چک لیست تابلو برق',
      'assetType': 'Electrical Panel',
    });

    final substationChecklistId = await db.insert('checklists', {
      'title': 'چک لیست پست برق',
      'assetType': 'Substation',
    });

    final extinguisherItems = [
      'کپسول در محل مناسب و قابل دسترس قرار دارد؟',
      'گیج فشار در محدوده مجاز قرار دارد؟',
      'پلمپ و ضامن سالم است؟',
      'بدنه کپسول سالم و بدون خوردگی است؟',
      'برچسب شارژ و تاریخ اعتبار قابل مشاهده است؟',
      'مسیر دسترسی به کپسول مسدود نیست؟',
    ];

    final electricalPanelItems = [
      'درب تابلو برق سالم و قابل بسته شدن است؟',
      'علائم هشدار برق گرفتگی نصب شده است؟',
      'داخل تابلو تمیز و بدون گرد و غبار زیاد است؟',
      'سیم کشی‌ها مرتب و بدون آسیب دیدگی هستند؟',
      'تجهیزات حفاظتی و فیوزها سالم هستند؟',
      'اطراف تابلو برق عاری از مواد قابل اشتعال است؟',
    ];

    final substationItems = [
      'درب و قفل پست برق سالم است؟',
      'تابلوها و علائم هشدار نصب شده‌اند؟',
      'تهویه پست برق مناسب است؟',
      'تجهیزات عایق و ایمنی در محل موجود است؟',
      'نشتی روغن یا آثار سوختگی مشاهده نمی‌شود؟',
      'دسترسی افراد غیرمجاز کنترل شده است؟',
    ];

    await _insertChecklistItems(db, extinguisherChecklistId, extinguisherItems);
    await _insertChecklistItems(db, electricalPanelChecklistId, electricalPanelItems);
    await _insertChecklistItems(db, substationChecklistId, substationItems);
  }

  Future<void> _insertChecklistItems(
    Database db,
    int checklistId,
    List<String> questions,
  ) async {
    for (final question in questions) {
      await db.insert('checklist_items', {
        'checklistId': checklistId,
        'question': question,
      });
    }
  }

  Future<List<ChecklistItem>> getChecklistItemsByAssetType(String assetType) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT checklist_items.*
      FROM checklist_items
      INNER JOIN checklists
      ON checklist_items.checklistId = checklists.id
      WHERE checklists.assetType = ?
      ORDER BY checklist_items.id ASC
      ''',
      [assetType],
    );

    return result.map((map) => ChecklistItem.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllAssets() async {
    final db = await database;
    return await db.query('assets', orderBy: 'id DESC');
  }

  Future<int> insertAsset(Map<String, dynamic> asset) async {
    final db = await database;
    return await db.insert('assets', asset);
  }

  Future<int> updateAsset(int id, Map<String, dynamic> asset) async {
    final db = await database;
    return await db.update(
      'assets',
      asset,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAsset(int id) async {
    final db = await database;
    return await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllInspections() async {
    final db = await database;

    return await db.rawQuery('''
      SELECT 
        inspections.*,
        assets.name AS assetName,
        assets.type AS assetType
      FROM inspections
      LEFT JOIN assets ON inspections.assetId = assets.id
      ORDER BY inspections.id DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getInspectionAnswers(int inspectionId) async {
    final db = await database;

    return await db.rawQuery(
      '''
      SELECT 
        inspection_answers.*,
        checklist_items.question
      FROM inspection_answers
      LEFT JOIN checklist_items
      ON inspection_answers.checklistItemId = checklist_items.id
      WHERE inspection_answers.inspectionId = ?
      ORDER BY inspection_answers.id ASC
      ''',
      [inspectionId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
