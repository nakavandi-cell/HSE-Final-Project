import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/inspection_model.dart';
import '../services/database_helper.dart';
import 'inspection_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Inspection> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() {
      _isLoading = true;
    });

    final data = await DatabaseHelper.instance.getAllInspections();

    if (!mounted) return;

    setState(() {
      _inspections = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteInspection(int id) async {
    await DatabaseHelper.instance.deleteInspection(id);
    await _loadInspections();
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();

    final sheet = excel['HSE_Report'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('شناسه'),
      TextCellValue('تاریخ'),
      TextCellValue('نام بازرس'),
      TextCellValue('شیفت'),
      TextCellValue('واحد'),
      TextCellValue('وضعیت'),
    ]);

    for (final inspection in _inspections) {
      sheet.appendRow([
        TextCellValue(inspection.id?.toString() ?? ''),
        TextCellValue(inspection.date),
        TextCellValue(inspection.inspectorName),
        TextCellValue(inspection.shift),
        TextCellValue(inspection.unit),
        TextCellValue(inspection.status),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/HSE_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final fileBytes = excel.save();

    if (fileBytes == null) {
      return;
    }

    final file = File(filePath);

    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'گزارش بازرسی HSE',
    );
  }

  Future<void> _openInspectionForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InspectionFormScreen(),
      ),
    );

    await _loadInspections();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('گزارش‌های بازرسی HSE'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'خروجی اکسل',
              onPressed: _inspections.isEmpty ? null : _exportToExcel,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _openInspectionForm,
          tooltip: 'ثبت بازرسی جدید',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_inspections.isEmpty) {
      return const Center(
        child: Text('هیچ موردی ثبت نشده است'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInspections,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _inspections.length,
        itemBuilder: (context, index) {
          final inspection = _inspections[index];

          final isSafe = inspection.status == 'ایمن';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                isSafe ? Icons.check_circle : Icons.warning,
                color: isSafe ? Colors.green : Colors.red,
                size: 32,
              ),
              title: Text(
                'واحد: ${inspection.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'بازرس: ${inspection.inspectorName}\n'
                'تاریخ: ${inspection.date} | '
                'شیفت: ${inspection.shift}\n'
                'وضعیت: ${inspection.status}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                tooltip: 'حذف بازرسی',
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('حذف بازرسی'),
                        content: const Text(
                          'آیا از حذف این بازرسی اطمینان دارید؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('انصراف'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('حذف'),
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldDelete == true && inspection.id != null) {
                    await _deleteInspection(inspection.id!);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
