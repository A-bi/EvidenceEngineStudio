import 'package:uuid/uuid.dart';

class Project {
  final String id;
  String title;
  String question;
  String status;
  int datasetCount;
  int evidenceCount;
  int hypothesisCount;
  String notes;

  Project({
    String? id,
    required this.title,
    required this.question,
    required this.status,
    required this.datasetCount,
    required this.evidenceCount,
    this.hypothesisCount = 0,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      datasetCount: json['datasetCount'] as int? ?? 0,
      evidenceCount: json['evidenceCount'] as int? ?? 0,
      hypothesisCount: json['hypothesisCount'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'status': status,
      'datasetCount': datasetCount,
      'evidenceCount': evidenceCount,
      'hypothesisCount': hypothesisCount,
      'notes': notes,
    };
  }
}
