    import 'package:flutter/material.dart';
    import 'package:excel/excel.dart'; // پکیج اکسل
    import 'package:path_provider/path_provider.dart'; // برای گرفتن مسیر ذخیره فایل
    import 'package:share_plus/share_plus.dart'; // برای اشتراک‌گذاری فایل
    import 'dart:io'; // برای کار با فایل‌ها
    import 'package:intl/intl.dart'; // برای فرمت تاریخ

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
        setState(() {
          _isLoading = true;
        });
        try {
          // دریافت همه بازرسی‌ها از دیتابیس
          _inspections = await DatabaseHelper.instance.getAllInspections();
        } catch (error) {
          // نمایش خطا در صورت بروز مشکل در بارگذاری
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در بارگذاری بازرسی‌ها: $error'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          // پایان بارگذاری، چه موفق چه ناموفق
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }

      // تابع برای ایجاد و اشتراک‌گذاری فایل اکسل
      Future<void> _exportToExcel() async {
        if (_inspections.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('هیچ بازرسی برای خروجی گرفتن وجود ندارد.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // ایجاد یک فایل اکسل جدید
        var excel = Excel.createExcel();
        Sheet sheet = excel[excel.getDefaultSheet()!];

        // اضافه کردن هدرها (عنوان ستون‌ها)
        sheet.appendRow([
          'شناسه',
          'تاریخ',
          'نام بازرس',
          'شیفت',
          'واحد',
          'وضعیت',
        ]);

        // اضافه کردن داده‌های بازرسی‌ها به شیت
        for (var inspection in _inspections) {
          sheet.appendRow([
            inspection.id.toString(),
            inspection.date,
            inspection.inspectorName,
            inspection.shift,
            inspection.unit,
            inspection.status,
          ]);
        }

        try {
          // گرفتن مسیر موقت برای ذخیره فایل
          final directory = await getTemporaryDirectory();
          final String fileName =
              'HSE_Inspections_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
          final String filePath = '${directory.path}/$fileName';

          // ذخیره فایل اکسل
          final fileBytes = excel.save();
          final file = File(filePath);
          await file.writeAsBytes(fileBytes!);

          // اشتراک‌گذاری فایل با استفاده از پکیج share_plus
          await Share.shareXFiles(
            [XFile(filePath, name: fileName)],
            text: 'فایل اکسل گزارش بازرسی‌های HSE:',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فایل اکسل با موفقیت ایجاد و برای اشتراک‌گذاری آماده شد: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ایجاد یا اشتراک‌گذاری فایل اکسل: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('گزارش بازرسی‌های HSE'),
            centerTitle: true,
            actions: [
              // دکمه خروجی اکسل در نوار بالا
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'خروجی اکسل',
                onPressed: _exportToExcel,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Directionality(
            textDirection: TextDirection.rtl, // برای راست به چپ شدن متن‌ها
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(), // نمایش چرخش هنگام بارگذاری
                  )
                : _inspections.isEmpty
                    ? const Center(
                        child: Text('هیچ بازرسی ثبت نشده است.'),
                      )
                    : ListView.builder(
                        // ساخت لیست بازرسی‌ها
                        itemCount: _inspections.length,
                        itemBuilder: (context, index) {
                          final inspection = _inspections[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text('واحد: ${inspection.unit} - ${inspection.status}'),
                              subtitle: Text(
                                  'بازرس: ${inspection.inspectorName} | تاریخ: ${inspection.date}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'حذف بازرسی',
                                onPressed: () async {
                                  // نمایش دیالوگ تایید قبل از حذف
                                  final bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('تایید حذف'),
                                        content: const Text(
                                            'آیا از حذف این بازرسی اطمینان دارید؟'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                            child: const Text('خیر'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('بله'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmDelete == true) {
                                    await _deleteInspection(inspection.id!);
                                  }
                                },
                              ),
                              // شما می‌توانید با زدن روی هر آیتم، جزئیات بیشتری را نمایش دهید
                              onTap: () {
                                // فعلاً کاری انجام نمی‌دهیم، اما می‌توانید در آینده جزئیات را نشان دهید
                                print('Tapped on inspection: ${inspection.id}');
                              },
                            ),
                          );
                        },
                      ),
          ),
          // دکمه شناور برای رفتن به صفحه فرم ثبت بازرسی
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // رفتن به صفحه فرم و منتظر ماندن برای نتیجه (مثلاً اگر بعد از ثبت، بخواهیم لیست را دوباره بارگذاری کنیم)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InspectionFormScreen(),
                ),
              ).then((result) {
                // اگر نتیجه‌ای برگشت (مثلاً فرم ثبت را کامل کردیم و برگشتیم)
                // لیست را دوباره بارگذاری کن تا مورد جدید نمایش داده شود
                if (result != null && result) {
                  _loadInspections();
                }
              });
            },
            tooltip: 'ثبت بازرسی جدید',
            child: const Icon(Icons.add),
          ),
        );
      }

      // تابع حذف بازرسی از دیتابیس
      Future<void> _deleteInspection(int id) async {
        try {
          await DatabaseHelper.instance.deleteInspection(id);
          // بعد از حذف، لیست را دوباره بارگذاری کن
          _loadInspections();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بازرسی با موفقیت حذف شد.'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در حذف بازرسی: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
