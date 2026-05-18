import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/analysis_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/analysis_chart.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisMethod selectedMethod = AnalysisMethod.descriptive;
  String? outcome;
  String? predictor;
  String? group;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.importedSummary;
    final dataset = state.selectedDataset;
    final columns = summary?.columnNames ?? [];
    final types = summary?.variableTypes ?? {};

    final numericColumns = columns
        .where((c) => ['numeric_continuous', 'numeric_discrete'].contains(types[c]))
        .toList();

    final categoricalColumns = columns
        .where((c) => ['categorical', 'boolean', 'numeric_discrete', 'text'].contains(types[c]))
        .toList();

    final outcomeOptions = selectedMethod.outcomeShouldBeNumeric && numericColumns.isNotEmpty
        ? numericColumns
        : columns;

    final predictorOptions = selectedMethod.predictorShouldBeNumeric && numericColumns.isNotEmpty
        ? numericColumns
        : columns;

    final groupOptions = categoricalColumns.isNotEmpty ? categoricalColumns : columns;

    outcome = _validOrFirst(outcome, outcomeOptions);
    predictor = _validOrFirst(predictor, predictorOptions);
    group = _validOrFirst(group, groupOptions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Analysis Studio',
            subtitle:
                'Choose statistical methods, map variables, run models, and inspect plots.',
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected dataset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dataset?.name ?? 'No dataset selected',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dataset?.filePath ?? 'Import one in the Data section first.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (summary == null || columns.isEmpty)
            const GlassCard(
              child: Text(
                'No dataset summary available. Import a dataset in the Data section first.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),
            )
          else
            _setupCard(
              outcomeOptions: outcomeOptions,
              predictorOptions: predictorOptions,
              groupOptions: groupOptions,
              types: types,
            ),
          const SizedBox(height: 20),
          if (state.latestAnalysisResult != null) _ResultCard(),
          if (state.analysisHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            _HistoryCard(),
          ],
        ],
      ),
    );
  }

  String? _validOrFirst(String? value, List<String> options) {
    if (options.isEmpty) return null;
    if (value != null && options.contains(value)) return value;
    return options.first;
  }

  Widget _setupCard({
    required List<String> outcomeOptions,
    required List<String> predictorOptions,
    required List<String> groupOptions,
    required Map<String, String> types,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _dropdown<AnalysisMethod>(
            label: 'Method',
            value: selectedMethod,
            items: AnalysisMethod.values,
            itemLabel: (m) => m.label,
            onChanged: (value) {
              if (value == null) return;
              setState(() => selectedMethod = value);
            },
          ),
          const SizedBox(height: 16),
          _dropdown<String>(
            label: _outcomeLabel(),
            value: outcome,
            items: outcomeOptions,
            itemLabel: (c) => '$c · ${types[c] ?? 'unknown'}',
            onChanged: (value) => setState(() => outcome = value),
          ),
          if (selectedMethod.needsPredictor) ...[
            const SizedBox(height: 16),
            _dropdown<String>(
              label: _predictorLabel(),
              value: predictor,
              items: predictorOptions,
              itemLabel: (c) => '$c · ${types[c] ?? 'unknown'}',
              onChanged: (value) => setState(() => predictor = value),
            ),
          ],
          if (selectedMethod.needsGroup) ...[
            const SizedBox(height: 16),
            _dropdown<String>(
              label: _groupLabel(),
              value: group,
              items: groupOptions,
              itemLabel: (c) => '$c · ${types[c] ?? 'unknown'}',
              onChanged: (value) => setState(() => group = value),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: outcome == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await context.read<AppState>().runAnalysis(
                            method: selectedMethod,
                            outcome: outcome!,
                            predictor: predictor,
                            group: group,
                          );

                      messenger.showSnackBar(
                        const SnackBar(content: Text('Analysis finished.')),
                      );
                    } catch (error) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Analysis failed: $error')),
                      );
                    }
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run analysis'),
          ),
        ],
      ),
    );
  }

  String _outcomeLabel() {
    switch (selectedMethod) {
      case AnalysisMethod.chiSquare:
      case AnalysisMethod.fisherExact2x2:
        return 'Variable A';
      case AnalysisMethod.kaplanMeier:
      case AnalysisMethod.logRank:
        return 'Time variable';
      case AnalysisMethod.diagnosticMetrics:
      case AnalysisMethod.rocAuc:
      case AnalysisMethod.logisticRegression:
      case AnalysisMethod.riskComparison:
        return 'Binary outcome / truth';
      default:
        return 'Outcome / variable';
    }
  }

  String _predictorLabel() {
    switch (selectedMethod) {
      case AnalysisMethod.kaplanMeier:
      case AnalysisMethod.logRank:
        return 'Event indicator';
      case AnalysisMethod.diagnosticMetrics:
        return 'Test / prediction variable';
      case AnalysisMethod.rocAuc:
        return 'Numeric score / predictor';
      case AnalysisMethod.pairedTTest:
      case AnalysisMethod.wilcoxonSignedRank:
        return 'Second paired numeric variable';
      default:
        return 'Predictor / second variable';
    }
  }

  String _groupLabel() {
    switch (selectedMethod) {
      case AnalysisMethod.chiSquare:
      case AnalysisMethod.fisherExact2x2:
        return 'Variable B';
      case AnalysisMethod.logRank:
        return 'Group variable';
      default:
        return 'Group / condition variable';
    }
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: items.contains(value) ? value : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final result = context.watch<AppState>().latestAnalysisResult!;
    final metrics = result.metrics;
    final categoryCounts = result.categoryCounts;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.analysis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.interpretation,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryText,
            ),
          ),
          if (result.warning != null) ...[
            const SizedBox(height: 10),
            Text(
              result.warning!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.warning,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (result.plotPath != null && File(result.plotPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(result.plotPath!),
                fit: BoxFit.contain,
              ),
            )
          else
            AnalysisChart(result: result),
          const SizedBox(height: 16),
          if (metrics != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Metric')),
                  DataColumn(label: Text('Value')),
                ],
                rows: metrics.entries
                    .map(
                      (entry) => DataRow(
                        cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text(_formatNumber(entry.value))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          if (categoryCounts != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Count')),
                ],
                rows: categoryCounts.entries
                    .take(30)
                    .map(
                      (entry) => DataRow(
                        cells: [
                          DataCell(Text(entry.key)),
                          DataCell(Text('${entry.value}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value.isInfinite) return '∞';
    if (value.isNaN) return 'NaN';
    return value.toStringAsFixed(4);
  }
}

class _HistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().analysisHistory;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          ...history.take(12).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.method,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        '${item.datasetName} · ${item.outcome}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedText,
                        ),
                      ),
                      Text(
                        item.summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
