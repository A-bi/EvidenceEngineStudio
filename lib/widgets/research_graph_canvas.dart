import 'dart:math';

import 'package:flutter/material.dart';

import '../models/research_node.dart';
import '../models/research_relation.dart';
import '../theme/app_theme.dart';

class ResearchGraphCanvas extends StatelessWidget {
  final List<ResearchNode> nodes;
  final List<ResearchRelation> relations;
  final ValueChanged<ResearchNode>? onNodeTap;
  final void Function(ResearchNode node, double x, double y)? onNodeMoved;

  const ResearchGraphCanvas({
    super.key,
    required this.nodes,
    required this.relations,
    this.onNodeTap,
    this.onNodeMoved,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ResearchGraphPainter(
                    nodes: nodes,
                    relations: relations,
                  ),
                ),
              ),
              ...nodes.map(
                (node) {
                  final left = node.x * constraints.maxWidth;
                  final top = node.y * constraints.maxHeight;

                  return Positioned(
                    left: left - 90,
                    top: top - 34,
                    width: 180,
                    child: Draggable<ResearchNode>(
                      data: node,
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 180,
                          child: _GraphNodeCard(node: node, isDragging: true),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _GraphNodeCard(node: node),
                      ),
                      onDragEnd: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;

                        final local = box.globalToLocal(details.offset);
                        final x = (local.dx + 90) / constraints.maxWidth;
                        final y = (local.dy + 34) / constraints.maxHeight;

                        onNodeMoved?.call(node, x, y);
                      },
                      child: _GraphNodeCard(
                        node: node,
                        onTap: () => onNodeTap?.call(node),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GraphNodeCard extends StatelessWidget {
  final ResearchNode node;
  final VoidCallback? onTap;
  final bool isDragging;

  const _GraphNodeCard({
    required this.node,
    this.onTap,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForKind(node.kind, node.colorHex);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.card.withOpacity(isDragging ? 0.82 : 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDragging ? 0.18 : 0.08),
              blurRadius: isDragging ? 20 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withOpacity(0.22),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: color.withOpacity(0.7)),
              ),
              child: Icon(
                _iconForKind(node.kind),
                size: 15,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForKind(ResearchNodeKind kind, String? customHex) {
    if (customHex != null) {
      final parsed = _colorFromHex(customHex);
      if (parsed != null) return parsed;
    }

    switch (kind) {
      case ResearchNodeKind.project:
        return AppTheme.accent;
      case ResearchNodeKind.dataset:
        return Colors.blueGrey;
      case ResearchNodeKind.hypothesis:
        return Colors.deepPurple;
      case ResearchNodeKind.paper:
        return Colors.teal;
      case ResearchNodeKind.analysis:
        return Colors.orange;
      case ResearchNodeKind.note:
        return Colors.indigo;
    }
  }

  Color? _colorFromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6) return null;
    final value = int.tryParse('FF$normalized', radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  IconData _iconForKind(ResearchNodeKind kind) {
    switch (kind) {
      case ResearchNodeKind.project:
        return Icons.folder_rounded;
      case ResearchNodeKind.dataset:
        return Icons.table_chart_rounded;
      case ResearchNodeKind.hypothesis:
        return Icons.lightbulb_rounded;
      case ResearchNodeKind.paper:
        return Icons.menu_book_rounded;
      case ResearchNodeKind.analysis:
        return Icons.monitor_heart_rounded;
      case ResearchNodeKind.note:
        return Icons.sticky_note_2_rounded;
    }
  }
}

class _ResearchGraphPainter extends CustomPainter {
  final List<ResearchNode> nodes;
  final List<ResearchRelation> relations;

  _ResearchGraphPainter({
    required this.nodes,
    required this.relations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = AppTheme.canvas.withOpacity(0.96)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );

    canvas.drawRRect(rect, backgroundPaint);
    canvas.drawRRect(rect, borderPaint);

    final gridPaint = Paint()
      ..color = AppTheme.border.withOpacity(0.32)
      ..strokeWidth = 0.7;

    for (double x = 40; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final nodeById = {for (final node in nodes) node.id: node};

    for (final relation in relations) {
      final source = nodeById[relation.sourceId];
      final target = nodeById[relation.targetId];

      if (source == null || target == null) continue;

      final p1 = Offset(source.x * size.width, source.y * size.height);
      final p2 = Offset(target.x * size.width, target.y * size.height);

      final paint = Paint()
        ..color = _relationColor(relation.kind).withOpacity(0.68)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(p1.dx, p1.dy);
      final midY = (p1.dy + p2.dy) / 2;

      path.cubicTo(
        p1.dx,
        midY,
        p2.dx,
        midY,
        p2.dx,
        p2.dy,
      );

      canvas.drawPath(path, paint);
      _drawArrow(canvas, p1, p2, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset source, Offset target, Paint paint) {
    final direction = (target - source);
    if (direction.distance == 0) return;

    final unit = direction / direction.distance;
    final end = target - unit * 88;
    final angle = unit.direction;

    const arrowSize = 8.0;

    final p1 = end;
    final p2 = Offset(
      end.dx - arrowSize * cos(angle - 0.45),
      end.dy - arrowSize * sin(angle - 0.45),
    );
    final p3 = Offset(
      end.dx - arrowSize * cos(angle + 0.45),
      end.dy - arrowSize * sin(angle + 0.45),
    );

    final arrow = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p3.dx, p3.dy);

    canvas.drawPath(arrow, paint);
  }

  Color _relationColor(ResearchRelationKind kind) {
    switch (kind) {
      case ResearchRelationKind.supports:
        return Colors.green;
      case ResearchRelationKind.contradicts:
        return Colors.red;
      case ResearchRelationKind.open:
        return Colors.orange;
      case ResearchRelationKind.basedOn:
        return Colors.blueGrey;
      case ResearchRelationKind.testedBy:
        return Colors.deepOrange;
      case ResearchRelationKind.linkedTo:
        return AppTheme.accent;
    }
  }

  @override
  bool shouldRepaint(covariant _ResearchGraphPainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.relations != relations;
  }
}
