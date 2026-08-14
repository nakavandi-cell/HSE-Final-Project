import 'package:flutter/material.dart';
import 'screens/inspection_form_screen.dart';

void main() {
  // این خط برای اطمینان از مقداردهی اولیه پلاگین‌ها (مثل دیتابیس) است
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // تنظیم فونت یا تم‌های فارسی در صورت نیاز در اینجا انجام می‌شود
      ),
      // تعیین صفحه اصلی اپلیکیشن
      home: const InspectionFormScreen(),
    );
  }
}
