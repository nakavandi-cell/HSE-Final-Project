class Inspection {
  final int? id;
  final int assetId;
  final String date;
  final String inspectorName;
  final String location;
  final String shift;
  final String overallStatus;

  Inspection({
    this.id,
    required this.assetId,
    required this.date,
    required this.inspectorName,
    required this.location,
    required this.shift,
    required this.overallStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetId': assetId,
      'date': date,
      'inspectorName': inspectorName,
      'location': location,
      'shift': shift,
      'overallStatus': overallStatus,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      assetId: map['assetId'] as int,
      date: map['date'] as String,
      inspectorName: map['inspectorName'] as String,
      location: map['location'] as String? ?? '',
      shift: map['shift'] as String? ?? '',
      overallStatus: map['overallStatus'] as String,
    );
  }
}
