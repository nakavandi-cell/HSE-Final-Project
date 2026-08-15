class ChecklistItem {
  final int? id;
  final int checklistId;
  final String question;

  ChecklistItem({this.id, required this.checklistId, required this.question});

  Map<String, dynamic> toMap() => {'id': id, 'checklistId': checklistId, 'question': question};
}
