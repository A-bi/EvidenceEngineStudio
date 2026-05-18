import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ExportFileItem {
  final String name;
  final String path;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedAt;

  ExportFileItem({
    required this.name,
    required this.path,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}

class ExportLibraryService {
  ExportLibraryService._();

  static final ExportLibraryService instance = ExportLibraryService._();

  Future<Directory> exportDirectory({String? customPath}) async {
    if (customPath != null && customPath.trim().isNotEmpty) {
      final dir = Directory(customPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/EvidenceEngineStudioOpen/Exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  Future<List<ExportFileItem>> listExports({String? customPath}) async {
    final dir = await exportDirectory(customPath: customPath);

    final files = await dir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .toList();

    final items = <ExportFileItem>[];

    for (final file in files) {
      final stat = await file.stat();
      final name = file.uri.pathSegments.isEmpty
          ? file.path
          : file.uri.pathSegments.last;

      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

      items.add(
        ExportFileItem(
          name: name,
          path: file.path,
          extension: ext,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }

    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return items;
  }

  Future<void> openFile(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
      return;
    }

    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
      return;
    }

    await Process.run('xdg-open', [path]);
  }

  Future<void> openExportFolder({String? customPath}) async {
    final dir = await exportDirectory(customPath: customPath);
    await openFile(dir.path);
  }

  Future<void> deleteExport(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}
