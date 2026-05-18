import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hypothesis_node.dart';
import '../../models/research_node.dart';
import '../../models/research_relation.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/research_graph_canvas.dart';
import '../../widgets/section_header.dart';

class HypothesesScreen extends StatefulWidget {
  const HypothesesScreen({super.key});

  @override
  State<HypothesesScreen> createState() => _HypothesesScreenState();
}

class _HypothesesScreenState extends State<HypothesesScreen> {
  ResearchNode? selectedNode;
  ResearchNode? connectionStart;
  ResearchRelationKind selectedRelationKind = ResearchRelationKind.linkedTo;

  String selectedColor = '#477D54';
  ResearchNodeKind selectedBoxKind = ResearchNodeKind.note;

  final titleController = TextEditingController();
  final subtitleController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nodes = state.researchNodesForSelectedProject();
    final relations = state.relationsForSelectedProjectGraph();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Research Graph',
            subtitle:
                'Move boxes, add thoughts, choose colors, and connect concepts in your research network.',
          ),
          const SizedBox(height: 14),
          _compactToolbar(nodes),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GraphStatusBar(
                  nodes: nodes.length,
                  relations: relations.length,
                  selected: selectedNode,
                  connectionStart: connectionStart,
                ),
                const SizedBox(height: 12),
                ResearchGraphCanvas(
                  nodes: nodes,
                  relations: relations,
                  onNodeTap: _handleNodeTap,
                  onNodeMoved: (node, x, y) {
                    context.read<AppState>().updateCanvasBoxPosition(node.id, x, y);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _bottomPanels(nodes, relations),
        ],
      ),
    );
  }

  Widget _compactToolbar(List<ResearchNode> nodes) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Box title',
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: subtitleController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Subtitle',
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<ResearchNodeKind>(
              value: selectedBoxKind,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Type',
              ),
              items: ResearchNodeKind.values
                  .where((kind) => kind != ResearchNodeKind.project)
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedBoxKind = value);
              },
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: selectedColor,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Color',
              ),
              items: const [
                DropdownMenuItem(value: '#477D54', child: Text('Green')),
                DropdownMenuItem(value: '#6A5ACD', child: Text('Purple')),
                DropdownMenuItem(value: '#008B8B', child: Text('Teal')),
                DropdownMenuItem(value: '#FF8C00', child: Text('Orange')),
                DropdownMenuItem(value: '#B22222', child: Text('Red')),
                DropdownMenuItem(value: '#4169E1', child: Text('Blue')),
                DropdownMenuItem(value: '#2F4F4F', child: Text('Slate')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedColor = value);
              },
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              context.read<AppState>().addCanvasBox(
                    title: title,
                    subtitle: subtitleController.text.trim(),
                    kind: selectedBoxKind,
                    colorHex: selectedColor,
                  );

              titleController.clear();
              subtitleController.clear();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add box'),
          ),
          OutlinedButton.icon(
            onPressed: selectedNode == null
                ? null
                : () {
                    setState(() {
                      connectionStart = selectedNode;
                    });
                  },
            icon: const Icon(Icons.link_rounded),
            label: const Text('Start link'),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<ResearchRelationKind>(
              value: selectedRelationKind,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Link type',
              ),
              items: ResearchRelationKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedRelationKind = value);
              },
            ),
          ),
          if (selectedNode != null)
            OutlinedButton.icon(
              onPressed: () {
                context.read<AppState>().updateCanvasBoxColor(
                      selectedNode!.id,
                      selectedColor,
                    );
              },
              icon: const Icon(Icons.palette_rounded),
              label: const Text('Color selected'),
            ),
          if (selectedNode != null)
            TextButton.icon(
              onPressed: () {
                context.read<AppState>().removeCanvasBox(selectedNode!.id);
                setState(() => selectedNode = null);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete selected'),
            ),
        ],
      ),
    );
  }

  void _handleNodeTap(ResearchNode node) {
    final state = context.read<AppState>();

    if (connectionStart != null && connectionStart!.id != node.id) {
      state.connectNodes(
        connectionStart!.id,
        node.id,
        selectedRelationKind,
      );

      setState(() {
        selectedNode = node;
        connectionStart = null;
      });
      return;
    }

    setState(() {
      selectedNode = node;
    });
  }

  Widget _bottomPanels(
    List<ResearchNode> nodes,
    List<ResearchRelation> relations,
  ) {
    final state = context.watch<AppState>();
    final project = state.selectedProject;
    final hypotheses = state.hypothesesForProject(project?.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              _NodeInspectorCard(node: selectedNode),
              const SizedBox(height: 16),
              _HypothesesListCard(hypotheses: hypotheses),
              const SizedBox(height: 16),
              _RelationsListCard(relations: relations, nodes: nodes),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _NodeInspectorCard(node: selectedNode)),
            const SizedBox(width: 16),
            Expanded(child: _HypothesesListCard(hypotheses: hypotheses)),
            const SizedBox(width: 16),
            Expanded(child: _RelationsListCard(relations: relations, nodes: nodes)),
          ],
        );
      },
    );
  }
}

class _GraphStatusBar extends StatelessWidget {
  final int nodes;
  final int relations;
  final ResearchNode? selected;
  final ResearchNode? connectionStart;

  const _GraphStatusBar({
    required this.nodes,
    required this.relations,
    required this.selected,
    required this.connectionStart,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill('Nodes', '$nodes'),
        _Pill('Relations', '$relations'),
        if (selected != null) _Pill('Selected', selected!.title),
        if (connectionStart != null)
          _Pill('Link from', connectionStart!.title, warning: true),
        const Text(
          'Tip: Drag custom boxes. Click a node, press Start link, then click another node.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _NodeInspectorCard extends StatelessWidget {
  final ResearchNode? node;

  const _NodeInspectorCard({required this.node});

  @override
  Widget build(BuildContext context) {
    if (node == null) {
      return const GlassCard(
        child: Text(
          'Select a node to inspect it.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.secondaryText,
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node!.kind.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            node!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            node!.subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryText,
            ),
          ),
          if (node!.colorHex != null) ...[
            const SizedBox(height: 12),
            _Pill('Color', node!.colorHex!),
          ],
        ],
      ),
    );
  }
}

class _HypothesesListCard extends StatelessWidget {
  final List<HypothesisNode> hypotheses;

  const _HypothesesListCard({required this.hypotheses});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hypotheses (${hypotheses.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (hypotheses.isEmpty)
            const Text(
              'No hypotheses yet.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            )
          else
            ...hypotheses.take(8).map(
                  (hypothesis) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '• ${hypothesis.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RelationsListCard extends StatelessWidget {
  final List<ResearchRelation> relations;
  final List<ResearchNode> nodes;

  const _RelationsListCard({
    required this.relations,
    required this.nodes,
  });

  @override
  Widget build(BuildContext context) {
    final nodeById = {for (final node in nodes) node.id: node};

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relations (${relations.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (relations.isEmpty)
            const Text(
              'No relations yet.',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            )
          else
            ...relations.take(12).map(
                  (relation) {
                    final source = nodeById[relation.sourceId];
                    final target = nodeById[relation.targetId];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${source?.title ?? relation.sourceId} → ${target?.title ?? relation.targetId} · ${relation.kind.displayName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;

  const _Pill(
    this.label,
    this.value, {
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: warning
            ? AppTheme.warning.withOpacity(0.18)
            : AppTheme.accentSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}
