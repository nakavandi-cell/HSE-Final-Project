import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../services/database_helper.dart';
import 'inspection_form_screen.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بارگذاری مجدد لیست هنگام بازگشت از صفحه‌های دیگر
    _assetsFuture = _loadAssets();
  }

  Future<List<Asset>> _loadAssets() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('assets');
    return List.generate(maps.length, (i) {
      return Asset.fromMap(maps[i]);
    });
  }

  Future<void> _openInspectionForm(Asset asset) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionFormScreen(
          assetId: asset.id!,
          assetName: asset.name,
          assetType: asset.type,
        ),
      ),
    );

    // بعد از بازگشت از فرم، لیست را به‌روزرسانی می‌کنیم
    if (mounted) {
      setState(() {
        _assetsFuture = _loadAssets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لیست تجهیزات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: 'گزارش‌های بازرسی',
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
              return Center(
                child: Text('خطا در بارگذاری تجهیزات: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('هیچ تجهیزی ثبت نشده است.'));
            } else {
              final assets = snapshot.data!;
              return ListView.builder(
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getAssetIcon(asset.type),
                        size: 32,
                        color: Colors.teal,
                      ),
                      title: Text(
                        '(${asset.assetCode}) ${asset.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${asset.location} - ${asset.type}',
                      ),
                      onTap: () => _openInspectionForm(asset),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  IconData _getAssetIcon(String type) {
    switch (type) {
      case 'Extinguisher':
        return Icons.fire_extinguisher;
      case 'Electrical Panel':
        return Icons.electrical_services;
      case 'Substation':
        return Icons.power;
      default:
        return Icons.devices;
    }
  }
}
