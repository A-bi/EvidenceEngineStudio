import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_diagnostics_service.dart';
import '../../services/export_library_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Settings',
            subtitle:
                'Configure the local research workflow, export behavior, backend availability and project links.',
          ),
          const SizedBox(height: 20),
          _WorkflowCard(),
          const SizedBox(height: 20),
          _ExportCard(exportDirectoryPath: state.exportDirectoryPath),
          const SizedBox(height: 20),
          const _BackendCard(),
          const SizedBox(height: 20),
          const _LinksCard(),
          const SizedBox(height: 20),
          const _PrivacyCard(),
          const SizedBox(height: 20),
          const _AboutCard(),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _WorkflowStep(
        icon: Icons.folder_rounded,
        title: '1. Project',
        text:
            'Create or select a research project and define the central question.',
      ),
      _WorkflowStep(
        icon: Icons.menu_book_rounded,
        title: '2. Evidence',
        text:
            'Search literature through EvidenceEngine and link relevant papers.',
      ),
      _WorkflowStep(
        icon: Icons.table_chart_rounded,
        title: '3. Data',
        text: 'Import CSV, Excel, JSON or other supported datasets.',
      ),
      _WorkflowStep(
        icon: Icons.monitor_heart_rounded,
        title: '4. Analysis',
        text:
            'Run descriptive statistics, group comparisons, correlations and models.',
      ),
      _WorkflowStep(
        icon: Icons.account_tree_rounded,
        title: '5. Research Graph',
        text:
            'Connect hypotheses, evidence, analyses, datasets and ideas visually.',
      ),
      _WorkflowStep(
        icon: Icons.edit_square,
        title: '6. Writing',
        text:
            'Write the manuscript, insert formulas, figures, references and result blocks.',
      ),
      _WorkflowStep(
        icon: Icons.feedback_rounded,
        title: '7. Critique',
        text:
            'Check completeness, scientific logic, methods, evidence and reporting quality.',
      ),
      _WorkflowStep(
        icon: Icons.ios_share_rounded,
        title: '8. Export',
        text:
            'Export Markdown, TXT, RMarkdown, LaTeX, PDF and reproducibility JSON.',
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.route_rounded,
            title: 'Workflow',
            subtitle: 'From research question to exportable manuscript.',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;

              if (compact) {
                return Column(
                  children: steps
                      .map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: step,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: steps
                    .map(
                      (step) => SizedBox(
                        width: (constraints.maxWidth - 24) / 3,
                        child: step,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.canvas.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppTheme.accentSoft.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryText),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
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
}

class _ExportCard extends StatelessWidget {
  final String? exportDirectoryPath;

  const _ExportCard({required this.exportDirectoryPath});

  @override
  Widget build(BuildContext context) {
    final hasCustomFolder =
        exportDirectoryPath != null && exportDirectoryPath!.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.folder_rounded,
            title: 'Export',
            subtitle: hasCustomFolder
                ? 'Custom export folder selected'
                : 'Using default export folder',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final selected = await getDirectoryPath(
                    confirmButtonText: 'Use this export folder',
                  );

                  if (selected == null || selected.trim().isEmpty) return;

                  if (context.mounted) {
                    context.read<AppState>().setExportDirectoryPath(selected);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export folder selected.')),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Choose export folder'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ExportLibraryService.instance.openExportFolder(
                    customPath: context.read<AppState>().exportDirectoryPath,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open export folder'),
              ),
              OutlinedButton.icon(
                onPressed: hasCustomFolder
                    ? () {
                        context.read<AppState>().setExportDirectoryPath(null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export folder reset to default.'),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusLine(
            'Current folder',
            hasCustomFolder
                ? 'Custom folder selected'
                : 'Default app export folder',
          ),
          const SizedBox(height: 6),
          const Text(
            'Private local paths are intentionally hidden in Settings.',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _BackendCard extends StatefulWidget {
  const _BackendCard();

  @override
  State<_BackendCard> createState() => _BackendCardState();
}

class _BackendCardState extends State<_BackendCard> {
  late Future<AppDiagnostics> future;

  @override
  void initState() {
    super.initState();
    future = AppDiagnosticsService.instance.inspect();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: FutureBuilder<AppDiagnostics>(
        future: future,
        builder: (context, snapshot) {
          final diagnostics = snapshot.data;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _CardHeader(
                      icon: Icons.memory_rounded,
                      title: 'Backend',
                      subtitle: 'Local analysis engine status.',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        future = AppDiagnosticsService.instance.inspect();
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (diagnostics == null)
                const _StatusPill(label: 'Backend unavailable', ok: false)
              else ...[
                _StatusPill(
                  label: diagnostics.backendUsable
                      ? 'Backend ready'
                      : 'Backend incomplete',
                  ok: diagnostics.backendUsable,
                ),
                const SizedBox(height: 14),
                _StatusLine('Mode', diagnostics.backendMode),
                _StatusLine(
                  'Analysis backend',
                  diagnostics.analysisBinaryFound ||
                          diagnostics.analysisScriptFound
                      ? 'Available'
                      : 'Missing',
                ),
                _StatusLine(
                  'Dataset backend',
                  diagnostics.datasetBinaryFound ||
                          diagnostics.datasetScriptFound
                      ? 'Available'
                      : 'Missing',
                ),
                _StatusLine(
                  'Runtime',
                  diagnostics.analysisBinaryFound &&
                          diagnostics.datasetBinaryFound
                      ? 'Bundled binary'
                      : diagnostics.pythonVenvFound
                      ? 'Development runtime'
                      : 'Not detected',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Technical paths are hidden for privacy and portability.',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LinksCard extends StatelessWidget {
  const _LinksCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            icon: Icons.link_rounded,
            title: 'Links & Support',
            subtitle: 'Project repository, support and EvidenceEngine access.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _openExternal(
                  'https://github.com/A-bi/EvidenceEngineStudio',
                ),
                icon: const Icon(Icons.code_rounded),
                label: const Text('GitHub Support'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openExternal('https://evidenceengine.eu'),
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('EvidenceEngine.eu'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'For support, updates and issue tracking, use the GitHub repository. Literature search and evidence workflows are connected to EvidenceEngine.',
            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy',
            subtitle: 'Local-first research workflow.',
          ),
          SizedBox(height: 14),
          Text(
            'Datasets and exports are processed locally on this device. Literature search uses the configured EvidenceEngine endpoint. Export files are written only to the selected export folder or to the app default export folder.',
            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.info_rounded,
            title: 'About',
            subtitle: 'EvidenceEngine Studio Open',
          ),
          SizedBox(height: 14),
          Text(
            'EvidenceEngine Studio Open is a local-first research workspace for projects, datasets, literature, analysis, hypothesis mapping, manuscript writing, critique and exports.',
            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
          SizedBox(height: 14),
          Text(
            'Copyright © Alice Laquerrière-Hecker',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: AppTheme.accentSoft.withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, color: AppTheme.primaryText, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String label;
  final String value;

  const _StatusLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusPill({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ok
            ? Colors.green.withOpacity(0.14)
            : Colors.orange.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ok
              ? Colors.green.withOpacity(0.35)
              : Colors.orange.withOpacity(0.35),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

Future<void> _openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
