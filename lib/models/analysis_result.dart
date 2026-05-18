class ChartPoint {
  final double x;
  final double y;
  final String? label;

  ChartPoint({
    required this.x,
    required this.y,
    this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'label': label,
    };
  }
}

class AnalysisResult {
  final String analysis;
  final String? outcome;
  final String? predictor;
  final String? group;
  final int n;

  final Map<String, double>? metrics;
  final Map<String, int>? categoryCounts;

  final String chartKind;
  final List<ChartPoint> chartPoints;
  String? plotPath;

  final String interpretation;
  final String? warning;
  final String? error;

  AnalysisResult({
    required this.analysis,
    this.outcome,
    this.predictor,
    this.group,
    required this.n,
    this.metrics,
    this.categoryCounts,
    this.chartKind = 'none',
    this.chartPoints = const [],
    this.plotPath,
    required this.interpretation,
    this.warning,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'outcome': outcome,
      'predictor': predictor,
      'group': group,
      'n': n,
      'metrics': metrics,
      'categoryCounts': categoryCounts,
      'chartKind': chartKind,
      'chartPoints': chartPoints.map((e) => e.toJson()).toList(),
      'plotPath': plotPath,
      'interpretation': interpretation,
      'warning': warning,
      'error': error,
    };
  }
}
