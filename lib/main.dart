import 'package:flutter/material.dart';
import 'screens/inspection_form_screen.dart'; // فرم ثبت
import 'screens/reports_screen.dart'; // صفحه گزارش‌ها

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        primarySwatch: Colors.teal, // رنگ اصلی اپلیکیشن را تغییر دادیم
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal, // رنگ نوار بالا
          foregroundColor: Colors.white, // رنگ آیکون‌ها و متن نوار بالا
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent, // رنگ دکمه شناور
        ),
        // تنظیم فونت فارسی در صورت نیاز
      ),
      // **صفحه اصلی اپلیکیشن را به ReportsScreen تغییر دادیم**
      home: const ReportsScreen(), 
      
      // **مسیردهی برای رفتن به صفحه فرم از صفحه گزارش‌ها**
      routes: {
        '/': (context) => const ReportsScreen(), // مسیر اصلی
        '/inspectionForm': (context) => const InspectionFormScreen(), // مسیر فرم ثبت
      },
    );
  }
}
