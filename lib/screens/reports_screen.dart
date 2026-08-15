import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/inspection_model.dart';
import '../services/database_helper.dart';

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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final data = await DatabaseHelper.instance.getAllInspections();

      if (!mounted) return;

      setState(() {
        _inspections = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بارگذاری گزارش‌ها: $error'),
        ),
      );
    }
  }

  Future<void> _deleteInspection(int id) async {
    try {
      await DatabaseHelper.instance.deleteInspection(id);
      await _loadInspections();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بازرسی با موفقیت حذف شد'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف بازرسی: $error'),
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_inspections.isEmpty) return;

    try {
      final excel = Excel.createExcel();
      final sheet = excel['HSE_Report'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      sheet.appendRow([
        TextCellValue('شناسه'),
        TextCellValue('شناسه تجهیز'),
        TextCellValue('تاریخ'),
        TextCellValue('نام بازرس'),
        TextCellValue('محل'),
        TextCellValue('شیفت'),
        TextCellValue('وضعیت کلی'),
      ]);

      for (final inspection in _inspections) {
        sheet.appendRow([
          TextCellValue(inspection.id?.toString() ?? ''),
          TextCellValue(inspection.assetId.toString()),
          TextCellValue(inspection.date),
          TextCellValue(inspection.inspectorName),
          TextCellValue(inspection.location),
          TextCellValue(inspection.shift),
          TextCellValue(inspection.overallStatus),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();

      final filePath =
          '${directory.path}/HSE_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final fileBytes = excel.save();

      if (fileBytes == null) {
        throw Exception('فایل اکسل تولید نشد');
      }

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'گزارش بازرسی HSE',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در تهیه خروجی اکسل: $error'),
        ),
      );
    }
  }

  Future<void> _openAssetList() async {
    await Navigator.pushNamed(context, '/assetList');

    if (!mounted) return;
    await _loadInspections();
  }

  Future<void> _confirmDelete(Inspection inspection) async {
    if (inspection.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف بازرسی'),
          content: const Text(
            'آیا از حذف این بازرسی و پاسخ‌های مربوط به آن اطمینان دارید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteInspection(inspection.id!);
    }
  }

  bool _isSafe(String status) {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus == 'ایمن' ||
        normalizedStatus == 'safe' ||
        normalizedStatus == 'pass';
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
          onPressed: _openAssetList,
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
      return RefreshIndicator(
        onRefresh: _loadInspections,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 240),
            Center(
              child: Text('هیچ موردی ثبت نشده است'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInspections,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _inspections.length,
        itemBuilder: (context, index) {
          final inspection = _inspections[index];
          final isSafe = _isSafe(inspection.overallStatus);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                isSafe ? Icons.check_circle : Icons.warning,
                color: isSafe ? Colors.green : Colors.red,
                size: 32,
              ),
              title: Text(
                'محل: ${inspection.location}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'بازرس: ${inspection.inspectorName}\n'
                'تاریخ: ${inspection.date} | '
                'شیفت: ${inspection.shift}\n'
                'وضعیت کلی: ${inspection.overallStatus}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                tooltip: 'حذف بازرسی',
                onPressed: () => _confirmDelete(inspection),
              ),
            ),
          );
        },
      ),
    );
  }
}
