import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/checklist_item_model.dart';
import '../models/inspection_model.dart';
import '../models/inspection_answer_model.dart';
import '../services/database_helper.dart';
import '../services/excel_service.dart';

class InspectionFormScreen extends StatefulWidget {
  final int? assetId;
  final String assetName;
  final String assetType;

  const InspectionFormScreen({
    super.key,
    this.assetId,
    required this.assetName,
    required this.assetType,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _inspectorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<ChecklistItem> _checklistItems = [];
  bool _isLoading = true;
  String _overallStatus = 'Pass';

  // Each answer maps checklistItemId -> {status, comment, photoPath}
  final Map<int, Map<String, dynamic>> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    // استفاده از متد تعریف شده در دیتابیس (مطمئن شو در مرحله بعد این متد را در DatabaseHelper داریم)
    final items = await _dbHelper.getChecklistItemsByAssetType(widget.assetType);
    setState(() {
      _checklistItems = items;
      _isLoading = false;
      for (var item in items) {
        _answers[item.id!] = {
          'status': 'Pass',
          'comment': '',
          'photoPath': null,
        };
      }
    });
  }

  Future<void> _pickPhoto(int itemId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _answers[itemId]?['photoPath'] = pickedFile.path;
      });
    }
  }

  Future<void> _submitInspection() async {
    if (_inspectorController.text.trim().isEmpty) {
      _showSnackBar('لطفاً نام بازرس را وارد کنید', isError: true);
      return;
    }

    if (_checklistItems.isEmpty) {
      _showSnackBar('چک‌لیستی برای این دارایی یافت نشد', isError: true);
      return;
    }

    // Determine overall status
    final anyFail = _answers.values.any((a) => a['status'] == 'Fail');
    final anyNac = _answers.values.any((a) => a['status'] == 'N/A');
    _overallStatus = anyFail ? 'Fail' : (anyNac ? 'Conditional' : 'Pass');

    try {
      final inspection = Inspection(
        assetId: widget.assetId,
        date: DateTime.now().toIso8601String(),
        inspectorName: _inspectorController.text.trim(),
        location: _locationController.text.trim(),
        overallStatus: _overallStatus,
      );

      final db = await _dbHelper.database;
      final inspectionId = await db.insert('inspections', inspection.toMap());

      for (var item in _checklistItems) {
        final answerData = _answers[item.id!]!;
        final answer = InspectionAnswer(
          inspectionId: inspectionId,
          checklistItemId: item.id!,
          result: answerData['status'], // در لاگ شما به جای status از result استفاده شده بود
          comment: answerData['comment'],
          photoPath: answerData['photoPath'],
        );
        await db.insert('inspection_answers', answer.toMap());
      }

      _showSnackBar('بازرسی با موفقیت ثبت شد');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('خطا در ثبت بازرسی: $e', isError: true);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      await ExcelService.exportInspectionToExcel(
        assetName: widget.assetName,
        assetType: widget.assetType,
        inspectorName: _inspectorController.text.trim(),
        checklistItems: _checklistItems,
        answers: _answers,
      );
      _showSnackBar('فایل Excel با موفقیت ذخیره شد');
    } catch (e) {
      _showSnackBar('خطا در ذخیره Excel: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _inspectorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('بازرسی: ${widget.assetName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'خروجی Excel',
            onPressed: _checklistItems.isEmpty ? null : _exportToExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _checklistItems.isEmpty
              ? const Center(child: Text('چک‌لیستی برای این نوع دارایی تعریف نشده است'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('نوع دارایی: ${widget.assetType}', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _inspectorController,
                                decoration: const InputDecoration(
                                  labelText: 'نام بازرس *',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'موقعیت مکانی',
                                  prefixIcon: Icon(Icons.location_on),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('تاریخ بازرسی: $dateString', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _checklistItems.length,
                          itemBuilder: (context, index) {
                            final item = _checklistItems[index];
                            final answer = _answers[item.id!]!;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${item.question}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Text('Pass'),
                                            selected: answer['status'] == 'Pass',
                                            selectedColor: Colors.green.shade200,
                                            onSelected: (_) => setState(() => answer['status'] = 'Pass'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Text('Fail'),
                                            selected: answer['status'] == 'Fail',
                                            selectedColor: Colors.red.shade200,
                                            onSelected: (_) => setState(() => answer['status'] = 'Fail'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Text('N/A'),
                                            selected: answer['status'] == 'N/A',
                                            selectedColor: Colors.grey.shade300,
                                            onSelected: (_) => setState(() => answer['status'] = 'N/A'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      maxLines: 2,
                                      decoration: const InputDecoration(
                                        labelText: 'توضیحات / اقدام اصلاحی',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onChanged: (value) => answer['comment'] = value,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.camera_alt),
                                          onPressed: () => _pickPhoto(item.id!),
                                        ),
                                        if (answer['photoPath'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: Image.file(
                                              File(answer['photoPath']),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        const Spacer(),
                                        if (answer['photoPath'] != null)
                                          const Text('تصویر ثبت شد', style: TextStyle(color: Colors.green, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _submitInspection,
                          icon: const Icon(Icons.save),
                          label: const Text('ثبت بازرسی نهایی'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
