class DatasetSummary {
  final String? file;
  final int? rows;
  final int? columns;
  final List<String>? columnNames;
  final Map<String, String>? variableTypes;
  final Map<String, int>? missingCounts;
  final List<Map<String, dynamic>>? preview;
  final List<Map<String, dynamic>>? rowsData;
  final String? error;

  DatasetSummary({
    this.file,
    this.rows,
    this.columns,
    this.columnNames,
    this.variableTypes,
    this.missingCounts,
    this.preview,
    this.rowsData,
    this.error,
  });

  factory DatasetSummary.fromJson(Map<String, dynamic> json) {
    return DatasetSummary(
      file: json['file'] as String?,
      rows: json['rows'] as int?,
      columns: json['columns'] as int?,
      columnNames: (json['column_names'] as List?)?.map((e) => e.toString()).toList(),
      variableTypes: (json['variable_types'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      missingCounts: (json['missing_counts'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value is int ? value : int.tryParse('$value') ?? 0),
      ),
      preview: (json['preview'] as List?)
          ?.map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      rowsData: (json['rows_data'] as List?)
          ?.map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'rows': rows,
      'columns': columns,
      'column_names': columnNames,
      'variable_types': variableTypes,
      'missing_counts': missingCounts,
      'preview': preview,
      'rows_data': rowsData,
      'error': error,
    };
  }
}
