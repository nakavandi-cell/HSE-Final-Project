import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/checklist_item_model.dart';
import '../services/database_helper.dart';
import '../services/excel_service.dart';

class InspectionFormScreen extends StatefulWidget {
  final int assetId;
  final String assetName;
  final String assetType;

  const InspectionFormScreen({
    super.key,
    required this.assetId,
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
    try {
      final items = await _dbHelper.getChecklistItemsByAssetType(widget.assetType);
      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('خطا در بارگذاری چک‌لیست: $e', isError: true);
    }
  }

  Future<void> _pickPhoto(int itemId) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          // Ensure the map entry for the item exists before updating
          if (_answers.containsKey(itemId)) {
            _answers[itemId]?['photoPath'] = pickedFile.path;
          } else {
            // This case should ideally not happen if _answers is initialized correctly
            _answers[itemId] = {
              'status': 'Pass', // Default status if item was somehow missed
              'comment': '',
              'photoPath': pickedFile.path,
            };
          }
        });
      }
    } catch (e) {
      _showSnackBar('خطا در گرفتن عکس: $e', isError: true);
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
      // Use the transactional method from DatabaseHelper
      final inspectionId = await _dbHelper.insertInspectionAndAnswers(
        assetId: widget.assetId,
        inspectorName: _inspectorController.text.trim(),
        location: _locationController.text.trim(),
        overallStatus: _overallStatus,
        answers: _answers,
      );

      _showSnackBar('بازرسی با موفقیت ثبت شد');
      if (mounted) {
        // Pop with a result to indicate success if needed elsewhere
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('خطا در ثبت بازرسی: $e', isError: true);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // Ensure all checklist items have an entry in _answers, even if not explicitly set
      for (var item in _checklistItems) {
        _answers.putIfAbsent(item.id!, () => {'status': 'Pass', 'comment': '', 'photoPath': null});
      }

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
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
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
    // Format date for display
    final dateString = DateFormat('yyyy/MM/dd – HH:mm').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('بازرسی: ${widget.assetName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'خروجی Excel',
            // Disable export if checklist is empty or loading
            onPressed: _isLoading || _checklistItems.isEmpty ? null : _exportToExcel,
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
                      // Asset and Inspector Info Card
                      Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('نوع دارایی: ${widget.assetType}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _inspectorController,
                                decoration: const InputDecoration(
                                  labelText: 'نام بازرس *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'موقعیت مکانی',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text('تاریخ بازرسی: $dateString', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      // Checklist Items List
                      Expanded(
                        child: ListView.builder(
                          itemCount: _checklistItems.length,
                          itemBuilder: (context, index) {
                            final item = _checklistItems[index];
                            // Ensure the answer map entry exists
                            _answers.putIfAbsent(item.id!, () => {'status': 'Pass', 'comment': '', 'photoPath': null});
                            final answer = _answers[item.id!]!;

                            return Card(
                              elevation: 1.0,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${index + 1}. ${item.question}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 12),
                                    // Status Selection Chips
                                    Row(
                                      children: [
                                        _buildStatusChip('Pass', Colors.green.shade600, 'Pass', answer),
                                        const SizedBox(width: 8),
                                        _buildStatusChip('Fail', Colors.red.shade600, 'Fail', answer),
                                        const SizedBox(width: 8),
                                        _buildStatusChip('N/A', Colors.grey.shade600, 'N/A', answer),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Comment TextField
                                    TextField(
                                      maxLines: 2,
                                      controller: TextEditingController(text: answer['comment'] as String?)
                                        ..selection = TextSelection.fromPosition(
                                            TextPosition(offset: (answer['comment'] as String?)?.length ?? 0)),
                                      decoration: const InputDecoration(
                                        labelText: 'توضیحات / اقدام اصلاحی',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (value) => answer['comment'] = value,
                                    ),
                                    const SizedBox(height: 12),
                                    // Photo Attachment Row
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                                          label: const Text('عکس'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blueGrey.shade100,
                                            foregroundColor: Colors.blueGrey.shade800,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                          ),
                                          onPressed: () => _pickPhoto(item.id!),
                                        ),
                                        const Spacer(),
                                        if (answer['photoPath'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8.0),
                                              child: Image.file(
                                                File(answer['photoPath']),
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        if (answer['photoPath'] != null)
                                          const Text('تصویر ضمیمه شد', style: TextStyle(color: Colors.green, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _submitInspection,
                          icon: const Icon(Icons.save_outlined, size: 24),
                          label: const Text('ثبت بازرسی نهایی', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Helper method to build status chips
  Widget _buildStatusChip(String label, Color color, String value, Map<String, dynamic> answer) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
        selected: answer['status'] == value,
        selectedColor: color.withOpacity(0.2),
        side: BorderSide(color: color.withOpacity(0.7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onSelected: (_) {
          setState(() {
            answer['status'] = value;
            // Optionally clear comment or photo if status changes to Pass?
            // if (value == 'Pass') {
            //   answer['comment'] = '';
            //   answer['photoPath'] = null;
            // }
          });
        },
      ),
    );
  }
}
