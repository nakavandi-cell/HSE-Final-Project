import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // برای فرمت تاریخ
import '../models/inspection_model.dart';
import '../models/inspection_answer_model.dart'; // اضافه شده
import '../services/database_helper.dart';
import '../models/asset_model.dart'; // برای دریافت اطلاعات Asset
import '../models/checklist_model.dart'; // برای دریافت اطلاعات Checklist
import '../models/checklist_item_model.dart'; // برای دریافت اطلاعات ChecklistItem

class InspectionFormScreen extends StatefulWidget {
  final int? assetId; // دریافت ID دارایی
  final String? assetName; // دریافت نام دارایی
  final String? assetType; // دریافت نوع دارایی

  const InspectionFormScreen({
    super.key,
    this.assetId,
    this.assetName,
    this.assetType,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _inspectorNameController;
  late TextEditingController _shiftController;
  late TextEditingController _remarksController;
  String _selectedStatus = 'ایمن'; // وضعیت پیش‌فرض
  List<ChecklistItem> _checklistItems = [];
  List<String> _results = []; // برای ذخیره نتایج هر آیتم
  List<TextEditingController> _commentControllers = []; // برای کامنت‌های هر آیتم
  List<String?> _selectedPhotos = []; // برای مسیر عکس‌ها

  @override
  void initState() {
    super.initState();
    _inspectorNameController = TextEditingController();
    _shiftController = TextEditingController();
    _remarksController = TextEditingController();
    _loadChecklistItems();
  }

  @override
  void dispose() {
    _inspectorNameController.dispose();
    _shiftController.dispose();
    _remarksController.dispose();
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadChecklistItems() async {
    if (widget.assetId == null || widget.assetType == null) {
      // اگر اطلاعات دارایی نداریم، نمی‌توانیم چک‌لیست را بارگذاری کنیم
      // این حالت نباید رخ دهد چون از AssetListScreen می‌آییم
      return;
    }

    final db = DatabaseHelper.instance.database;
    final checklist = await (await db).query(
      'checklists',
      where: 'assetType = ?',
      whereArgs: [widget.assetType],
      limit: 1,
    );

    if (checklist.isNotEmpty) {
      final checklistId = checklist.first['id'] as int;
      final items = await (await db).query(
        'checklist_items',
        where: 'checklistId = ?',
        whereArgs: [checklistId],
        orderBy: 'orderNo ASC', // فرض می‌کنیم orderNo داریم، اگر نه، id را استفاده می‌کنیم
      );

      setState(() {
        _checklistItems = items.map((item) => ChecklistItem.fromMap(item)).toList();
        // مقداردهی اولیه نتایج و کامنت‌ها
        _results = List.filled(_checklistItems.length, 'Pass'); // پیش‌فرض Pass
        _commentControllers = List.generate(_checklistItems.length, (_) => TextEditingController());
        _selectedPhotos = List.filled(_checklistItems.length, null);
      });
    }
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.assetId == null || widget.assetType == null || _checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: اطلاعات دارایی یا چک‌لیست ناقص است.')));
      return;
    }

    final db = DatabaseHelper.instance.database;
    final inspection = Inspection(
      assetId: widget.assetId!,
      checklistId: _checklistItems.first.checklistId, // فعلا اولی را می‌گیریم، باید درست انتخاب شود
      date: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      inspectorName: _inspectorNameController.text,
      shift: _shiftController.text,
      overallStatus: _selectedStatus,
      remarks: _remarksController.text,
    );

    try {
      final inspectionId = await (await db).insert('inspections', inspection.toMap());

      // ذخیره پاسخ‌های آیتم‌ها
      for (int i = 0; i < _checklistItems.length; i++) {
        final answer = InspectionAnswer(
          inspectionId: inspectionId,
          checklistItemId: _checklistItems[i].id!,
          result: _results[i],
          // comment: _commentControllers[i].text, // فعلا کامنت ذخیره نمی‌شود
          // photoPath: _selectedPhotos[i], // فعلا عکس ذخیره نمی‌شود
        );
        await (await db).insert('inspection_answers', answer.toMap());
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بازرسی با موفقیت ثبت شد!')));
      // رفتن به صفحه لیست دارایی‌ها یا گزارش‌ها بعد از ذخیره
      Navigator.pop(context); // بازگشت به صفحه قبل
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ثبت بازرسی: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بازرسی ${widget.assetName ?? ''} (${widget.assetType ?? ''})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // بخش اطلاعات بازرسی
              TextFormField(
                controller: _inspectorNameController,
                decoration: const InputDecoration(labelText: 'نام بازرس'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'لطفاً نام بازرس را وارد کنید';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shiftController,
                decoration: const InputDecoration(labelText: 'شیفت'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'لطفاً شیفت را وارد کنید';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // بخش وضعیت کلی
              const Text('وضعیت کلی:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['ایمن', 'ناایمن'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'انتخاب وضعیت'),
              ),
              const SizedBox(height: 20),

              // بخش چک‌لیست آیتم‌ها
              if (_checklistItems.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جزئیات بازرسی:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...List.generate(_checklistItems.length, (index) {
                      final item = _checklistItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.question, style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'Pass',
                                    groupValue: _results[index],
                                    onChanged: (value) {
                                      setState(() => _results[index] = value!);
                                    },
                                  ),
                                  const Text('سالم'),
                                  const SizedBox(width: 20),
                                  Radio<String>(
                                    value: 'Fail',
                                    groupValue: _results[index],
                                    onChanged: (value) {
                                      setState(() => _results[index] = value!);
                                    },
                                  ),
                                  const Text('ناقص'),
                                ],
                              ),
                              // TODO: Add comment field and photo upload later
                              // TextFormField(
                              //   controller: _commentControllers[index],
                              //   decoration: InputDecoration(labelText: 'توضیحات (اختیاری)'),
                              // ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                )
              else if (widget.assetType != null) // اگر نوع دارایی داریم اما چک‌لیست بار نشد
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('برای این نوع دارایی، چک‌لیستی یافت نشد یا در حال بارگذاری است.'),
                ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'نکات کلی بازرسی (اختیاری)'),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveInspection,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('ثبت بازرسی'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
