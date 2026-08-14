class Inspection {
  final int? id;
  final String date;
  final String inspectorName;
  final String shift;
  final String unit;
  final String status; // مثلا 'ایمن' یا 'ناایمن'

  Inspection({
    this.id,
    required this.date,
    required this.inspectorName,
    required this.shift,
    required this.unit,
    required this.status,
  });

  // تبدیل به Map برای ذخیره در دیتابیس SQL
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'inspectorName': inspectorName,
      'shift': shift,
      'unit': unit,
      'status': status,
    };
  }

  // تبدیل از Map به مدل (زمان خواندن از دیتابیس)
  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'],
      date: map['date'],
      inspectorName: map['inspectorName'],
      shift: map['shift'],
      unit: map['unit'],
      status: map['status'],
    );
  }
}
