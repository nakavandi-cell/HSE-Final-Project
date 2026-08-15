class Checklist {
  final int? id;
  final String title;
  final String assetType;

  Checklist({this.id, required this.title, required this.assetType});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'assetType': assetType};
}
