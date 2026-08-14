import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import '../services/database_helper.dart';

class InspectionFormScreen extends StatefulWidget {
  const InspectionFormScreen({super.key});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _inspectorNameController = TextEditingController();
  
  String? _selectedShift;
  String? _selectedUnit;
  String? _selectedStatus;
  bool _isSaving = false;

  final List<String> _shifts = [
    'صبح',
    'عصر',
    'شب',
  ];

  final List<String> _units = [
    'تولید',
    'تأسیسات',
    'انبار',
    'آزمایشگاه',
    'اداری',
  ];

  final List<String> _statuses = [
    'ایمن',
    'نیازمند اصلاح',
    'ناایمن',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveInspection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final inspection = Inspection(
        date: _dateController.text.trim(),
        inspectorName: _inspectorNameController.text.trim(),
        shift: _selectedShift!,
        unit: _selectedUnit!,
        status: _selectedStatus!,
      );

      await DatabaseHelper.instance.insertInspection(inspection);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اطلاعات بازرسی با موفقیت ثبت شد.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _clearForm();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت اطلاعات: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearForm() {
    _inspectorNameController.clear();
    setState(() {
      _selectedShift = null;
      _selectedUnit = null;
      _selectedStatus = null;
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _inspectorNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت بازرسی HSE'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'تاریخ',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _inspectorNameController,
                    decoration: const InputDecoration(
                      labelText: 'نام بازرس',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفاً نام بازرس را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedShift,
                    decoration: const InputDecoration(
                      labelText: 'شیفت',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    items: _shifts.map((shift) {
                      return DropdownMenuItem<String>(
                        value: shift,
                        child: Text(shift),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedShift = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'لطفاً شیفت را انتخاب کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'واحد',
                      prefixIcon: Icon(Icons.factory),
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'لطفاً واحد مورد نظر را انتخاب کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'وضعیت بازرسی',
                      prefixIcon: Icon(Icons.health_and_safety),
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'لطفاً وضعیت بازرسی را انتخاب کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveInspection,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving ? 'در حال ثبت...' : 'ثبت اطلاعات',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
