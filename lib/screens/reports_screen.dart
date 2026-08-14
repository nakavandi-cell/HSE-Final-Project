import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
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
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.readAllInspections();
    setState(() {
      _inspections = data;
      _isLoading = false;
    });
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['HSE_Report'];
    excel.delete('Sheet1');

    // تیترهای جدول
    List<CellValue> header = [
      TextCellValue('شناسه'),
      TextCellValue('تاریخ'),
      TextCellValue('نام بازرس'),
      TextCellValue('شیفت'),
      TextCellValue('واحد'),
      TextCellValue('وضعیت'),
    ];
    sheetObject.appendRow(header);

    // افزودن داده‌ها
    for (var inspection in _inspections) {
      sheetObject.appendRow([
        TextCellValue(inspection.id.toString()),
        TextCellValue(inspection.date),
        TextCellValue(inspection.inspectorName),
        TextCellValue(inspection.shift),
        TextCellValue(inspection.unit),
        TextCellValue(inspection.status),
      ]);
    }

    // ذخیره فایل
    final directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/HSE_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final fileBytes = excel.save();
    
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      // اشتراک‌گذاری فایل
      await Share.shareXFiles([XFile(filePath)], text: 'گزارش بازرسی HSE');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارشات بازرسی HSE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _inspections.isEmpty ? null : _exportToExcel,
            tooltip: 'خروجی اکسل',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _inspections.isEmpty
                ? const Center(child: Text('هیچ موردی ثبت نشده است'))
                : ListView.builder(
                    itemCount: _inspections.length,
                    itemBuilder: (context, index) {
                      final item = _inspections[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('واحد: ${item.unit}'),
                          subtitle: Text('بازرس: ${item.inspectorName} - تاریخ: ${item.date}'),
                          trailing: Icon(
                            item.status == 'ایمن' ? Icons.check_circle : Icons.warning,
                            color: item.status == 'ایمن' ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InspectionFormScreen()),
          );
          _loadInspections();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
