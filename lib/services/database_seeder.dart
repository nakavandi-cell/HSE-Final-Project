import 'package:sqflite/sqflite.dart';
import '../models/asset_model.dart';
import '../models/checklist_model.dart';
import '../models/checklist_item_model.dart';

class DatabaseSeeder {
  static Future<void> seedData(Database db) async {
    // از تکرار داده‌ها با چک کردن وجود دارایی جلوگیری می‌کنیم
    final assetCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM assets'),
        ) ??
        0;
    final checklistCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM checklists'),
        ) ??
        0;

    // فقط اگر هر دو جدول خالی باشند، داده اولیه seed می‌شود
    if (assetCount == 0 && checklistCount == 0) {
      await _seedAssets(db);
      await _seedChecklists(db);
    }
  }

  static Future<void> _seedAssets(Database db) async {
    final List<Asset> sampleAssets = [
      Asset(
        assetCode: 'F-001',
        name: 'کپسول آتش‌نشانی پودری 4kg',
        type: 'Extinguisher',
        location: 'سالن تولید',
      ),
      Asset(
        assetCode: 'F-002',
        name: 'کپسول CO2 3kg',
        type: 'Extinguisher',
        location: 'آزمایشگاه',
      ),
      Asset(
        assetCode: 'P-001',
        name: 'تابلو برق اصلی انبار',
        type: 'Electrical Panel',
        location: 'انبار',
      ),
      Asset(
        assetCode: 'P-002',
        name: 'تابلو برق خروجی سالن',
        type: 'Electrical Panel',
        location: 'خروجی سالن',
      ),
      Asset(
        assetCode: 'S-001',
        name: 'تابلو پست برق اصلی',
        type: 'Substation',
        location: 'اتاق پست',
      ),
    ];

    for (final asset in sampleAssets) {
      await db.insert('assets', asset.toMap());
    }
  }

  static Future<void> _seedChecklists(Database db) async {
    // چک‌لیست کپسول آتش‌نشانی
    final extinguisherChecklistId = await db.insert(
      'checklists',
      Checklist(title: 'چک‌لیست کپسول آتش‌نشانی', assetType: 'Extinguisher').toMap(),
    );

    final extinguisherItems = [
      'آیا بدنه کپسول فاقد خوردگی یا فرورفتگی است؟',
      'آیا گیج فشار در محدوده سبز قرار دارد؟',
      'آیا پلمب و ضامن سالم و دست‌نخورده است؟',
      'آیا شیلنگ و نازل فاقد ترک‌خوردگی یا گرفتگی است؟',
      'آیا تاریخ شارژ کپسول معتبر است؟',
      'آیا برچسب مشخصات و محل نصب خوانا و صحیح است؟',
      'آیا دسترسی به کپسول آسان و بدون مانع است؟',
    ];
    for (final question in extinguisherItems) {
      await db.insert(
        'checklist_items',
        ChecklistItem(checklistId: extinguisherChecklistId, question: question).toMap(),
      );
    }

    // چک‌لیست تابلو برق
    final electricalPanelChecklistId = await db.insert(
      'checklists',
      Checklist(title: 'چک‌لیست تابلو برق عمومی', assetType: 'Electrical Panel').toMap(),
    );

    final electricalPanelItems = [
      'آیا درب تابلو بسته و دارای قفل ایمن است؟',
      'آیا بدنه تابلو فاقد آثار داغی، سوختگی یا آسیب فیزیکی است؟',
      'آیا علائم هشدار (مانند خطر برق گرفتگی) نصب شده و خوانا هستند؟',
      'آیا سیم‌کشی داخلی مرتب، عایق‌بندی شده و بدون لخت‌شدگی است؟',
      'آیا از تجمع گرد و غبار یا رطوبت در داخل تابلو جلوگیری شده است؟',
      'آیا ورودی کابل‌ها به تابلو دارای گلند مناسب است؟',
    ];
    for (final question in electricalPanelItems) {
      await db.insert(
        'checklist_items',
        ChecklistItem(checklistId: electricalPanelChecklistId, question: question).toMap(),
      );
    }

    // چک‌لیست پست برق
    final substationChecklistId = await db.insert(
      'checklists',
      Checklist(title: 'چک‌لیست تابلو پست برق', assetType: 'Substation').toMap(),
    );

    final substationItems = [
      'وضعیت ظاهری تجهیزات پست (ترانسفورماتور، کلیدها) مناسب است؟',
      'آیا تجهیزات حفاظتی (فیوزها، رله‌ها) سالم و به‌روز هستند؟',
      'دمای عملکرد تجهیزات در محدوده مجاز است؟',
      'آیا صدای غیرعادی از تجهیزات شنیده می‌شود؟',
      'وضعیت سیستم ارتینگ و اتصال به زمین مناسب است؟',
      'آیا علائم و تابلوهای هشدار دهنده در محل نصب شده‌اند؟',
      'تهویه مناسب در اتاق پست برقرار است؟',
    ];
    for (final question in substationItems) {
      await db.insert(
        'checklist_items',
        ChecklistItem(checklistId: substationChecklistId, question: question).toMap(),
      );
    }
  }
}
