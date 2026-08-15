class Asset {
  final int? id;
  final String assetCode;
  final String name;
  final String type; // 'Fire', 'Panel', 'Substation'
  final String location;

  Asset({this.id, required this.assetCode, required this.name, required this.type, required this.location});

  Map<String, dynamic> toMap() => {'id': id, 'assetCode': assetCode, 'name': name, 'type': type, 'location': location};
}
