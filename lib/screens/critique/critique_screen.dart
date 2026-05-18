import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/manuscript.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class CritiqueScreen extends StatelessWidget {
  const CritiqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final manuscript = state.manuscript;
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);
    final analyses = state.analysisHistory;

    final report = _critique(
      manuscript: manuscript,
      paperCount: papers.length,
      analysisCount: analyses.length,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Critique Studio',
            subtitle:
                'A structured internal review of manuscript completeness, scientific logic, methods, evidence and export readiness.',
          ),
          const SizedBox(height: 20),
          _scoreCard(report),
          const SizedBox(height: 20),
          _summaryCard(report),
          const SizedBox(height: 20),
          _itemsCard('Critical issues', report.critical),
          const SizedBox(height: 20),
          _itemsCard('Warnings', report.warnings),
          const SizedBox(height: 20),
          _itemsCard('Suggestions', report.suggestions),
          const SizedBox(height: 20),
          _itemsCard('Strengths', report.strengths),
        ],
      ),
    );
  }

  Widget _scoreCard(_CritiqueReport report) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: _scoreColor(report.score).withOpacity(0.16),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _scoreColor(report.score).withOpacity(0.45),
              ),
            ),
            child: Center(
              child: Text(
                '${report.score}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _scoreColor(report.score),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.grade,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  report.shortInterpretation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(_CritiqueReport report) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manuscript overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill('Words', '${report.wordCount}'),
              _Pill(
                'Filled sections',
                '${report.filledSections}/${report.totalSections}',
              ),
              _Pill('Formulas', '${report.formulaCount}'),
              _Pill('Figures', '${report.figureCount}'),
              _Pill('Evidence papers', '${report.paperCount}'),
              _Pill('Analyses', '${report.analysisCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(String title, List<_CritiqueItem> items) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${items.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'None detected.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            )
          else
            ...items.map((item) => _CritiqueTile(item: item)),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  _CritiqueReport _critique({
    required Manuscript manuscript,
    required int paperCount,
    required int analysisCount,
  }) {
    final critical = <_CritiqueItem>[];
    final warnings = <_CritiqueItem>[];
    final suggestions = <_CritiqueItem>[];
    final strengths = <_CritiqueItem>[];

    final sections = manuscript.sections;
    final filledSections = sections
        .where((s) => s.content.trim().length > 80)
        .length;
    final totalSections = sections.length;

    final fullText = [
      manuscript.title,
      manuscript.abstractText,
      manuscript.keywords,
      ...sections.map((s) => s.content),
    ].join('\n\n');

    final wordCount = fullText
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;

    String sectionContent(String id) {
      return sections
          .where((s) => s.id == id)
          .map((s) => s.content.trim())
          .join('\n');
    }

    final abstractOk =
        manuscript.abstractText.trim().length > 120 ||
        sectionContent('abstract').length > 120;

    final methodsOk =
        sectionContent('methods').length > 120 ||
        sectionContent('study_design').length > 120;

    final statsOk = sectionContent('statistics').length > 120;

    final resultsOk = sectionContent('results').length > 120;

    final discussionOk = sectionContent('discussion').length > 120;

    final limitationsOk = sectionContent('limitations').length > 80;

    final ethicsOk =
        sectionContent('ethics').length > 40 ||
        sectionContent('data_availability').length > 40;

    if (manuscript.title.trim().length < 12) {
      critical.add(
        _CritiqueItem(
          area: 'Title',
          message: 'The manuscript title is missing or too short.',
          action:
              'Add a specific title including population, method and main outcome.',
        ),
      );
    }

    if (!abstractOk) {
      critical.add(
        _CritiqueItem(
          area: 'Abstract',
          message: 'The abstract is missing or underdeveloped.',
          action: 'Add Background, Objective, Methods, Results and Conclusion.',
        ),
      );
    }

    if (!methodsOk) {
      critical.add(
        _CritiqueItem(
          area: 'Methods',
          message: 'The methods section is not sufficiently developed.',
          action:
              'Describe design, data source, inclusion criteria and variables.',
        ),
      );
    }

    if (!resultsOk) {
      critical.add(
        _CritiqueItem(
          area: 'Results',
          message: 'The results section is currently too sparse.',
          action:
              'Insert analysis outputs and report sample size, effect sizes and uncertainty.',
        ),
      );
    }

    if (!statsOk) {
      warnings.add(
        _CritiqueItem(
          area: 'Statistics',
          message: 'The statistical analysis plan is missing or too short.',
          action:
              'Specify tests, models, assumptions, missing-data handling and software.',
        ),
      );
    }

    if (!discussionOk) {
      warnings.add(
        _CritiqueItem(
          area: 'Discussion',
          message: 'The discussion is not yet sufficiently developed.',
          action:
              'Interpret the main findings and compare them with prior evidence.',
        ),
      );
    }

    if (!limitationsOk) {
      warnings.add(
        _CritiqueItem(
          area: 'Limitations',
          message: 'Limitations are missing or too brief.',
          action:
              'Add internal validity, external validity, sample size and measurement limitations.',
        ),
      );
    }

    if (!ethicsOk) {
      warnings.add(
        _CritiqueItem(
          area: 'Ethics / Data availability',
          message: 'Ethics or data availability information is missing.',
          action:
              'Clarify approval, consent, dataset access and code availability.',
        ),
      );
    }

    if (paperCount < 5) {
      suggestions.add(
        _CritiqueItem(
          area: 'Evidence',
          message: 'Only few linked papers are available.',
          action:
              'Import more directly relevant references through Evidence Search.',
        ),
      );
    } else {
      strengths.add(
        _CritiqueItem(
          area: 'Evidence',
          message: 'The manuscript has a linked evidence base.',
          action: 'Use citations consistently in Introduction and Discussion.',
        ),
      );
    }

    if (analysisCount == 0) {
      warnings.add(
        _CritiqueItem(
          area: 'Analysis',
          message: 'No analysis results have been added yet.',
          action:
              'Run at least one analysis and insert the result block into Results.',
        ),
      );
    } else {
      strengths.add(
        _CritiqueItem(
          area: 'Analysis',
          message: 'Analysis history is available.',
          action: 'Check that model assumptions and uncertainty are reported.',
        ),
      );
    }

    if (manuscript.figures.isEmpty) {
      suggestions.add(
        _CritiqueItem(
          area: 'Figures',
          message: 'No figures are attached.',
          action:
              'Add a main result figure, model diagnostic plot or study flow diagram.',
        ),
      );
    } else {
      strengths.add(
        _CritiqueItem(
          area: 'Figures',
          message: 'Figures are attached.',
          action: 'Ensure every figure has a self-contained legend.',
        ),
      );
    }

    if (manuscript.formulas.isNotEmpty) {
      strengths.add(
        _CritiqueItem(
          area: 'Mathematical clarity',
          message: 'Formulas are explicitly stored in the manuscript.',
          action:
              'Define all variables and connect formulas to the statistical analysis.',
        ),
      );
    }

    if (wordCount < 800) {
      suggestions.add(
        _CritiqueItem(
          area: 'Length',
          message: 'The manuscript is still very short.',
          action:
              'Expand Introduction, Methods, Results and Discussion before external review.',
        ),
      );
    }

    var score = 100;
    score -= critical.length * 16;
    score -= warnings.length * 8;
    score -= suggestions.length * 3;
    score += strengths.length * 2;
    score = score.clamp(0, 100);

    final grade = score >= 80
        ? 'Submission-near draft'
        : score >= 60
        ? 'Promising but incomplete'
        : 'Early draft';

    final shortInterpretation = score >= 80
        ? 'The manuscript structure is mostly complete. Focus on polishing, citations and journal-specific formatting.'
        : score >= 60
        ? 'The manuscript has a useful core but still needs methodological and reporting improvements.'
        : 'The manuscript needs substantial development before it is ready for external review.';

    return _CritiqueReport(
      score: score,
      grade: grade,
      shortInterpretation: shortInterpretation,
      wordCount: wordCount,
      filledSections: filledSections,
      totalSections: totalSections,
      formulaCount: manuscript.formulas.length,
      figureCount: manuscript.figures.length,
      paperCount: paperCount,
      analysisCount: analysisCount,
      critical: critical,
      warnings: warnings,
      suggestions: suggestions,
      strengths: strengths,
    );
  }
}

class _CritiqueTile extends StatelessWidget {
  final _CritiqueItem item;

  const _CritiqueTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.canvas.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.area,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.message,
            style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            'Action: ${item.action}',
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _CritiqueReport {
  final int score;
  final String grade;
  final String shortInterpretation;
  final int wordCount;
  final int filledSections;
  final int totalSections;
  final int formulaCount;
  final int figureCount;
  final int paperCount;
  final int analysisCount;
  final List<_CritiqueItem> critical;
  final List<_CritiqueItem> warnings;
  final List<_CritiqueItem> suggestions;
  final List<_CritiqueItem> strengths;

  _CritiqueReport({
    required this.score,
    required this.grade,
    required this.shortInterpretation,
    required this.wordCount,
    required this.filledSections,
    required this.totalSections,
    required this.formulaCount,
    required this.figureCount,
    required this.paperCount,
    required this.analysisCount,
    required this.critical,
    required this.warnings,
    required this.suggestions,
    required this.strengths,
  });
}

class _CritiqueItem {
  final String area;
  final String message;
  final String action;

  _CritiqueItem({
    required this.area,
    required this.message,
    required this.action,
  });
}
