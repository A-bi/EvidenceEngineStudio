import 'dart:io';

class BackendRuntime {
  final Directory root;
  final File analysisExecutable;
  final File datasetExecutable;
  final File? pythonExecutable;
  final File? analysisScript;
  final File? datasetScript;

  BackendRuntime({
    required this.root,
    required this.analysisExecutable,
    required this.datasetExecutable,
    this.pythonExecutable,
    this.analysisScript,
    this.datasetScript,
  });

  bool get hasBinaryBackend =>
      analysisExecutable.existsSync() && datasetExecutable.existsSync();

  bool get hasPythonFallback =>
      pythonExecutable != null &&
      pythonExecutable!.existsSync() &&
      analysisScript != null &&
      analysisScript!.existsSync() &&
      datasetScript != null &&
      datasetScript!.existsSync();
}

class BackendRuntimeService {
  BackendRuntimeService._();

  static final BackendRuntimeService instance = BackendRuntimeService._();

  String get _analysisBinaryName {
    if (Platform.isWindows) return 'analysis_backend.exe';
    return 'analysis_backend';
  }

  String get _datasetBinaryName {
    if (Platform.isWindows) return 'dataset_backend.exe';
    return 'dataset_backend';
  }

  String get _pythonName {
    if (Platform.isWindows) return 'python.exe';
    return 'python';
  }

  BackendRuntime findRuntime() {
    final candidates = _candidateRoots();

    for (final root in candidates) {
      final runtime = _runtimeForRoot(root);

      if (runtime.hasBinaryBackend || runtime.hasPythonFallback) {
        return runtime;
      }
    }

    throw Exception(
      'Backend not found. Expected bundled backend/bin executables next to the app, '
      'inside macOS Contents/Resources, or development backend with .venv.',
    );
  }

  List<Directory> _candidateRoots() {
    final candidates = <Directory>[];

    final envRoot = Platform.environment['EVIDENCE_ENGINE_STUDIO_ROOT'];
    if (envRoot != null && envRoot.trim().isNotEmpty) {
      candidates.add(Directory(envRoot));
    }

    candidates.add(Directory.current);

    final executable = File(Platform.resolvedExecutable);
    final executableDir = executable.parent;

    // Windows/Linux portable layout:
    // app.exe + backend/bin/... in same folder.
    candidates.add(executableDir);

    // macOS layout:
    // .app/Contents/MacOS/app
    // .app/Contents/Resources/backend/bin/...
    if (Platform.isMacOS) {
      final contentsDir = executableDir.parent;
      final resourcesDir = Directory('${contentsDir.path}/Resources');
      candidates.add(resourcesDir);
      candidates.add(contentsDir);
    }

    // One or two parent levels for packaged zip layouts.
    var dir = executableDir;
    for (var i = 0; i < 6; i++) {
      candidates.add(dir);
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }

    // Development fallback. This is okay for you, but not required for users.
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      candidates.addAll([
        Directory('$home/KI-Projekte/evidence_engine_studio_open'),
        Directory('$home/Documents/evidence_engine_studio_open'),
        Directory('$home/Downloads/evidence_engine_studio_open'),
        Directory('$home/evidence_engine_studio_open'),
      ]);
    }

    final unique = <String>{};
    return candidates.where((d) => unique.add(d.path)).toList();
  }

  BackendRuntime _runtimeForRoot(Directory root) {
    final analysisBinary = File(
      '${root.path}/backend/bin/$_analysisBinaryName',
    );

    final datasetBinary = File(
      '${root.path}/backend/bin/$_datasetBinaryName',
    );

    final pythonExecutable = File(
      '${root.path}/backend/.venv/bin/$_pythonName',
    );

    final windowsPythonExecutable = File(
      '${root.path}/backend/.venv/Scripts/$_pythonName',
    );

    final py = pythonExecutable.existsSync()
        ? pythonExecutable
        : windowsPythonExecutable.existsSync()
            ? windowsPythonExecutable
            : null;

    final analysisScript = File('${root.path}/backend/analysis_backend.py');
    final datasetScript = File('${root.path}/backend/dataset_backend.py');

    return BackendRuntime(
      root: root,
      analysisExecutable: analysisBinary,
      datasetExecutable: datasetBinary,
      pythonExecutable: py,
      analysisScript: analysisScript,
      datasetScript: datasetScript,
    );
  }
}
