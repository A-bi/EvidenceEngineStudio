class InspectedFile {
  final String id;
  final String name;
  final String path;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String preview;
  final String role;

  InspectedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedAt,
    this.preview = '',
    this.role = 'General file',
  });

  factory InspectedFile.fromJson(Map<String, dynamic> json) {
    return InspectedFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      extension: json['extension'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      modifiedAt: DateTime.tryParse(json['modifiedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      preview: json['preview'] as String? ?? '',
      role: json['role'] as String? ?? 'General file',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'modifiedAt': modifiedAt.toIso8601String(),
      'preview': preview,
      'role': role,
    };
  }
}
