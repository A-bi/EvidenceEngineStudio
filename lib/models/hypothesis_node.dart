import 'package:uuid/uuid.dart';

class HypothesisNode {
  final String id;
  String? projectId;
  String title;
  String evidenceStrength;
  String status;

  HypothesisNode({
    String? id,
    this.projectId,
    required this.title,
    required this.evidenceStrength,
    this.status = 'Open',
  }) : id = id ?? const Uuid().v4();

  factory HypothesisNode.fromJson(Map<String, dynamic> json) {
    return HypothesisNode(
      id: json['id'] as String?,
      projectId: json['projectId'] as String?,
      title: json['title'] as String? ?? '',
      evidenceStrength: json['evidenceStrength'] as String? ?? 'Open',
      status: json['status'] as String? ?? 'Open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'evidenceStrength': evidenceStrength,
      'status': status,
    };
  }
}
