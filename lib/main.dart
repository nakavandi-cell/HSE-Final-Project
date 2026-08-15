import 'package:flutter/material.dart';
import 'screens/asset_list_screen.dart';
import 'screens/inspection_form_screen.dart';
import 'screens/reports_screen.dart';
import 'services/database_helper.dart';
import 'services/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // آماده‌سازی دیتابیس
  final db = await DatabaseHelper.instance.database;
  await DatabaseSeeder.seedData(db);

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
      home: const AssetListScreen(),
      routes: {
        '/assetList': (context) => const AssetListScreen(),
        '/inspectionForm': (context) => const InspectionFormScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}
