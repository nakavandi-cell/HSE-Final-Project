import 'package:sqflite/sqflite.dart';
import '../models/asset_model.dart';
import '../models/checklist_model.dart';
import '../models/checklist_item_model.dart';

class DatabaseSeeder {
  static Future<void> seedData(Database db) async {
    // 1. Seed Assets (نمونه دارایی‌ها)
    await _seedAssets(db);

    // 2. Seed Checklists and Items
    await _seedChecklists(db);
  }

  static Future<void> _seedAssets(Database db) async {
    List<Asset> sampleAssets = [
      Asset(assetCode: 'F-001', name: 'کپسول آتش‌نشانی پودری 4kg', type: 'Fire', location: 'سالن تولید'),
      Asset(assetCode: 'F-002', name: 'کپسول CO2 3kg', type: 'Fire', location: 'آزمایشگاه'),
      Asset(assetCode: 'P-001', name: 'تابلو برق اصلی انبار', type: 'Panel', location: 'انبار'),
      Asset(assetCode: 'P-002', name: 'تابلو برق خروجی سالن', type: 'Panel', location: 'خروجی سالن'),
      Asset(assetCode: 'S-001', name: 'تابلو پست برق اصلی', type: 'Substation', location: 'اتاق پست'),
    ];

    for (var asset in sampleAssets) {
      await db.insert('assets', asset.toMap());
    }
  }

  static Future<void> _seedChecklists(Database db) async {
    // چک‌لیست کپسول آتش‌نشانی
    int fireChecklistId = await db.insert('checklists', Checklist(title: 'چک‌لیست کپسول آتش‌نشانی', assetType: 'Fire').toMap());
    List<Map<String, dynamic>> fireItems = [
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا بدنه کپسول فاقد خوردگی یا فرورفتگی است؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا گیج فشار در محدوده سبز قرار دارد؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا پلمب و ضامن سالم و دست‌نخورده است؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا شیلنگ و نازل فاقد ترک‌خوردگی یا گرفتگی است؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا تاریخ شارژ کپسول معتبر است؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا برچسب مشخصات و محل نصب خوانا و صحیح است؟').toMap(),
      ChecklistItem(checklistId: fireChecklistId, question: 'آیا دسترسی به کپسول آسان و بدون مانع است؟').toMap(),
    ];
    for (var item in fireItems) await db.insert('checklist_items', item);

    // چک‌لیست تابلو برق عمومی
    int panelChecklistId = await db.insert('checklists', Checklist(title: 'چک‌لیست تابلو برق عمومی', assetType: 'Panel').toMap());
    List<Map<String, dynamic>> panelItems = [
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا درب تابلو بسته و دارای قفل ایمن است؟').toMap(),
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا بدنه تابلو فاقد آثار داغی، سوختگی یا آسیب فیزیکی است؟').toMap(),
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا علائم هشدار (مانند خطر برق گرفتگی) نصب شده و خوانا هستند؟').toMap(),
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا سیم‌کشی داخلی مرتب، عایق‌بندی شده و بدون لخت‌شدگی است؟').toMap(),
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا از تجمع گرد و غبار یا رطوبت در داخل تابلو جلوگیری شده است؟').toMap(),
      ChecklistItem(checklistId: panelChecklistId, question: 'آیا ورودی کابل‌ها به تابلو دارای گلند مناسب است؟').toMap(),
    ];
    for (var item in panelItems) await db.insert('checklist_items', item);

    // چک‌لیست تابلو پست برق
    int substationChecklistId = await db.insert('checklists', Checklist(title: 'چک‌لیست تابلو پست برق', assetType: 'Substation').toMap());
    List<Map<String, dynamic>> substationItems = [
      ChecklistItem(checklistId: substationChecklistId, question: 'وضعیت ظاهری تجهیزات پست (ترانسفورماتور، کلیدها) مناسب است؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'آیا تجهیزات حفاظتی (فیوزها، رله‌ها) سالم و به‌روز هستند؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'دمای عملکرد تجهیزات در محدوده مجاز است؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'آیا صدای غیرعادی از تجهیزات شنیده می‌شود؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'وضعیت سیستم ارتینگ و اتصال به زمین مناسب است؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'آیا علائم و تابلوهای هشدار دهنده در محل نصب شده‌اند؟').toMap(),
      ChecklistItem(checklistId: substationChecklistId, question: 'تهویه مناسب در اتاق پست برقرار است؟').toMap(),
    ];
    for (var item in substationItems) await db.insert('checklist_items', item);
  }
}
