import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/dataset.dart';
import '../models/dataset_summary.dart';

class DatasetImportResult {
  final Dataset dataset;
  final DatasetSummary summary;

  DatasetImportResult({required this.dataset, required this.summary});
}

class DatasetImportService {
  DatasetImportService._();

  static final DatasetImportService instance = DatasetImportService._();

  static const supportedExtensions = [
    'csv',
    'txt',
    'tsv',
    'json',
    'xlsx',
    'xls',
    'sqlite',
    'db',
    'parquet',
    'sav',
    'dta',
    'accdb',
    'mdb',
  ];

  Directory _projectRoot() {
    final envRoot = Platform.environment['EVIDENCE_ENGINE_STUDIO_ROOT'];

    final candidates = <Directory>[
      if (envRoot != null && envRoot.trim().isNotEmpty) Directory(envRoot),
      Directory.current,
    ];

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    if (home != null) {
      candidates.addAll([
        Directory('$home/KI-Projekte/evidence_engine_studio_open'),
        Directory('$home/Documents/evidence_engine_studio_open'),
        Directory('$home/Downloads/evidence_engine_studio_open'),
        Directory('$home/evidence_engine_studio_open'),
      ]);
    }

    var dir = File(Platform.resolvedExecutable).parent;

    for (var i = 0; i < 10; i++) {
      candidates.add(dir);
      candidates.add(Directory('${dir.path}/Resources'));
      candidates.add(Directory('${dir.path}/../Resources'));

      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }

    for (final candidate in candidates) {
      final binary = File('${candidate.path}/backend/bin/dataset_backend');
      final script = File('${candidate.path}/backend/dataset_backend.py');

      if (binary.existsSync() || script.existsSync()) {
        return candidate;
      }
    }

    throw Exception(
      'Could not find EvidenceEngineStudioOpen dataset backend. '
      'Set EVIDENCE_ENGINE_STUDIO_ROOT to the app/project folder or bundle backend with the app.',
    );
  }

  Future<DatasetImportResult> importDataset(String path) async {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');

    if (!supportedExtensions.contains(ext)) {
      throw Exception('Unsupported file type: .$ext');
    }

    final root = _projectRoot();

    final binary = File('${root.path}/backend/bin/dataset_backend');
    final python = File('${root.path}/backend/.venv/bin/python');
    final script = File('${root.path}/backend/dataset_backend.py');

    late final ProcessResult process;

    if (binary.existsSync()) {
      process = await Process.run(binary.path, [
        '--file',
        path,
      ], workingDirectory: root.path);
    } else {
      if (!python.existsSync()) {
        throw Exception(
          'No backend runtime found. Expected either backend/bin/dataset_backend or backend/.venv/bin/python.',
        );
      }

      if (!script.existsSync()) {
        throw Exception('dataset_backend.py not found.');
      }

      process = await Process.run(python.path, [
        script.path,
        '--file',
        path,
      ], workingDirectory: root.path);
    }

    if (process.exitCode != 0) {
      throw Exception(
        'Dataset backend failed.\nSTDERR:\n${process.stderr}\nSTDOUT:\n${process.stdout}',
      );
    }

    final raw = process.stdout.toString().trim();

    if (raw.isEmpty) {
      throw Exception('Dataset backend returned empty output.');
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    if (decoded['ok'] != true) {
      throw Exception(decoded['error']?.toString() ?? 'Dataset import failed.');
    }

    final rows = (decoded['rows'] as num?)?.toInt() ?? 0;
    final columns = (decoded['columns'] as num?)?.toInt() ?? 0;
    final source = decoded['source']?.toString() ?? ext.toUpperCase();

    final dataset = Dataset(
      name: p.basename(path),
      rows: rows,
      columns: columns,
      source: source,
      filePath: path,
    );

    final summary = DatasetSummary(
      file: decoded['file']?.toString() ?? path,
      rows: rows,
      columns: columns,
      columnNames: (decoded['column_names'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      variableTypes: (decoded['variable_types'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      missingCounts: (decoded['missing_counts'] as Map? ?? {}).map((
        key,
        value,
      ) {
        final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
        return MapEntry(key.toString(), n);
      }),
      preview: (decoded['preview'] as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(),
      rowsData: null,
    );

    return DatasetImportResult(dataset: dataset, summary: summary);
  }
}
