import 'dart:math';

import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../theme/app_theme.dart';

class AnalysisChart extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisChart({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result.chartKind == 'none' || result.chartPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: CustomPaint(
        painter: _AnalysisChartPainter(result),
      ),
    );
  }
}

class _AnalysisChartPainter extends CustomPainter {
  final AnalysisResult result;

  _AnalysisChartPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    final points = result.chartPoints;
    if (points.isEmpty) return;

    final padding = const EdgeInsets.fromLTRB(42, 18, 18, 38);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    final axisPaint = Paint()
      ..color = AppTheme.borderStrong
      ..strokeWidth = 1.2;

    canvas.drawLine(chartRect.bottomLeft, chartRect.bottomRight, axisPaint);
    canvas.drawLine(chartRect.bottomLeft, chartRect.topLeft, axisPaint);

    if (result.chartKind == 'scatter') {
      _drawScatter(canvas, chartRect, points);
    } else if (result.chartKind == 'line') {
      _drawLine(canvas, chartRect, points);
    } else {
      _drawBars(canvas, chartRect, points);
    }
  }

  void _drawScatter(Canvas canvas, Rect rect, List<ChartPoint> points) {
    final paint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;

    final xs = points.map((p) => p.x).toList();
    final ys = points.map((p) => p.y).toList();

    final minX = xs.reduce(min);
    final maxX = xs.reduce(max);
    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);

    for (final point in points) {
      final xNorm = maxX == minX ? 0.5 : (point.x - minX) / (maxX - minX);
      final yNorm = maxY == minY ? 0.5 : (point.y - minY) / (maxY - minY);

      final x = rect.left + xNorm * rect.width;
      final y = rect.bottom - yNorm * rect.height;

      canvas.drawCircle(Offset(x, y), 3.2, paint);
    }
  }

  void _drawLine(Canvas canvas, Rect rect, List<ChartPoint> points) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final dotPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;

    final xs = points.map((p) => p.x).toList();
    final ys = points.map((p) => p.y).toList();

    final minX = xs.reduce(min);
    final maxX = xs.reduce(max);
    final minY = ys.reduce(min);
    final maxY = ys.reduce(max);

    Offset project(ChartPoint point) {
      final xNorm = maxX == minX ? 0.5 : (point.x - minX) / (maxX - minX);
      final yNorm = maxY == minY ? 0.5 : (point.y - minY) / (maxY - minY);
      final x = rect.left + xNorm * rect.width;
      final y = rect.bottom - yNorm * rect.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(project(points.first).dx, project(points.first).dy);

    for (final point in points.skip(1)) {
      final p = project(point);
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(project(point), 2.8, dotPaint);
    }
  }

  void _drawBars(Canvas canvas, Rect rect, List<ChartPoint> points) {
    final paint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    final maxY = points.map((p) => p.y).reduce(max);
    final count = points.length;
    final gap = 4.0;
    final barWidth = max(2.0, (rect.width - gap * (count - 1)) / count);

    for (var i = 0; i < count; i++) {
      final point = points[i];
      final h = maxY == 0 ? 0.0 : (point.y / maxY) * rect.height;
      final left = rect.left + i * (barWidth + gap);
      final top = rect.bottom - h;

      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, paint);

      if (count <= 16 && point.label != null) {
        labelPainter.text = TextSpan(
          text: point.label!,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 9,
          ),
        );
        labelPainter.layout(maxWidth: max(30, barWidth * 3));
        canvas.save();
        canvas.translate(left, rect.bottom + 6);
        labelPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnalysisChartPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
