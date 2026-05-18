import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_section.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<AppSection>? onNavigate;

  const HomeScreen({
    super.key,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroSection(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _MetricCard(title: 'Projects', value: '${state.projects.length}'),
                _MetricCard(title: 'Datasets', value: '${state.datasets.length}'),
                _MetricCard(title: 'Papers', value: '${state.papers.length}'),
                _MetricCard(title: 'Hypotheses', value: '${state.hypotheses.length}'),
              ];

              if (constraints.maxWidth < 760) {
                return Column(
                  children: cards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ))
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _quickActions(),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _activeProjects(),
                    const SizedBox(height: 16),
                    _researchSnapshot(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _activeProjects()),
                  const SizedBox(width: 16),
                  Expanded(child: _researchSnapshot()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _heroSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Research cosmos',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'A calm green environment where data, evidence, hypotheses, analysis, and writing converge into one research space.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _HeroBadge('Nature interface'),
              _HeroBadge('Local statistics'),
              _HeroBadge('Evidence dock'),
              _HeroBadge('Research memory'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                label: 'Projects',
                icon: Icons.folder_rounded,
                onTap: () => onNavigate?.call(AppSection.projects),
              ),
              _QuickActionButton(
                label: 'Data',
                icon: Icons.table_chart_rounded,
                onTap: () => onNavigate?.call(AppSection.data),
              ),
              _QuickActionButton(
                label: 'Analysis',
                icon: Icons.monitor_heart_rounded,
                onTap: () => onNavigate?.call(AppSection.analysis),
              ),
              _QuickActionButton(
                label: 'Writing',
                icon: Icons.edit_square,
                onTap: () => onNavigate?.call(AppSection.writing),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activeProjects() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active projects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (state.projects.isEmpty)
                const Text(
                  'No projects yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                )
              else
                ...state.projects.map(
                  (project) {
                    final selected = state.selectedProject?.id == project.id;
                    return InkWell(
                      onTap: () => state.selectProject(project),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.selectedCard
                              : AppTheme.canvas.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppTheme.borderStrong
                                : AppTheme.border,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 260;

                            final textBlock = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  project.question,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                              ],
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  textBlock,
                                  const SizedBox(height: 8),
                                  _StatusPill(project.status),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: textBlock),
                                const SizedBox(width: 8),
                                _StatusPill(project.status),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _researchSnapshot() {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final project = state.selectedProject;
        final dataset = state.selectedDataset;
        final hypotheses = state.hypothesesForProject(project?.id);
        final papers = state.papersForProject(project?.id);

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current research focus',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              if (project == null)
                const Text(
                  'No project selected.',
                  style: TextStyle(color: AppTheme.secondaryText),
                )
              else ...[
                Text(
                  project.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  project.question,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoLine(
                  label: 'Dataset',
                  value: dataset?.name ?? 'No dataset selected',
                ),
                _InfoLine(
                  label: 'Hypotheses',
                  value: '${hypotheses.length}',
                ),
                _InfoLine(
                  label: 'Linked papers',
                  value: '${papers.length}',
                ),
                if (project.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
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

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
