import 'dart:convert';
import 'dart:io';

import '../models/analysis_result.dart';
import 'analysis_service.dart';

class PythonAnalysisService {
  PythonAnalysisService._();

  static final PythonAnalysisService instance = PythonAnalysisService._();

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
      final binary = File('${candidate.path}/backend/bin/analysis_backend');
      final script = File('${candidate.path}/backend/analysis_backend.py');

      if (binary.existsSync() || script.existsSync()) {
        return candidate;
      }
    }

    throw Exception(
      'Could not find EvidenceEngineStudioOpen analysis backend. '
      'Set EVIDENCE_ENGINE_STUDIO_ROOT to the app/project folder or bundle backend with the app.',
    );
  }

  Future<AnalysisResult> run({
    required String filePath,
    required AnalysisMethod method,
    required String outcome,
    String? predictor,
    String? group,
  }) async {
    final root = _projectRoot();

    final binary = File('${root.path}/backend/bin/analysis_backend');
    final python = File('${root.path}/backend/.venv/bin/python');
    final script = File('${root.path}/backend/analysis_backend.py');

    final args = [
      '--file',
      filePath,
      '--method',
      method.name,
      '--outcome',
      outcome,
      if (predictor != null && predictor.isNotEmpty) ...[
        '--predictor',
        predictor,
      ],
      if (group != null && group.isNotEmpty) ...['--group', group],
    ];

    late final ProcessResult process;

    if (binary.existsSync()) {
      process = await Process.run(
        binary.path,
        args,
        workingDirectory: root.path,
      );
    } else {
      if (!python.existsSync()) {
        throw Exception(
          'No backend runtime found. Expected either backend/bin/analysis_backend or backend/.venv/bin/python.',
        );
      }

      if (!script.existsSync()) {
        throw Exception('analysis_backend.py not found.');
      }

      process = await Process.run(python.path, [
        script.path,
        ...args,
      ], workingDirectory: root.path);
    }

    if (process.exitCode != 0) {
      throw Exception(
        'Analysis backend failed.\n'
        'STDERR:\n${process.stderr}\n'
        'STDOUT:\n${process.stdout}',
      );
    }

    final raw = process.stdout.toString().trim();

    if (raw.isEmpty) {
      throw Exception('Analysis backend returned empty output.');
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    if (decoded['ok'] != true) {
      return AnalysisResult(
        analysis: decoded['analysis']?.toString() ?? method.label,
        outcome: outcome,
        predictor: predictor,
        group: group,
        n: 0,
        interpretation:
            decoded['interpretation']?.toString() ?? 'Analysis failed.',
        error: decoded['error']?.toString(),
      );
    }

    return AnalysisResult(
      analysis: decoded['analysis']?.toString() ?? method.label,
      outcome: decoded['outcome']?.toString(),
      predictor: decoded['predictor']?.toString(),
      group: decoded['group']?.toString(),
      n: (decoded['n'] as num?)?.toInt() ?? 0,
      metrics: _doubleMap(decoded['metrics']),
      categoryCounts: _intMap(decoded['category_counts']),
      chartKind: 'image',
      chartPoints: const [],
      plotPath: decoded['plot_path']?.toString(),
      interpretation: decoded['interpretation']?.toString() ?? '',
      warning: decoded['warning']?.toString(),
      error: decoded['error']?.toString(),
    );
  }

  static Map<String, double>? _doubleMap(dynamic value) {
    if (value is! Map) return null;

    return value.map((key, val) {
      double number;

      if (val is num) {
        number = val.toDouble();
      } else if (val == 'inf' || val == 'Infinity' || val == '∞') {
        number = double.infinity;
      } else {
        number = double.tryParse('$val') ?? 0.0;
      }

      return MapEntry(key.toString(), number);
    });
  }

  static Map<String, int>? _intMap(dynamic value) {
    if (value is! Map) return null;

    return value.map((key, val) {
      final number = val is num ? val.toInt() : int.tryParse('$val') ?? 0;
      return MapEntry(key.toString(), number);
    });
  }
}
