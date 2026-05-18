import 'package:uuid/uuid.dart';

class AnalysisHistoryItem {
  final String id;
  final DateTime timestamp;
  final String method;
  final String datasetName;
  final String outcome;
  final String secondaryVariable;
  final String summary;

  AnalysisHistoryItem({
    String? id,
    DateTime? timestamp,
    required this.method,
    required this.datasetName,
    required this.outcome,
    required this.secondaryVariable,
    required this.summary,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory AnalysisHistoryItem.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryItem(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.tryParse(json['timestamp'].toString()),
      method: json['method'] as String? ?? '',
      datasetName: json['datasetName'] as String? ?? '',
      outcome: json['outcome'] as String? ?? '',
      secondaryVariable: json['secondaryVariable'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'method': method,
      'datasetName': datasetName,
      'outcome': outcome,
      'secondaryVariable': secondaryVariable,
      'summary': summary,
    };
  }
}
