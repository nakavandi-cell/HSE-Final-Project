import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/asset_model.dart';
import '../services/database_helper.dart';
import 'inspection_form_screen.dart'; // فرم ثبت بازرسی

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  late Future<List<Asset>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    _assetsFuture = _loadAssets();
  }

  Future<List<Asset>> _loadAssets() async {
    final db = DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await (await db).query('assets');
    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست دارایی‌ها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement navigation to add new asset screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اضافه کردن دارایی جدید به زودی فعال می‌شود.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment), // آیکون برای گزارش‌ها
            onPressed: () {
              Navigator.pushNamed(context, '/reports');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Asset>>(
        future: _assetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('خطا در بارگذاری دارایی‌ها: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('هیچ دارایی ثبت نشده است.'));
          } else {
            final assets = snapshot.data!;
            return ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return ListTile(
                  leading: Icon(_getAssetIcon(asset.type)), // آیکون مناسب هر نوع دارایی
                  title: Text('(${asset.assetCode}) ${asset.name}'),
                  subtitle: Text('${asset.location} - ${asset.type}'),
                  onTap: () {
                    // وقتی روی دارایی کلیک می‌شود، به صفحه فرم بازرسی می‌رود
                    // فعلا فقط نام دارایی را به فرم می‌فرستیم. بعداً Asset ID را می‌فرستیم.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectionFormScreen(assetName: asset.name, assetType: asset.type, assetId: asset.id!),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // TODO: Add functionality to navigate to a screen for adding new assets
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('اضافه کردن دارایی جدید به زودی فعال می‌شود.')),
           );
        },
        child: const Icon(Icons.add),
        tooltip: 'اضافه کردن دارایی جدید',
      ),
    );
  }

  // تابع کمکی برای نمایش آیکون مناسب بر اساس نوع دارایی
  IconData _getAssetIcon(String type) {
    switch (type) {
      case 'Fire':
        return Icons.fire_extinguisher;
      case 'Panel':
        return Icons.electrical_services;
      case 'Substation':
        return Icons.power;
      default:
        return Icons.devices;
    }
  }
}
