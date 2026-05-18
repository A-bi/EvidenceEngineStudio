import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedProject = state.selectedProject;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Projects',
            subtitle:
                'Every project is a container for question, evidence, hypotheses, analysis, and writing.',
          ),
          const SizedBox(height: 20),
          ...state.projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProjectCard(project: project),
            ),
          ),
          if (selectedProject != null) ...[
            const SizedBox(height: 12),
            const SectionHeader(
              'Selected project',
              subtitle: 'Current project focus and linked research objects.',
            ),
            const SizedBox(height: 16),
            _ProjectDetail(project: selectedProject),
          ],
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selected = state.selectedProject?.id == project.id;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.read<AppState>().selectProject(project),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.question,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      Text('Datasets: ${project.datasetCount}'),
                      Text('Evidence: ${project.evidenceCount}'),
                      Text('Hypotheses: ${project.hypothesisCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.selectedCard
                      : AppTheme.accentSoft.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selected ? 'Selected' : project.status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              IconButton(
                tooltip: 'Delete project',
                onPressed: () => _confirmDelete(context, project),
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project project) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete project?'),
          content: Text('Do you really want to delete "${project.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<AppState>().removeProject(project);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectDetail extends StatefulWidget {
  final Project project;

  const _ProjectDetail({required this.project});

  @override
  State<_ProjectDetail> createState() => _ProjectDetailState();
}

class _ProjectDetailState extends State<_ProjectDetail> {
  late final TextEditingController notesController;
  final TextEditingController hypothesisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    notesController = TextEditingController(text: widget.project.notes);
  }

  @override
  void didUpdateWidget(covariant _ProjectDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) {
      notesController.text = widget.project.notes;
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    hypothesisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hypotheses = state.hypothesesForProject(widget.project.id);
    final papers = state.papersForProject(widget.project.id);

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.question,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'Datasets', value: '${widget.project.datasetCount}')),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(title: 'Evidence', value: '${widget.project.evidenceCount}')),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(title: 'Hypotheses', value: '${widget.project.hypothesisCount}')),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Project notes',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    context.read<AppState>().updateProjectNotes(
                          widget.project.id,
                          notesController.text,
                        );
                  },
                  child: const Text('Save notes'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add hypothesis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hypothesisController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a new hypothesis',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    final text = hypothesisController.text.trim();
                    if (text.isEmpty) return;
                    context.read<AppState>().addHypothesis(title: text);
                    hypothesisController.clear();
                  },
                  child: const Text('Add hypothesis'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hypotheses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (hypotheses.isEmpty)
                const Text(
                  'No hypotheses linked yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                )
              else
                ...hypotheses.map(
                  (hypothesis) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(hypothesis.title),
                    subtitle: Text('Evidence: ${hypothesis.evidenceStrength}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hypothesis.status),
                        IconButton(
                          onPressed: () {
                            context.read<AppState>().deleteHypothesis(hypothesis);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Linked evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (papers.isEmpty)
                const Text(
                  'No papers linked yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                )
              else
                ...papers.take(5).map(
                      (paper) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paper.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${paper.journal} · ${paper.year}',
                              style: const TextStyle(color: AppTheme.mutedText),
                            ),
                            Text(
                              paper.summary,
                              style: const TextStyle(color: AppTheme.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

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
