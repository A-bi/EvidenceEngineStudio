import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_section.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'widgets/sidebar.dart';
import 'widgets/glass_card.dart';
import 'widgets/section_header.dart';
import 'screens/projects/projects_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/data/data_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/evidence/evidence_screen.dart';
import 'screens/hypotheses/hypotheses_screen.dart';
import 'screens/writing/writing_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/export_center/export_center_screen.dart';
import 'screens/critique/critique_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  AppSection selectedSection = AppSection.home;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoaded) {
      return const Scaffold(
        backgroundColor: AppTheme.canvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showInspector = constraints.maxWidth >= 1150;
          final showSidebar = constraints.maxWidth >= 760;

          return Row(
            children: [
              if (showSidebar)
                Sidebar(
                  selectedSection: selectedSection,
                  onSelected: (section) {
                    setState(() => selectedSection = section);
                  },
                ),
              Expanded(
                child: Container(color: AppTheme.canvas, child: _mainContent()),
              ),
              if (showInspector) SizedBox(width: 320, child: _inspectorPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _mainContent() {
    switch (selectedSection) {
      case AppSection.home:
        return HomeScreen(
          onNavigate: (section) {
            setState(() => selectedSection = section);
          },
        );
      case AppSection.projects:
        return const ProjectsScreen();
      case AppSection.evidence:
        return const EvidenceScreen();
      case AppSection.data:
        return const DataScreen();
      case AppSection.analysis:
        return const AnalysisScreen();
      case AppSection.hypotheses:
        return const HypothesesScreen();
      case AppSection.writing:
        return const WritingScreen();
      case AppSection.critique:
        return const CritiqueScreen();
      case AppSection.exports:
        return const ExportCenterScreen();
      case AppSection.settings:
        return const SettingsScreen();
    }
  }

  Widget _placeholder({required String title, String? subtitle}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title, subtitle: subtitle),
          const SizedBox(height: 20),
          GlassCard(
            child: Text(
              '$title screen is ready for migration.',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorPanel() {
    final appState = context.watch<AppState>();
    final project = appState.selectedProject;
    final dataset = appState.selectedDataset;
    final summary = appState.importedSummary;
    final latestAnalysis = appState.latestAnalysisResult;

    String targetSection(String preferred) {
      if (appState.manuscript.sections.any(
        (section) => section.id == preferred,
      )) {
        return preferred;
      }

      if (appState.manuscript.sections.isNotEmpty) {
        return appState.manuscript.sections.first.id;
      }

      return preferred;
    }

    Widget actionButton({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
      bool filled = false,
    }) {
      final child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 7),
          Flexible(child: Text(label)),
        ],
      );

      if (filled) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onPressed, child: child),
        );
      }

      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: onPressed, child: child),
      );
    }

    Widget infoLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 94,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
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

    Widget inspectorCard({
      required String title,
      required String subtitle,
      required List<Widget> children,
    }) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...children,
            ],
          ],
        ),
      );
    }

    List<Widget> content;

    switch (selectedSection) {
      case AppSection.home:
        content = [
          inspectorCard(
            title: 'Workspace overview',
            subtitle: 'Navigate through the full research workflow.',
            children: [
              actionButton(
                icon: Icons.folder_rounded,
                label: 'Go to Projects',
                filled: true,
                onPressed: () =>
                    setState(() => selectedSection = AppSection.projects),
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.table_chart_rounded,
                label: 'Go to Data',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.data),
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.edit_square,
                label: 'Go to Writing',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.writing),
              ),
            ],
          ),
        ];
        break;

      case AppSection.projects:
        content = [
          inspectorCard(
            title: 'Project Inspector',
            subtitle: project == null
                ? 'No project selected.'
                : 'Current project focus and linked objects.',
            children: [
              infoLine('Project', project?.title ?? 'None'),
              infoLine('Question', project?.question ?? 'No question defined'),
              infoLine('Datasets', '${appState.datasets.length}'),
              infoLine(
                'Evidence',
                '${appState.papersForProject(project?.id).length}',
              ),
              infoLine(
                'Hypotheses',
                '${appState.hypothesesForProject(project?.id).length}',
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.table_chart_rounded,
                label: 'Open Data / File Inspector',
                filled: true,
                onPressed: () =>
                    setState(() => selectedSection = AppSection.data),
              ),
            ],
          ),
        ];
        break;

      case AppSection.evidence:
        content = [
          inspectorCard(
            title: 'Evidence Inspector',
            subtitle: 'Use linked papers as manuscript input.',
            children: [
              infoLine('Project', project?.title ?? 'None'),
              infoLine(
                'Linked papers',
                '${appState.papersForProject(project?.id).length}',
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.edit_square,
                label: 'Go to Writing',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.writing),
              ),
            ],
          ),
        ];
        break;

      case AppSection.data:
        final name = dataset?.name ?? summary?.file ?? 'No dataset imported';
        final rows = dataset?.rows ?? summary?.rows ?? 0;
        final columns = dataset?.columns ?? summary?.columns ?? 0;

        content = [
          inspectorCard(
            title: 'Data / File Inspector',
            subtitle:
                'Dataset metadata and writing actions. Private paths stay hidden.',
            children: [
              infoLine('File', name),
              infoLine('Rows', '$rows'),
              infoLine('Columns', '$columns'),
              infoLine(
                'Status',
                summary == null ? 'No active import' : 'Imported and inspected',
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.input_rounded,
                label: 'Insert dataset into Methods',
                filled: true,
                onPressed: summary == null && dataset == null
                    ? null
                    : () {
                        final target = targetSection('methods');
                        appState.insertTextIntoSection(
                          target,
                          [
                            '### Dataset',
                            '',
                            'Dataset name: $name',
                            '',
                            'Rows: $rows',
                            'Columns: $columns',
                            '',
                            'The dataset was imported and inspected locally. Private local file paths are intentionally omitted for privacy and portability.',
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
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.monitor_heart_rounded,
                label: 'Go to Analysis',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.analysis),
              ),
            ],
          ),
        ];
        break;

      case AppSection.analysis:
        content = [
          inspectorCard(
            title: 'Analysis Inspector',
            subtitle: latestAnalysis == null
                ? 'No analysis result selected yet.'
                : 'Latest analysis is available for writing.',
            children: [
              infoLine('Latest', latestAnalysis?.analysis ?? 'None'),
              infoLine('Outcome', latestAnalysis?.outcome ?? '-'),
              infoLine('N', '${latestAnalysis?.n ?? 0}'),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.edit_square,
                label: 'Go to Writing',
                filled: true,
                onPressed: () =>
                    setState(() => selectedSection = AppSection.writing),
              ),
            ],
          ),
        ];
        break;

      case AppSection.hypotheses:
        content = [
          inspectorCard(
            title: 'Hypothesis Inspector',
            subtitle: 'Connect ideas, evidence and analysis logic.',
            children: [
              infoLine('Project', project?.title ?? 'None'),
              infoLine(
                'Hypotheses',
                '${appState.hypothesesForProject(project?.id).length}',
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.edit_square,
                label: 'Go to Writing',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.writing),
              ),
            ],
          ),
        ];
        break;

      case AppSection.writing:
        final filled = appState.manuscript.sections
            .where((section) => section.content.trim().isNotEmpty)
            .length;

        content = [
          inspectorCard(
            title: 'Writing Inspector',
            subtitle: 'Manuscript status and next steps.',
            children: [
              infoLine(
                'Title',
                appState.manuscript.title.isEmpty
                    ? 'Untitled'
                    : appState.manuscript.title,
              ),
              infoLine(
                'Sections',
                '$filled/${appState.manuscript.sections.length} filled',
              ),
              infoLine('Figures', '${appState.manuscript.figures.length}'),
              infoLine('Formulas', '${appState.manuscript.formulas.length}'),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.feedback_rounded,
                label: 'Critique manuscript',
                filled: true,
                onPressed: () =>
                    setState(() => selectedSection = AppSection.critique),
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.ios_share_rounded,
                label: 'Open Export Center',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.exports),
              ),
            ],
          ),
        ];
        break;

      case AppSection.critique:
        content = [
          inspectorCard(
            title: 'Critique Inspector',
            subtitle: 'Use critique results to improve the manuscript.',
            children: [
              actionButton(
                icon: Icons.edit_square,
                label: 'Back to Writing',
                filled: true,
                onPressed: () =>
                    setState(() => selectedSection = AppSection.writing),
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.ios_share_rounded,
                label: 'Go to Exports',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.exports),
              ),
            ],
          ),
        ];
        break;

      case AppSection.exports:
        content = [
          inspectorCard(
            title: 'Export Inspector',
            subtitle: 'Manage exported files and selected export folder.',
            children: [
              infoLine(
                'Folder',
                appState.exportDirectoryPath == null
                    ? 'Default'
                    : 'Custom selected',
              ),
              const SizedBox(height: 8),
              actionButton(
                icon: Icons.settings_rounded,
                label: 'Export settings',
                onPressed: () =>
                    setState(() => selectedSection = AppSection.settings),
              ),
            ],
          ),
        ];
        break;

      case AppSection.settings:
        content = [
          inspectorCard(
            title: 'Settings Inspector',
            subtitle: 'Configuration is local and privacy-aware.',
            children: [
              infoLine(
                'Export folder',
                appState.exportDirectoryPath == null
                    ? 'Default'
                    : 'Custom selected',
              ),
              infoLine('Backend', 'Checked in Settings'),
            ],
          ),
        ];
        break;
    }

    return Container(
      color: AppTheme.canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inspector',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }
}
