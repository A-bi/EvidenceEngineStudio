import 'dart:io';

import 'package:path_provider/path_provider.dart';

class BibTeXEntry {
  final String key;
  final String entry;

  BibTeXEntry({
    required this.key,
    required this.entry,
  });
}

class BibTeXService {
  BibTeXService._();

  static final BibTeXService instance = BibTeXService._();

  BibTeXEntry makeBibTeXEntry({
    required String title,
    required String authors,
    required String journal,
    required int year,
    String? doi,
    String? url,
  }) {
    final firstAuthorToken = authors
        .split(RegExp(r'[, ]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .firstOrNull ??
        'paper';

    final key = '$firstAuthorToken$year';

    final entry = '''
@article{$key,
  title = {${_escape(title)}},
  author = {${_escape(authors)}},
  journal = {${_escape(journal)}},
  year = {$year},
  doi = {${_escape(doi ?? '')}},
  url = {${_escape(url ?? '')}}
}
''';

    return BibTeXEntry(key: key, entry: entry);
  }

  Future<void> appendEntry(
    String entry, {
    required String? projectName,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final bibDir = Directory('${dir.path}/EvidenceEngineStudioOpen/BibTeX');

    if (!await bibDir.exists()) {
      await bibDir.create(recursive: true);
    }

    final safeName = (projectName == null || projectName.trim().isEmpty
            ? 'references'
            : projectName)
        .replaceAll('/', '_')
        .replaceAll(':', '_');

    final file = File('${bibDir.path}/$safeName.bib');

    final existing = await file.exists() ? await file.readAsString() : '';
    final updated = existing.trim().isEmpty
        ? '$entry\n'
        : '${existing.trim()}\n\n$entry\n';

    await file.writeAsString(updated);
  }

  String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
