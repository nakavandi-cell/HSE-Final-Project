class ChecklistItem {
  final int? id;
  final int checklistId;
  final String question;

  ChecklistItem({
    this.id,
    required this.checklistId,
    required this.question,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'checklistId': checklistId,
      'question': question,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as int?,
      checklistId: map['checklistId'] as int,
      question: map['question'] as String,
    );
  }
}
