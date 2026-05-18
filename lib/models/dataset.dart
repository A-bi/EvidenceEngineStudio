import 'package:uuid/uuid.dart';

class Dataset {
  final String id;
  String name;
  int rows;
  int columns;
  String source;
  String? filePath;

  Dataset({
    String? id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.source,
    this.filePath,
  }) : id = id ?? const Uuid().v4();

  factory Dataset.fromJson(Map<String, dynamic> json) {
    return Dataset(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      rows: json['rows'] as int? ?? 0,
      columns: json['columns'] as int? ?? 0,
      source: json['source'] as String? ?? '',
      filePath: json['filePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rows': rows,
      'columns': columns,
      'source': source,
      'filePath': filePath,
    };
  }
}
