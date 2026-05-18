import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_snapshot.dart';

class AppPersistenceService {
  AppPersistenceService._();

  static final AppPersistenceService instance = AppPersistenceService._();

  Future<File> _snapshotFile() async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/EvidenceEngineStudioOpen');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return File('${folder.path}/app_snapshot.json');
  }

  Future<void> save(AppSnapshot snapshot) async {
    final file = await _snapshotFile();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(snapshot.toJson()));
  }

  Future<AppSnapshot?> load() async {
    final file = await _snapshotFile();

    if (!await file.exists()) {
      return null;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> reset() async {
    final file = await _snapshotFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
