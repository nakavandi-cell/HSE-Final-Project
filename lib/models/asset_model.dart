class Asset {
  final int? id;
  final String assetCode;
  final String name;
  final String type; // 'Extinguisher', 'Electrical Panel', 'Substation'
  final String location;

  Asset({
    this.id,
    required this.assetCode,
    required this.name,
    required this.type,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetCode': assetCode,
      'name': name,
      'type': type,
      'location': location,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      assetCode: map['assetCode'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      location: map['location'] as String,
    );
  }
}
