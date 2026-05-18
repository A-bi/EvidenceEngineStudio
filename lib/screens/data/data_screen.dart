import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';

import '../../models/dataset.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.importedSummary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Data',
            subtitle:
                'Import, inspect, and understand your dataset before analysis.',
          ),
          const SizedBox(height: 20),
          _TopBar(),
          const SizedBox(height: 20),
          _DataInspectorCard(),
          const SizedBox(height: 20),
          if (summary != null) _SummarySection(),
          if (summary != null) const SizedBox(height: 20),
          _DatasetListSection(),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final state = context.read<AppState>();

              final file = await openFile();

              final path = file?.path;
              if (path == null) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No file selected.')),
                );
                return;
              }

              try {
                await state.importDataset(path);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Dataset imported: ${file?.name ?? 'selected file'}',
                    ),
                  ),
                );
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Import failed: $error')),
                );
              }
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import dataset'),
          ),
          const SizedBox(
            width: 520,
            child: Text(
              'Choose CSV, TSV, TXT, JSON, Excel or statistical datasets. The Data/File Inspector keeps private local paths hidden.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataInspectorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dataset = state.selectedDataset;
    final summary = state.importedSummary;

    if (dataset == null && summary == null) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'File Inspector',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryText,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'No dataset selected yet. Import a file to inspect metadata, preview and research-readiness.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    final name = dataset?.name ?? summary?.file ?? 'Imported dataset';
    final source = dataset?.source ?? _extensionFromName(name).toUpperCase();
    final rows = dataset?.rows ?? summary?.rows ?? 0;
    final columns = dataset?.columns ?? summary?.columns ?? 0;
    final variables = summary?.columnNames?.length ?? columns;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: AppTheme.primaryText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Dataset file inspected locally. Private path hidden.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InspectorPill('Role', 'Dataset'),
              _InspectorPill('Type', source.isEmpty ? 'Unknown' : source),
              _InspectorPill('Rows', '$rows'),
              _InspectorPill('Columns', '$columns'),
              _InspectorPill('Variables', '$variables'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: dataset == null && summary == null
                    ? null
                    : () {
                        final target = _targetSectionId(state, 'methods');

                        state.insertTextIntoSection(
                          target,
                          [
                            '### Dataset',
                            '',
                            'Dataset name: $name',
                            '',
                            'Rows: $rows  ',
                            'Columns: $columns  ',
                            'Source/type: ${source.isEmpty ? 'Unknown' : source}',
                            '',
                            'The dataset was imported and inspected locally using the integrated Data/File Inspector. Private local file paths are intentionally not included in the manuscript.',
                          ].join('\n'),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dataset description inserted into Methods.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.input_rounded),
                label: const Text('Insert into Methods'),
              ),
              OutlinedButton.icon(
                onPressed: dataset == null && summary == null
                    ? null
                    : () {
                        final target = _targetSectionId(
                          state,
                          'data_availability',
                        );

                        state.insertTextIntoSection(
                          target,
                          [
                            'The dataset was processed locally within EvidenceEngine Studio Open.',
                            '',
                            'Exported analysis and reproducibility files can be generated from the Writing and Export modules.',
                            '',
                            'Local file system paths are omitted from the manuscript for privacy and portability.',
                          ].join('\n'),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data availability note inserted.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.privacy_tip_rounded),
                label: const Text('Insert data availability'),
              ),
              OutlinedButton.icon(
                onPressed: summary == null
                    ? null
                    : () {
                        final target = _targetSectionId(state, 'results');

                        final variableText =
                            summary.variableTypes?.entries
                                .map((e) => '- ${e.key}: ${e.value}')
                                .join('\n') ??
                            'No variable type information available.';

                        state.insertTextIntoSection(
                          target,
                          [
                            '### Dataset inspection summary',
                            '',
                            'Rows: ${summary.rows ?? 0}  ',
                            'Columns: ${summary.columns ?? 0}',
                            '',
                            'Detected variable types:',
                            '',
                            variableText,
                          ].join('\n'),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dataset inspection summary inserted.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Insert inspection summary'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _targetSectionId(AppState state, String preferred) {
    if (state.manuscript.sections.any((section) => section.id == preferred)) {
      return preferred;
    }

    if (state.manuscript.sections.isNotEmpty) {
      return state.manuscript.sections.first.id;
    }

    return preferred;
  }

  static String _extensionFromName(String name) {
    if (!name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }
}

class _InspectorPill extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorPill(this.label, this.value);

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

class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<AppState>().importedSummary;
    if (summary == null) return const SizedBox.shrink();

    final groupColumns =
        summary.variableTypes?.entries
            .where(
              (e) => [
                'categorical',
                'boolean',
                'numeric_discrete',
              ].contains(e.value),
            )
            .map((e) => e.key)
            .toList() ??
        [];

    final outcomeColumns =
        summary.variableTypes?.entries
            .where(
              (e) =>
                  ['numeric_continuous', 'numeric_discrete'].contains(e.value),
            )
            .map((e) => e.key)
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(title: 'Rows', value: '${summary.rows ?? 0}'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Columns',
                value: '${summary.columns ?? 0}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Variables',
                value: '${summary.columnNames?.length ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-detected research hints',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 14),
              if (groupColumns.isNotEmpty) ...[
                const _SmallLabel('Likely group variables'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: groupColumns
                      .map((c) => _Badge(c, soft: true))
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],
              if (outcomeColumns.isNotEmpty) ...[
                const _SmallLabel('Likely outcome variables'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: outcomeColumns.map((c) => _Badge(c)).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (summary.variableTypes != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Variable types',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                ...summary.variableTypes!.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                        _TypePill(entry.value),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (summary.preview != null && summary.preview!.isNotEmpty)
          _PreviewTable(),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final summary = context.watch<AppState>().importedSummary;
    final preview = summary?.preview ?? [];
    final columns = summary?.columnNames ?? [];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns
                  .map(
                    (c) => DataColumn(
                      label: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(),
              rows: preview
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map((c) => DataCell(Text('${row[c] ?? ''}')))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatasetListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datasets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (state.datasets.isEmpty)
            const Text(
              'No datasets imported yet.',
              style: TextStyle(color: AppTheme.secondaryText),
            )
          else
            ...state.datasets.map((dataset) => _DatasetRow(dataset: dataset)),
        ],
      ),
    );
  }
}

class _DatasetRow extends StatelessWidget {
  final Dataset dataset;

  const _DatasetRow({required this.dataset});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected = state.selectedDataset?.id == dataset.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.selectedCard
            : AppTheme.canvas.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.borderStrong : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.table_chart_rounded,
            color: selected ? AppTheme.accent : AppTheme.secondaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataset.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dataset.rows} rows · ${dataset.columns} columns · ${dataset.source}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                if (dataset.filePath != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    dataset.filePath!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (selected)
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent,
              ),
            ),
          TextButton(
            onPressed: () => context.read<AppState>().selectDataset(dataset),
            child: const Text('Use'),
          ),
          IconButton(
            onPressed: () => context.read<AppState>().removeDataset(dataset),
            icon: const Icon(Icons.delete_outline_rounded),
            color: Colors.red,
            tooltip: 'Remove dataset',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool soft;

  const _Badge(this.text, {this.soft = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft ? AppTheme.accentSoft.withOpacity(0.55) : AppTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String value;

  const _TypePill(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  final String text;

  const _SmallLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedText,
      ),
    );
  }
}
