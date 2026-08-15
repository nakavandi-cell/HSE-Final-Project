class InspectionAnswer {
  final int? id;
  final int inspectionId;
  final int checklistItemId;
  final String result; // 'Pass', 'Fail'

  InspectionAnswer({this.id, required this.inspectionId, required this.checklistItemId, required this.result});

  Map<String, dynamic> toMap() => {'id': id, 'inspectionId': inspectionId, 'checklistItemId': checklistItemId, 'result': result};
}
