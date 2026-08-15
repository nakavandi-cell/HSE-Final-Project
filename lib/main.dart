import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // برای دسترسی به دیتابیس
import 'screens/asset_list_screen.dart'; // صفحه جدید برای نمایش دارایی‌ها
import 'screens/inspection_form_screen.dart'; // فرم فعلی ثبت بازرسی
import 'screens/reports_screen.dart';      // صفحه گزارش‌ها
import 'services/database_helper.dart';     // برای دسترسی به دیتابیس
import 'services/database_seeder.dart';     // برای پر کردن اولیه دیتابیس

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseHelper.instance.database;
  await DatabaseSeeder.seedData(db); // فراخوانی seeder برای پر کردن اولیه دیتابیس

  runApp(const HSEApp());
}

class HSEApp extends StatelessWidget {
  const HSEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HSE Inspection App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
        ),
      ),
      // صفحه اصلی برنامه را به AssetListScreen تغییر دادیم
      home: const AssetListScreen(), 
      routes: {
        // مسیرهای احتمالی دیگر
        '/assetList': (context) => const AssetListScreen(),
        '/inspectionForm': (context) => const InspectionFormScreen(), // فعلا فرم بازرسی اصلی
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}
