import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/analysis_history_item.dart';
import '../models/dataset.dart';
import '../models/evidence_paper.dart';
import '../models/manuscript.dart';
import '../models/project.dart';

class ManuscriptExportService {
  ManuscriptExportService._();

  static final ManuscriptExportService instance = ManuscriptExportService._();

  Future<File> exportMarkdown({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final dir = await _exportDir(exportDirectoryPath: exportDirectoryPath);
    final file = File(
      '${dir.path}/${_safeFileName(_title(manuscript, project))}.md',
    );

    await file.writeAsString(
      _buildMarkdown(manuscript, project, dataset, papers, analyses),
    );

    return file;
  }

  Future<File> exportText({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final dir = await _exportDir(exportDirectoryPath: exportDirectoryPath);
    final file = File(
      '${dir.path}/${_safeFileName(_title(manuscript, project))}.txt',
    );

    final markdown = _buildMarkdown(
      manuscript,
      project,
      dataset,
      papers,
      analyses,
    );

    final text = markdown
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll('**', '')
        .replaceAll('_', '')
        .replaceAll(r'$$', '')
        .replaceAll(RegExp(r'\[@([^\]]+)\]'), r'($1)');

    await file.writeAsString(text);
    return file;
  }

  Future<File> exportRMarkdown({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final dir = await _exportDir(exportDirectoryPath: exportDirectoryPath);
    final file = File(
      '${dir.path}/${_safeFileName(_title(manuscript, project))}.Rmd',
    );

    final buffer = StringBuffer();

    buffer.writeln('---');
    buffer.writeln('title: "${_yamlEscape(_title(manuscript, project))}"');
    buffer.writeln('author: "${_yamlEscape(manuscript.authors)}"');
    buffer.writeln('date: "`r Sys.Date()`"');
    buffer.writeln('output:');
    buffer.writeln('  html_document: default');
    buffer.writeln('  pdf_document: default');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('```{r setup, include=FALSE}');
    buffer.writeln(
      r'knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)',
    );
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln(
      _buildMarkdown(manuscript, project, dataset, papers, analyses),
    );
    buffer.writeln();
    buffer.writeln('```{r session-info}');
    buffer.writeln('sessionInfo()');
    buffer.writeln('```');

    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<File> exportLatex({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final dir = await _exportDir(exportDirectoryPath: exportDirectoryPath);
    final file = File(
      '${dir.path}/${_safeFileName(_title(manuscript, project))}.tex',
    );

    final buffer = StringBuffer();

    buffer.writeln(r'\documentclass[11pt]{article}');
    buffer.writeln(r'\usepackage[utf8]{inputenc}');
    buffer.writeln(r'\usepackage{fontspec}');
    buffer.writeln(r'\usepackage{amsmath}');
    buffer.writeln(r'\usepackage{graphicx}');
    buffer.writeln(r'\usepackage{hyperref}');
    buffer.writeln(r'\usepackage{booktabs}');
    buffer.writeln(r'\usepackage{setspace}');
    buffer.writeln(r'\usepackage{lineno}');
    buffer.writeln(r'\usepackage[margin=1in]{geometry}');
    buffer.writeln(r'\setmainfont{' + manuscript.format.fontFamily + '}');
    buffer.writeln();

    buffer.writeln(
      r'\title{' + _latexEscape(_title(manuscript, project)) + '}',
    );
    buffer.writeln(r'\author{' + _latexEscape(manuscript.authors) + '}');
    buffer.writeln(r'\date{\today}');
    buffer.writeln(r'\begin{document}');

    if (manuscript.format.lineSpacing >= 1.9) {
      buffer.writeln(r'\doublespacing');
    } else if (manuscript.format.lineSpacing >= 1.4) {
      buffer.writeln(r'\onehalfspacing');
    } else {
      buffer.writeln(r'\singlespacing');
    }

    if (manuscript.format.includeLineNumbers) {
      buffer.writeln(r'\linenumbers');
    }

    buffer.writeln(r'\maketitle');
    buffer.writeln();

    if (manuscript.abstractText.trim().isNotEmpty) {
      buffer.writeln(r'\begin{abstract}');
      buffer.writeln(_latexEscape(manuscript.abstractText.trim()));
      buffer.writeln(r'\end{abstract}');
      buffer.writeln();
    }

    if (manuscript.keywords.trim().isNotEmpty) {
      buffer.writeln(
        r'\noindent\textbf{Keywords:} ' + _latexEscape(manuscript.keywords),
      );
      buffer.writeln();
    }

    for (final section in manuscript.sections) {
      if (section.id == 'title_page' ||
          section.id == 'abstract' ||
          section.id == 'keywords') {
        continue;
      }

      buffer.writeln(r'\section{' + _latexEscape(section.title) + '}');
      buffer.writeln(
        _convertMarkdownishToLatex(
          section.content.trim().isEmpty
              ? 'To be written.'
              : section.content.trim(),
        ),
      );
      buffer.writeln();
    }

    if (manuscript.formulas.isNotEmpty) {
      buffer.writeln(r'\section{Formulas}');
      for (final formula in manuscript.formulas) {
        buffer.writeln(r'\subsection{' + _latexEscape(formula.title) + '}');
        buffer.writeln(r'\[');
        buffer.writeln(formula.latex);
        buffer.writeln(r'\]');
        if (formula.note.trim().isNotEmpty) {
          buffer.writeln(_latexEscape(formula.note.trim()));
        }
      }
    }

    if (manuscript.figures.isNotEmpty) {
      buffer.writeln(r'\section{Figures}');
      for (final fig in manuscript.figures) {
        buffer.writeln(r'\begin{figure}[ht]');
        buffer.writeln(r'\centering');
        buffer.writeln(
          r'\includegraphics[width=0.9\linewidth]{' +
              _latexPath(fig.path) +
              '}',
        );
        buffer.writeln(
          r'\caption{' +
              _latexEscape(fig.caption.isEmpty ? fig.title : fig.caption) +
              '}',
        );
        buffer.writeln(r'\end{figure}');
      }
    }

    if (papers.isNotEmpty) {
      buffer.writeln(r'\section{References}');
      buffer.writeln(r'\begin{itemize}');
      for (final paper in papers) {
        final year = paper.year == 0 ? 'n.d.' : paper.year.toString();
        buffer.writeln(
          r'\item ' +
              _latexEscape(
                '${paper.authors ?? 'Unknown authors'} ($year). ${paper.title}. ${paper.journal}.',
              ),
        );
      }
      buffer.writeln(r'\end{itemize}');
    }

    buffer.writeln(r'\end{document}');

    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<File> exportPdf({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final mdFile = await exportMarkdown(
      manuscript: manuscript,
      project: project,
      dataset: dataset,
      papers: papers,
      analyses: analyses,
      exportDirectoryPath: exportDirectoryPath,
    );

    final pdfPath = mdFile.path.replaceAll(RegExp(r'\.md$'), '.pdf');

    final pandoc = await _findExecutable('pandoc');
    if (pandoc == null) {
      throw Exception(
        'Pandoc is not installed or not in PATH. Markdown export was created.',
      );
    }

    final process = await Process.run(pandoc, [
      mdFile.path,
      '-o',
      pdfPath,
      '--pdf-engine=xelatex',
      '-V',
      'mainfont=${manuscript.format.fontFamily}',
      '-V',
      'fontsize=${manuscript.format.fontSize.toStringAsFixed(0)}pt',
      '-V',
      'geometry:margin=1in',
    ]);

    if (process.exitCode != 0) {
      throw Exception(
        'PDF export failed.\nSTDERR:\n${process.stderr}\nSTDOUT:\n${process.stdout}',
      );
    }

    return File(pdfPath);
  }

  Future<File> exportReproducibilityJson({
    required Manuscript manuscript,
    required Project? project,
    required Dataset? dataset,
    required List<EvidencePaper> papers,
    required List<AnalysisHistoryItem> analyses,
    String? exportDirectoryPath,
  }) async {
    final dir = await _exportDir(exportDirectoryPath: exportDirectoryPath);
    final file = File(
      '${dir.path}/reproducibility_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    final payload = {
      'created_at': DateTime.now().toIso8601String(),
      'project': project?.toJson(),
      'dataset': dataset?.toJson(),
      'manuscript': manuscript.toJson(),
      'papers': papers.map((e) => e.toJson()).toList(),
      'analysis_history': analyses.map((e) => e.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));
    return file;
  }

  String _buildMarkdown(
    Manuscript manuscript,
    Project? project,
    Dataset? dataset,
    List<EvidencePaper> papers,
    List<AnalysisHistoryItem> analyses,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('# ${_title(manuscript, project)}');
    buffer.writeln();

    if (manuscript.authors.trim().isNotEmpty) {
      buffer.writeln('**Authors:** ${manuscript.authors}');
      buffer.writeln();
    }

    if (manuscript.affiliation.trim().isNotEmpty) {
      buffer.writeln('**Affiliation:** ${manuscript.affiliation}');
      buffer.writeln();
    }

    if (manuscript.journalTarget.trim().isNotEmpty) {
      buffer.writeln('**Target journal:** ${manuscript.journalTarget}');
      buffer.writeln();
    }

    if (manuscript.abstractText.trim().isNotEmpty) {
      buffer.writeln('## Abstract');
      buffer.writeln();
      buffer.writeln(manuscript.abstractText.trim());
      buffer.writeln();
    }

    if (manuscript.keywords.trim().isNotEmpty) {
      buffer.writeln('**Keywords:** ${manuscript.keywords}');
      buffer.writeln();
    }

    if (project != null) {
      buffer.writeln('## Project Context');
      buffer.writeln();
      buffer.writeln('**Research question:** ${project.question}');
      buffer.writeln();
    }

    if (dataset != null) {
      buffer.writeln(
        '**Dataset:** ${dataset.name} (${dataset.rows} rows, ${dataset.columns} columns)',
      );
      buffer.writeln();
    }

    for (final section in manuscript.sections) {
      if (section.id == 'title_page' ||
          section.id == 'abstract' ||
          section.id == 'keywords') {
        continue;
      }

      buffer.writeln('## ${section.title}');
      buffer.writeln();
      buffer.writeln(
        section.content.trim().isEmpty
            ? '_To be written._'
            : section.content.trim(),
      );
      buffer.writeln();
    }

    if (manuscript.formulas.isNotEmpty) {
      buffer.writeln('## Formulas');
      buffer.writeln();

      for (final formula in manuscript.formulas) {
        buffer.writeln('### ${formula.title}');
        buffer.writeln();
        buffer.writeln(r'$$');
        buffer.writeln(formula.latex);
        buffer.writeln(r'$$');
        if (formula.note.trim().isNotEmpty) {
          buffer.writeln();
          buffer.writeln(formula.note.trim());
        }
        buffer.writeln();
      }
    }

    if (manuscript.figures.isNotEmpty) {
      buffer.writeln('## Figures');
      buffer.writeln();

      for (var i = 0; i < manuscript.figures.length; i++) {
        final fig = manuscript.figures[i];
        buffer.writeln('![${fig.title}](${fig.path})');
        buffer.writeln();
        buffer.writeln('**Figure ${i + 1}. ${fig.title}.** ${fig.caption}');
        buffer.writeln();
      }
    }

    if (manuscript.dataAttachments.isNotEmpty) {
      buffer.writeln('## Data Attachments');
      buffer.writeln();

      for (final attachment in manuscript.dataAttachments) {
        buffer.writeln('- **${attachment.name}**: `${attachment.path}`');
        if (attachment.description.trim().isNotEmpty) {
          buffer.writeln('  - ${attachment.description.trim()}');
        }
      }

      buffer.writeln();
    }

    if (analyses.isNotEmpty) {
      buffer.writeln('## Analysis History');
      buffer.writeln();

      for (final item in analyses) {
        buffer.writeln(
          '- **${item.method}** on `${item.datasetName}` · ${item.outcome}: ${item.summary}',
        );
      }

      buffer.writeln();
    }

    if (papers.isNotEmpty) {
      buffer.writeln('## References');
      buffer.writeln();

      for (final paper in papers) {
        final year = paper.year == 0 ? 'n.d.' : paper.year.toString();
        final authors = paper.authors ?? 'Unknown authors';
        buffer.writeln(
          '- $authors ($year). ${paper.title}. *${paper.journal}*.${paper.doi == null ? '' : ' DOI: ${paper.doi}'}',
        );
      }
    }

    if (manuscript.notes.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## Internal Notes');
      buffer.writeln();
      buffer.writeln(manuscript.notes.trim());
    }

    return buffer.toString();
  }

  Future<Directory> _exportDir({String? exportDirectoryPath}) async {
    if (exportDirectoryPath != null && exportDirectoryPath.trim().isNotEmpty) {
      final chosen = Directory(exportDirectoryPath);
      if (!await chosen.exists()) {
        await chosen.create(recursive: true);
      }
      return chosen;
    }

    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/EvidenceEngineStudioOpen/Exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  Future<String?> _findExecutable(String name) async {
    final candidates = [
      '/opt/homebrew/bin/$name',
      '/usr/local/bin/$name',
      '/usr/bin/$name',
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) return candidate;
    }

    final result = await Process.run('which', [name]);
    if (result.exitCode == 0) {
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) return path;
    }

    return null;
  }

  String _title(Manuscript manuscript, Project? project) {
    return manuscript.title.trim().isEmpty
        ? project?.title ?? 'Untitled manuscript'
        : manuscript.title.trim();
  }

  String _safeFileName(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return cleaned.isEmpty ? 'manuscript' : cleaned;
  }

  String _yamlEscape(String value) {
    return value.replaceAll('"', r'\"');
  }

  String _latexPath(String value) {
    return value.replaceAll(r'\', '/');
  }

  String _latexEscape(String value) {
    return value
        .replaceAll(r'\', r'\textbackslash{}')
        .replaceAll('&', r'\&')
        .replaceAll('%', r'\%')
        .replaceAll(r'$', r'\$')
        .replaceAll('#', r'\#')
        .replaceAll('_', r'\_')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}')
        .replaceAll('~', r'\textasciitilde{}')
        .replaceAll('^', r'\textasciicircum{}');
  }

  String _convertMarkdownishToLatex(String value) {
    return _latexEscape(value);
  }
}
