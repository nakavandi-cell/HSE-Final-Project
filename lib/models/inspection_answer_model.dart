class InspectionAnswer {
  final int? id;
  final int inspectionId;
  final int checklistItemId;
  final String result; // 'Pass', 'Fail', 'N/A'
  final String? comment;
  final String? photoPath;

  InspectionAnswer({
    this.id,
    required this.inspectionId,
    required this.checklistItemId,
    required this.result,
    this.comment,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'checklistItemId': checklistItemId,
      'result': result,
      'comment': comment,
      'photoPath': photoPath,
    };
  }

  factory InspectionAnswer.fromMap(Map<String, dynamic> map) {
    return InspectionAnswer(
      id: map['id'] as int?,
      inspectionId: map['inspectionId'] as int,
      checklistItemId: map['checklistItemId'] as int,
      result: map['result'] as String,
      comment: map['comment'] as String?,
      photoPath: map['photoPath'] as String?,
    );
  }
}
