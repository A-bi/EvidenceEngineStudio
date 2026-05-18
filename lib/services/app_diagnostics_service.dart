import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDiagnostics {
  final String executablePath;
  final String currentDirectory;
  final String documentsDirectory;
  final String? backendRoot;
  final bool analysisBinaryFound;
  final bool datasetBinaryFound;
  final bool pythonVenvFound;
  final bool analysisScriptFound;
  final bool datasetScriptFound;

  AppDiagnostics({
    required this.executablePath,
    required this.currentDirectory,
    required this.documentsDirectory,
    required this.backendRoot,
    required this.analysisBinaryFound,
    required this.datasetBinaryFound,
    required this.pythonVenvFound,
    required this.analysisScriptFound,
    required this.datasetScriptFound,
  });

  bool get backendUsable {
    final binaryMode = analysisBinaryFound && datasetBinaryFound;
    final pythonMode =
        pythonVenvFound && analysisScriptFound && datasetScriptFound;
    return binaryMode || pythonMode;
  }

  String get backendMode {
    if (analysisBinaryFound && datasetBinaryFound)
      return 'Bundled binary backend';
    if (pythonVenvFound && analysisScriptFound && datasetScriptFound)
      return 'Development Python backend';
    return 'Backend incomplete';
  }
}

class AppDiagnosticsService {
  AppDiagnosticsService._();

  static final AppDiagnosticsService instance = AppDiagnosticsService._();

  Future<AppDiagnostics> inspect() async {
    final documents = await getApplicationDocumentsDirectory();

    final root = _findBackendRoot();

    final analysisBinary = root == null
        ? false
        : File('${root.path}/backend/bin/analysis_backend').existsSync();

    final datasetBinary = root == null
        ? false
        : File('${root.path}/backend/bin/dataset_backend').existsSync();

    final pythonVenv = root == null
        ? false
        : File('${root.path}/backend/.venv/bin/python').existsSync();

    final analysisScript = root == null
        ? false
        : File('${root.path}/backend/analysis_backend.py').existsSync();

    final datasetScript = root == null
        ? false
        : File('${root.path}/backend/dataset_backend.py').existsSync();

    return AppDiagnostics(
      executablePath: Platform.resolvedExecutable,
      currentDirectory: Directory.current.path,
      documentsDirectory: documents.path,
      backendRoot: root?.path,
      analysisBinaryFound: analysisBinary,
      datasetBinaryFound: datasetBinary,
      pythonVenvFound: pythonVenv,
      analysisScriptFound: analysisScript,
      datasetScriptFound: datasetScript,
    );
  }

  Directory? _findBackendRoot() {
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
      final analysisBinary = File(
        '${candidate.path}/backend/bin/analysis_backend',
      );
      final datasetBinary = File(
        '${candidate.path}/backend/bin/dataset_backend',
      );
      final analysisScript = File(
        '${candidate.path}/backend/analysis_backend.py',
      );
      final datasetScript = File(
        '${candidate.path}/backend/dataset_backend.py',
      );

      if (analysisBinary.existsSync() ||
          datasetBinary.existsSync() ||
          analysisScript.existsSync() ||
          datasetScript.existsSync()) {
        return candidate;
      }
    }

    return null;
  }
}
