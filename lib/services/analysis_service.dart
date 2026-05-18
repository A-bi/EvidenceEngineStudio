import 'dart:math';

import '../models/analysis_result.dart';
import '../models/dataset_summary.dart';

enum AnalysisMethod {
  descriptive,
  pearson,
  spearman,
  welchTTest,
  mannWhitneyU,
  pairedTTest,
  wilcoxonSignedRank,
  chiSquare,
  fisherExact2x2,
  kruskalWallis,
  simpleLinearRegression,
  multipleLinearRegression,
  logisticRegression,
  rocAuc,
  diagnosticMetrics,
  riskComparison,
  kaplanMeier,
  logRank,
  normalityJarqueBera,
  residualDiagnostics,
}

extension AnalysisMethodInfo on AnalysisMethod {
  String get label {
    switch (this) {
      case AnalysisMethod.descriptive:
        return 'Descriptive statistics';
      case AnalysisMethod.pearson:
        return 'Pearson correlation';
      case AnalysisMethod.spearman:
        return 'Spearman correlation';
      case AnalysisMethod.welchTTest:
        return 'Welch t-test';
      case AnalysisMethod.mannWhitneyU:
        return 'Mann-Whitney U';
      case AnalysisMethod.pairedTTest:
        return 'Paired t-test';
      case AnalysisMethod.wilcoxonSignedRank:
        return 'Wilcoxon signed-rank';
      case AnalysisMethod.chiSquare:
        return 'Chi-square';
      case AnalysisMethod.fisherExact2x2:
        return 'Fisher exact 2x2';
      case AnalysisMethod.kruskalWallis:
        return 'Kruskal-Wallis';
      case AnalysisMethod.simpleLinearRegression:
        return 'Simple linear regression';
      case AnalysisMethod.multipleLinearRegression:
        return 'Multiple regression';
      case AnalysisMethod.logisticRegression:
        return 'Logistic regression';
      case AnalysisMethod.rocAuc:
        return 'ROC / AUC';
      case AnalysisMethod.diagnosticMetrics:
        return 'Diagnostic metrics';
      case AnalysisMethod.riskComparison:
        return 'Risk comparison';
      case AnalysisMethod.kaplanMeier:
        return 'Kaplan-Meier';
      case AnalysisMethod.logRank:
        return 'Log-rank';
      case AnalysisMethod.normalityJarqueBera:
        return 'Normality / Jarque-Bera';
      case AnalysisMethod.residualDiagnostics:
        return 'Residual diagnostics';
    }
  }

  bool get needsPredictor {
    return {
      AnalysisMethod.pearson,
      AnalysisMethod.spearman,
      AnalysisMethod.pairedTTest,
      AnalysisMethod.wilcoxonSignedRank,
      AnalysisMethod.simpleLinearRegression,
      AnalysisMethod.multipleLinearRegression,
      AnalysisMethod.logisticRegression,
      AnalysisMethod.rocAuc,
      AnalysisMethod.diagnosticMetrics,
      AnalysisMethod.kaplanMeier,
      AnalysisMethod.logRank,
      AnalysisMethod.residualDiagnostics,
    }.contains(this);
  }

  bool get needsGroup {
    return {
      AnalysisMethod.welchTTest,
      AnalysisMethod.mannWhitneyU,
      AnalysisMethod.chiSquare,
      AnalysisMethod.fisherExact2x2,
      AnalysisMethod.kruskalWallis,
      AnalysisMethod.riskComparison,
      AnalysisMethod.logRank,
    }.contains(this);
  }

  bool get outcomeShouldBeNumeric {
    return {
      AnalysisMethod.pearson,
      AnalysisMethod.spearman,
      AnalysisMethod.welchTTest,
      AnalysisMethod.mannWhitneyU,
      AnalysisMethod.pairedTTest,
      AnalysisMethod.wilcoxonSignedRank,
      AnalysisMethod.kruskalWallis,
      AnalysisMethod.simpleLinearRegression,
      AnalysisMethod.multipleLinearRegression,
      AnalysisMethod.kaplanMeier,
      AnalysisMethod.logRank,
      AnalysisMethod.normalityJarqueBera,
      AnalysisMethod.residualDiagnostics,
    }.contains(this);
  }

  bool get predictorShouldBeNumeric {
    return {
      AnalysisMethod.pearson,
      AnalysisMethod.spearman,
      AnalysisMethod.pairedTTest,
      AnalysisMethod.wilcoxonSignedRank,
      AnalysisMethod.simpleLinearRegression,
      AnalysisMethod.multipleLinearRegression,
      AnalysisMethod.logisticRegression,
      AnalysisMethod.rocAuc,
      AnalysisMethod.kaplanMeier,
      AnalysisMethod.logRank,
      AnalysisMethod.residualDiagnostics,
    }.contains(this);
  }
}

class AnalysisService {
  AnalysisService._();

  static final AnalysisService instance = AnalysisService._();

  AnalysisResult run({
    required AnalysisMethod method,
    required DatasetSummary summary,
    required String outcome,
    String? predictor,
    String? group,
  }) {
    switch (method) {
      case AnalysisMethod.descriptive:
        return descriptive(summary: summary, variable: outcome);
      case AnalysisMethod.pearson:
        return pearson(summary: summary, xVariable: outcome, yVariable: predictor);
      case AnalysisMethod.spearman:
        return spearman(summary: summary, xVariable: outcome, yVariable: predictor);
      case AnalysisMethod.welchTTest:
        return welchTTest(summary: summary, outcome: outcome, group: group);
      case AnalysisMethod.mannWhitneyU:
        return mannWhitneyU(summary: summary, outcome: outcome, group: group);
      case AnalysisMethod.pairedTTest:
        return pairedTTest(summary: summary, first: outcome, second: predictor);
      case AnalysisMethod.wilcoxonSignedRank:
        return wilcoxonSignedRank(summary: summary, first: outcome, second: predictor);
      case AnalysisMethod.chiSquare:
        return chiSquare(summary: summary, variableA: outcome, variableB: group);
      case AnalysisMethod.fisherExact2x2:
        return fisherExact2x2(summary: summary, variableA: outcome, variableB: group);
      case AnalysisMethod.kruskalWallis:
        return kruskalWallis(summary: summary, outcome: outcome, group: group);
      case AnalysisMethod.simpleLinearRegression:
        return simpleLinearRegression(summary: summary, outcome: outcome, predictor: predictor);
      case AnalysisMethod.multipleLinearRegression:
        return multipleLinearRegression(summary: summary, outcome: outcome, predictor: predictor);
      case AnalysisMethod.logisticRegression:
        return logisticRegression(summary: summary, outcome: outcome, predictor: predictor);
      case AnalysisMethod.rocAuc:
        return rocAuc(summary: summary, outcome: outcome, predictor: predictor);
      case AnalysisMethod.diagnosticMetrics:
        return diagnosticMetrics(summary: summary, truth: outcome, test: predictor);
      case AnalysisMethod.riskComparison:
        return riskComparison(summary: summary, outcome: outcome, group: group);
      case AnalysisMethod.kaplanMeier:
        return kaplanMeier(summary: summary, time: outcome, event: predictor);
      case AnalysisMethod.logRank:
        return logRank(summary: summary, time: outcome, event: predictor, group: group);
      case AnalysisMethod.normalityJarqueBera:
        return normalityJarqueBera(summary: summary, variable: outcome);
      case AnalysisMethod.residualDiagnostics:
        return residualDiagnostics(summary: summary, outcome: outcome, predictor: predictor);
    }
  }

  List<Map<String, dynamic>> _rows(DatasetSummary summary) {
    return summary.rowsData ?? summary.preview ?? [];
  }

  List<double> _numericColumn(DatasetSummary summary, String variable) {
    return _rows(summary)
        .map((row) => row[variable])
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => double.tryParse(value.toString().replaceAll(',', '.')))
        .whereType<double>()
        .toList();
  }

  List<String> _stringColumn(DatasetSummary summary, String variable) {
    return _rows(summary)
        .map((row) => row[variable])
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .toList();
  }

  List<(double, double)> _numericPairs(DatasetSummary summary, String a, String b) {
    final pairs = <(double, double)>[];
    for (final row in _rows(summary)) {
      final x = double.tryParse('${row[a]}'.replaceAll(',', '.'));
      final y = double.tryParse('${row[b]}'.replaceAll(',', '.'));
      if (x != null && y != null) pairs.add((x, y));
    }
    return pairs;
  }

  double? _binaryValue(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    if (['1', 'true', 'yes', 'ja', 'positive', 'pos', 'case', 'event', 'dead', 'died'].contains(s)) return 1.0;
    if (['0', 'false', 'no', 'nein', 'negative', 'neg', 'control', 'none', 'alive'].contains(s)) return 0.0;
    final n = double.tryParse(s.replaceAll(',', '.'));
    if (n == null) return null;
    return n > 0 ? 1.0 : 0.0;
  }

  AnalysisResult _error({
    required String analysis,
    String? outcome,
    String? predictor,
    String? group,
    required String message,
  }) {
    return AnalysisResult(
      analysis: analysis,
      outcome: outcome,
      predictor: predictor,
      group: group,
      n: 0,
      interpretation: message,
      error: message,
    );
  }

  AnalysisResult descriptive({required DatasetSummary summary, required String variable}) {
    final rows = _rows(summary);
    if (rows.isEmpty) {
      return _error(analysis: 'Descriptive statistics', outcome: variable, message: 'No rows are available.');
    }

    final rawValues = rows
        .map((row) => row[variable])
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .toList();

    final numericValues = rawValues
        .map((value) => double.tryParse(value.toString().replaceAll(',', '.')))
        .whereType<double>()
        .toList();

    final isMostlyNumeric = rawValues.isNotEmpty && numericValues.length / rawValues.length >= 0.8;

    if (isMostlyNumeric) {
      numericValues.sort();
      final mean = _mean(numericValues);
      final median = _median(numericValues);
      final sd = sqrt(_variance(numericValues));

      return AnalysisResult(
        analysis: 'Descriptive statistics',
        outcome: variable,
        n: numericValues.length,
        metrics: {
          'mean': mean,
          'median': median,
          'sd': sd,
          'min': numericValues.first,
          'max': numericValues.last,
        },
        chartKind: 'histogram',
        chartPoints: _histogram(numericValues, bins: 12),
        interpretation: '$variable is numeric. Mean ${mean.toStringAsFixed(3)}, median ${median.toStringAsFixed(3)}, SD ${sd.toStringAsFixed(3)}.',
      );
    }

    final counts = <String, int>{};
    for (final value in rawValues) {
      counts[value.toString()] = (counts[value.toString()] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return AnalysisResult(
      analysis: 'Category counts',
      outcome: variable,
      n: rawValues.length,
      categoryCounts: Map.fromEntries(sorted),
      chartKind: 'bar',
      chartPoints: sorted.take(20).map((e) => ChartPoint(x: 0, y: e.value.toDouble(), label: e.key)).toList(),
      interpretation: '$variable is categorical/text-like. ${counts.length} unique value(s) found.',
    );
  }

  AnalysisResult pearson({required DatasetSummary summary, required String xVariable, String? yVariable}) {
    if (yVariable == null || yVariable.isEmpty || yVariable == xVariable) {
      return _error(analysis: 'Pearson correlation', outcome: xVariable, predictor: yVariable, message: 'Choose two different numeric variables.');
    }
    final pairs = _numericPairs(summary, xVariable, yVariable);
    if (pairs.length < 3) {
      return _error(analysis: 'Pearson correlation', outcome: xVariable, predictor: yVariable, message: 'At least 3 paired numeric observations are required.');
    }
    final xs = pairs.map((p) => p.$1).toList();
    final ys = pairs.map((p) => p.$2).toList();
    final r = _pearson(xs, ys);
    return AnalysisResult(
      analysis: 'Pearson correlation',
      outcome: xVariable,
      predictor: yVariable,
      n: pairs.length,
      metrics: {'r': r, 'r_squared': r * r},
      chartKind: 'scatter',
      chartPoints: pairs.map((p) => ChartPoint(x: p.$1, y: p.$2)).toList(),
      interpretation: 'Pearson correlation between $xVariable and $yVariable: r = ${r.toStringAsFixed(3)}.',
    );
  }

  AnalysisResult spearman({required DatasetSummary summary, required String xVariable, String? yVariable}) {
    if (yVariable == null || yVariable.isEmpty || yVariable == xVariable) {
      return _error(analysis: 'Spearman correlation', outcome: xVariable, predictor: yVariable, message: 'Choose two different numeric variables.');
    }
    final pairs = _numericPairs(summary, xVariable, yVariable);
    if (pairs.length < 3) {
      return _error(analysis: 'Spearman correlation', outcome: xVariable, predictor: yVariable, message: 'At least 3 paired numeric observations are required.');
    }
    final rx = _rank(pairs.map((p) => p.$1).toList());
    final ry = _rank(pairs.map((p) => p.$2).toList());
    final rho = _pearson(rx, ry);
    return AnalysisResult(
      analysis: 'Spearman correlation',
      outcome: xVariable,
      predictor: yVariable,
      n: pairs.length,
      metrics: {'rho': rho},
      chartKind: 'scatter',
      chartPoints: pairs.map((p) => ChartPoint(x: p.$1, y: p.$2)).toList(),
      interpretation: 'Spearman correlation between $xVariable and $yVariable: ρ = ${rho.toStringAsFixed(3)}.',
    );
  }

  AnalysisResult welchTTest({required DatasetSummary summary, required String outcome, String? group}) {
    final groups = _numericByGroup(summary, outcome, group);
    if (groups.length != 2) {
      return _error(analysis: 'Welch t-test', outcome: outcome, group: group, message: 'Welch t-test requires exactly two groups.');
    }
    final entries = groups.entries.toList();
    final a = entries[0].value;
    final b = entries[1].value;
    if (a.length < 2 || b.length < 2) {
      return _error(analysis: 'Welch t-test', outcome: outcome, group: group, message: 'Each group needs at least two numeric observations.');
    }
    final meanA = _mean(a);
    final meanB = _mean(b);
    final varA = _variance(a);
    final varB = _variance(b);
    final t = (meanB - meanA) / sqrt(varA / a.length + varB / b.length);
    final pooled = sqrt((varA + varB) / 2.0);
    final d = pooled == 0 ? 0.0 : (meanB - meanA) / pooled;

    return AnalysisResult(
      analysis: 'Welch t-test',
      outcome: outcome,
      group: group,
      n: a.length + b.length,
      metrics: {
        '${entries[0].key}_mean': meanA,
        '${entries[1].key}_mean': meanB,
        'mean_difference': meanB - meanA,
        't_statistic': t,
        'cohen_d': d,
      },
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: meanA, label: entries[0].key),
        ChartPoint(x: 1, y: meanB, label: entries[1].key),
      ],
      interpretation: 'Welch t-test comparing $outcome by $group: mean difference ${(meanB - meanA).toStringAsFixed(3)}, t = ${t.toStringAsFixed(3)}, Cohen d = ${d.toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult mannWhitneyU({required DatasetSummary summary, required String outcome, String? group}) {
    final groups = _numericByGroup(summary, outcome, group);
    if (groups.length != 2) {
      return _error(analysis: 'Mann-Whitney U', outcome: outcome, group: group, message: 'Mann-Whitney U requires exactly two groups.');
    }
    final entries = groups.entries.toList();
    final a = entries[0].value;
    final b = entries[1].value;
    if (a.isEmpty || b.isEmpty) {
      return _error(analysis: 'Mann-Whitney U', outcome: outcome, group: group, message: 'Both groups need observations.');
    }

    final combined = <({double value, int group})>[];
    combined.addAll(a.map((v) => (value: v, group: 0)));
    combined.addAll(b.map((v) => (value: v, group: 1)));
    combined.sort((x, y) => x.value.compareTo(y.value));

    final ranks = _rank(combined.map((e) => e.value).toList());
    var rankA = 0.0;
    for (var i = 0; i < combined.length; i++) {
      if (combined[i].group == 0) rankA += ranks[i];
    }

    final n1 = a.length.toDouble();
    final n2 = b.length.toDouble();
    final u1 = rankA - n1 * (n1 + 1) / 2;
    final u2 = n1 * n2 - u1;
    final u = min(u1, u2);

    return AnalysisResult(
      analysis: 'Mann-Whitney U',
      outcome: outcome,
      group: group,
      n: a.length + b.length,
      metrics: {'U': u, 'U1': u1, 'U2': u2, 'group1_median': _medianSortedCopy(a), 'group2_median': _medianSortedCopy(b)},
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: _medianSortedCopy(a), label: entries[0].key),
        ChartPoint(x: 1, y: _medianSortedCopy(b), label: entries[1].key),
      ],
      interpretation: 'Mann-Whitney U comparing $outcome by $group: U = ${u.toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult pairedTTest({required DatasetSummary summary, required String first, String? second}) {
    final pairs = _numericPairs(summary, first, second ?? '');
    if (pairs.length < 2) {
      return _error(analysis: 'Paired t-test', outcome: first, predictor: second, message: 'At least two paired observations are required.');
    }
    final diffs = pairs.map((p) => p.$1 - p.$2).toList();
    final meanDiff = _mean(diffs);
    final sdDiff = sqrt(_variance(diffs));
    final t = sdDiff == 0 ? 0.0 : meanDiff / (sdDiff / sqrt(diffs.length));

    return AnalysisResult(
      analysis: 'Paired t-test',
      outcome: first,
      predictor: second,
      n: pairs.length,
      metrics: {'mean_difference': meanDiff, 'sd_difference': sdDiff, 't_statistic': t},
      chartKind: 'histogram',
      chartPoints: _histogram(diffs..sort(), bins: 10),
      interpretation: 'Paired t-test between $first and $second: mean difference ${meanDiff.toStringAsFixed(3)}, t = ${t.toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult wilcoxonSignedRank({required DatasetSummary summary, required String first, String? second}) {
    final pairs = _numericPairs(summary, first, second ?? '');
    final diffs = pairs.map((p) => p.$1 - p.$2).where((d) => d != 0).toList();
    if (diffs.isEmpty) {
      return _error(analysis: 'Wilcoxon signed-rank', outcome: first, predictor: second, message: 'No non-zero paired differences found.');
    }

    final absDiffs = diffs.map((d) => d.abs()).toList();
    final ranks = _rank(absDiffs);
    var wPlus = 0.0;
    var wMinus = 0.0;
    for (var i = 0; i < diffs.length; i++) {
      if (diffs[i] > 0) {
        wPlus += ranks[i];
      } else {
        wMinus += ranks[i];
      }
    }

    return AnalysisResult(
      analysis: 'Wilcoxon signed-rank',
      outcome: first,
      predictor: second,
      n: diffs.length,
      metrics: {'W_plus': wPlus, 'W_minus': wMinus, 'W': min(wPlus, wMinus)},
      chartKind: 'histogram',
      chartPoints: _histogram(diffs..sort(), bins: 10),
      interpretation: 'Wilcoxon signed-rank between $first and $second: W = ${min(wPlus, wMinus).toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult chiSquare({required DatasetSummary summary, required String variableA, String? variableB}) {
    final tableResult = _contingency(summary, variableA, variableB);
    if (tableResult == null) {
      return _error(analysis: 'Chi-square', outcome: variableA, group: variableB, message: 'Choose two different categorical variables with observations.');
    }
    final table = tableResult.$1;
    final n = tableResult.$2;
    final rows = table.keys.toList();
    final cols = table.values.expand((m) => m.keys).toSet().toList();

    final rowTotals = <String, int>{};
    final colTotals = <String, int>{};
    for (final r in rows) {
      rowTotals[r] = 0;
      for (final c in cols) {
        final v = table[r]?[c] ?? 0;
        rowTotals[r] = rowTotals[r]! + v;
        colTotals[c] = (colTotals[c] ?? 0) + v;
      }
    }

    var chi2 = 0.0;
    for (final r in rows) {
      for (final c in cols) {
        final observed = (table[r]?[c] ?? 0).toDouble();
        final expected = rowTotals[r]! * colTotals[c]! / n;
        if (expected > 0) chi2 += pow(observed - expected, 2) / expected;
      }
    }

    return AnalysisResult(
      analysis: 'Chi-square',
      outcome: variableA,
      group: variableB,
      n: n,
      metrics: {'chi_square': chi2, 'df': ((rows.length - 1) * (cols.length - 1)).toDouble()},
      chartKind: 'bar',
      chartPoints: rows.take(20).map((r) => ChartPoint(x: 0, y: rowTotals[r]!.toDouble(), label: r)).toList(),
      interpretation: 'Chi-square association between $variableA and $variableB: χ² = ${chi2.toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult fisherExact2x2({required DatasetSummary summary, required String variableA, String? variableB}) {
    final tableResult = _contingency(summary, variableA, variableB);
    if (tableResult == null) {
      return _error(analysis: 'Fisher exact 2x2', outcome: variableA, group: variableB, message: 'Choose two categorical variables.');
    }

    final table = tableResult.$1;
    final rows = table.keys.toList();
    final cols = table.values.expand((m) => m.keys).toSet().toList();

    if (rows.length != 2 || cols.length != 2) {
      return _error(analysis: 'Fisher exact 2x2', outcome: variableA, group: variableB, message: 'Fisher exact test requires a 2x2 table.');
    }

    final a = (table[rows[0]]?[cols[0]] ?? 0).toDouble();
    final b = (table[rows[0]]?[cols[1]] ?? 0).toDouble();
    final c = (table[rows[1]]?[cols[0]] ?? 0).toDouble();
    final d = (table[rows[1]]?[cols[1]] ?? 0).toDouble();
    final oddsRatio = b * c == 0 ? double.infinity : (a * d) / (b * c);

    return AnalysisResult(
      analysis: 'Fisher exact 2x2',
      outcome: variableA,
      group: variableB,
      n: tableResult.$2,
      metrics: {'a': a, 'b': b, 'c': c, 'd': d, 'odds_ratio': oddsRatio},
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: a, label: '${rows[0]}/${cols[0]}'),
        ChartPoint(x: 1, y: b, label: '${rows[0]}/${cols[1]}'),
        ChartPoint(x: 2, y: c, label: '${rows[1]}/${cols[0]}'),
        ChartPoint(x: 3, y: d, label: '${rows[1]}/${cols[1]}'),
      ],
      interpretation: '2x2 table odds ratio = ${oddsRatio.isInfinite ? '∞' : oddsRatio.toStringAsFixed(3)}.',
      warning: 'Exact Fisher p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult kruskalWallis({required DatasetSummary summary, required String outcome, String? group}) {
    final groups = _numericByGroup(summary, outcome, group);
    if (groups.length < 2) {
      return _error(analysis: 'Kruskal-Wallis', outcome: outcome, group: group, message: 'Kruskal-Wallis requires at least two groups.');
    }

    final combined = <({double value, String group})>[];
    for (final entry in groups.entries) {
      for (final v in entry.value) {
        combined.add((value: v, group: entry.key));
      }
    }
    combined.sort((a, b) => a.value.compareTo(b.value));
    final ranks = _rank(combined.map((e) => e.value).toList());
    final n = combined.length.toDouble();

    var h = 0.0;
    for (final g in groups.keys) {
      var rankSum = 0.0;
      var count = 0;
      for (var i = 0; i < combined.length; i++) {
        if (combined[i].group == g) {
          rankSum += ranks[i];
          count++;
        }
      }
      if (count > 0) h += (rankSum * rankSum) / count;
    }
    h = (12 / (n * (n + 1))) * h - 3 * (n + 1);

    return AnalysisResult(
      analysis: 'Kruskal-Wallis',
      outcome: outcome,
      group: group,
      n: combined.length,
      metrics: {'H': h, 'df': (groups.length - 1).toDouble()},
      chartKind: 'bar',
      chartPoints: groups.entries.map((e) => ChartPoint(x: 0, y: _medianSortedCopy(e.value), label: e.key)).toList(),
      interpretation: 'Kruskal-Wallis across ${groups.length} groups: H = ${h.toStringAsFixed(3)}.',
      warning: 'Exact p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult simpleLinearRegression({required DatasetSummary summary, required String outcome, String? predictor}) {
    if (predictor == null || predictor == outcome) {
      return _error(analysis: 'Simple linear regression', outcome: outcome, predictor: predictor, message: 'Choose an outcome and a different predictor.');
    }

    final pairs = _numericPairs(summary, predictor, outcome);
    if (pairs.length < 3) {
      return _error(analysis: 'Simple linear regression', outcome: outcome, predictor: predictor, message: 'At least 3 numeric pairs are required.');
    }

    final xs = pairs.map((p) => p.$1).toList();
    final ys = pairs.map((p) => p.$2).toList();
    final mx = _mean(xs);
    final my = _mean(ys);

    var sxx = 0.0;
    var sxy = 0.0;
    for (var i = 0; i < pairs.length; i++) {
      sxx += pow(xs[i] - mx, 2);
      sxy += (xs[i] - mx) * (ys[i] - my);
    }

    final slope = sxx == 0 ? 0.0 : sxy / sxx;
    final intercept = my - slope * mx;
    final r = _pearson(xs, ys);

    return AnalysisResult(
      analysis: 'Simple linear regression',
      outcome: outcome,
      predictor: predictor,
      n: pairs.length,
      metrics: {'intercept': intercept, 'slope': slope, 'r_squared': r * r},
      chartKind: 'scatter',
      chartPoints: pairs.map((p) => ChartPoint(x: p.$1, y: p.$2)).toList(),
      interpretation: '$outcome = ${intercept.toStringAsFixed(3)} + ${slope.toStringAsFixed(3)} × $predictor, R² = ${(r * r).toStringAsFixed(3)}.',
      warning: 'Standard errors, confidence intervals and p-values will be added through the Python backend.',
    );
  }

  AnalysisResult multipleLinearRegression({required DatasetSummary summary, required String outcome, String? predictor}) {
    final base = simpleLinearRegression(summary: summary, outcome: outcome, predictor: predictor);
    return AnalysisResult(
      analysis: 'Multiple regression',
      outcome: outcome,
      predictor: predictor,
      n: base.n,
      metrics: base.metrics,
      chartKind: base.chartKind,
      chartPoints: base.chartPoints,
      interpretation: 'Prototype currently runs a one-predictor regression. Multi-predictor selection will be added in the UI next.',
      warning: 'True multiple regression with several predictors will be routed through the Python/statsmodels backend.',
    );
  }

  AnalysisResult logisticRegression({required DatasetSummary summary, required String outcome, String? predictor}) {
    if (predictor == null || predictor == outcome) {
      return _error(analysis: 'Logistic regression', outcome: outcome, predictor: predictor, message: 'Choose binary outcome and numeric predictor.');
    }

    final pairs = <(double, double)>[];
    for (final row in _rows(summary)) {
      final y = _binaryValue(row[outcome]);
      final x = double.tryParse('${row[predictor]}'.replaceAll(',', '.'));
      if (x != null && y != null) pairs.add((x, y));
    }

    if (pairs.length < 10) {
      return _error(analysis: 'Logistic regression', outcome: outcome, predictor: predictor, message: 'At least 10 valid observations are recommended.');
    }

    final xs = pairs.map((p) => p.$1).toList();
    final ys = pairs.map((p) => p.$2).toList();

    final mx = _mean(xs);
    final sx = sqrt(_variance(xs));
    final scaled = xs.map((x) => sx == 0 ? 0.0 : (x - mx) / sx).toList();

    var b0 = 0.0;
    var b1 = 0.0;
    const lr = 0.05;

    for (var iter = 0; iter < 800; iter++) {
      var g0 = 0.0;
      var g1 = 0.0;
      for (var i = 0; i < scaled.length; i++) {
        final p = _sigmoid(b0 + b1 * scaled[i]);
        g0 += p - ys[i];
        g1 += (p - ys[i]) * scaled[i];
      }
      b0 -= lr * g0 / scaled.length;
      b1 -= lr * g1 / scaled.length;
    }

    final probs = List.generate(scaled.length, (i) => _sigmoid(b0 + b1 * scaled[i]));
    final auc = _aucFromScores(ys, probs);

    return AnalysisResult(
      analysis: 'Logistic regression',
      outcome: outcome,
      predictor: predictor,
      n: pairs.length,
      metrics: {'intercept_scaled': b0, 'beta_scaled': b1, 'odds_ratio_scaled': exp(b1), 'auc': auc},
      chartKind: 'scatter',
      chartPoints: List.generate(pairs.length, (i) => ChartPoint(x: xs[i], y: probs[i])),
      interpretation: 'Logistic regression predicting $outcome from $predictor: scaled OR = ${exp(b1).toStringAsFixed(3)}, AUC = ${auc.toStringAsFixed(3)}.',
      warning: 'This is a lightweight local prototype. Robust coefficients, CIs and p-values should come from Python/statsmodels.',
    );
  }

  AnalysisResult rocAuc({required DatasetSummary summary, required String outcome, String? predictor}) {
    if (predictor == null || predictor == outcome) {
      return _error(analysis: 'ROC / AUC', outcome: outcome, predictor: predictor, message: 'Choose binary outcome and numeric score/predictor.');
    }

    final labels = <double>[];
    final scores = <double>[];

    for (final row in _rows(summary)) {
      final y = _binaryValue(row[outcome]);
      final s = double.tryParse('${row[predictor]}'.replaceAll(',', '.'));
      if (y != null && s != null) {
        labels.add(y);
        scores.add(s);
      }
    }

    if (labels.length < 3) {
      return _error(analysis: 'ROC / AUC', outcome: outcome, predictor: predictor, message: 'Not enough valid observations.');
    }

    final points = _rocPoints(labels, scores);
    final auc = _aucFromScores(labels, scores);

    return AnalysisResult(
      analysis: 'ROC / AUC',
      outcome: outcome,
      predictor: predictor,
      n: labels.length,
      metrics: {'auc': auc},
      chartKind: 'line',
      chartPoints: points,
      interpretation: 'ROC analysis for $predictor predicting $outcome: AUC = ${auc.toStringAsFixed(3)}.',
    );
  }

  AnalysisResult diagnosticMetrics({required DatasetSummary summary, required String truth, String? test}) {
    if (test == null || test == truth) {
      return _error(analysis: 'Diagnostic metrics', outcome: truth, predictor: test, message: 'Choose truth/outcome and test/prediction variable.');
    }

    var tp = 0;
    var tn = 0;
    var fp = 0;
    var fn = 0;

    for (final row in _rows(summary)) {
      final y = _binaryValue(row[truth]);
      final t = _binaryValue(row[test]);
      if (y == null || t == null) continue;

      if (y == 1 && t == 1) tp++;
      if (y == 0 && t == 0) tn++;
      if (y == 0 && t == 1) fp++;
      if (y == 1 && t == 0) fn++;
    }

    final n = tp + tn + fp + fn;
    if (n == 0) {
      return _error(analysis: 'Diagnostic metrics', outcome: truth, predictor: test, message: 'No valid binary pairs found.');
    }

    final sensitivity = _safeDiv(tp, tp + fn);
    final specificity = _safeDiv(tn, tn + fp);
    final ppv = _safeDiv(tp, tp + fp);
    final npv = _safeDiv(tn, tn + fn);
    final accuracy = _safeDiv(tp + tn, n);
    final lrPositive = specificity == 1 ? double.infinity : sensitivity / (1 - specificity);
    final lrNegative = specificity == 0 ? double.infinity : (1 - sensitivity) / specificity;

    return AnalysisResult(
      analysis: 'Diagnostic metrics',
      outcome: truth,
      predictor: test,
      n: n,
      metrics: {
        'tp': tp.toDouble(),
        'tn': tn.toDouble(),
        'fp': fp.toDouble(),
        'fn': fn.toDouble(),
        'accuracy': accuracy,
        'sensitivity': sensitivity,
        'specificity': specificity,
        'ppv': ppv,
        'npv': npv,
        'lr_positive': lrPositive,
        'lr_negative': lrNegative,
        'youden_index': sensitivity + specificity - 1,
      },
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: tp.toDouble(), label: 'TP'),
        ChartPoint(x: 1, y: tn.toDouble(), label: 'TN'),
        ChartPoint(x: 2, y: fp.toDouble(), label: 'FP'),
        ChartPoint(x: 3, y: fn.toDouble(), label: 'FN'),
      ],
      interpretation: 'Diagnostic performance of $test against $truth: sensitivity ${sensitivity.toStringAsFixed(3)}, specificity ${specificity.toStringAsFixed(3)}.',
    );
  }

  AnalysisResult riskComparison({required DatasetSummary summary, required String outcome, String? group}) {
    if (group == null || group == outcome) {
      return _error(analysis: 'Risk comparison', outcome: outcome, group: group, message: 'Choose binary outcome and two-group exposure variable.');
    }

    final groups = <String, List<double>>{};
    for (final row in _rows(summary)) {
      final g = row[group]?.toString();
      final y = _binaryValue(row[outcome]);
      if (g == null || g.trim().isEmpty || y == null) continue;
      groups.putIfAbsent(g, () => []).add(y);
    }

    if (groups.length != 2) {
      return _error(analysis: 'Risk comparison', outcome: outcome, group: group, message: 'Risk comparison requires exactly two groups.');
    }

    final entries = groups.entries.toList();
    final r1 = _mean(entries[0].value);
    final r2 = _mean(entries[1].value);
    final arr = r2 - r1;
    final rr = r1 == 0 ? double.infinity : r2 / r1;
    final nnt = arr == 0 ? double.infinity : 1 / arr.abs();

    return AnalysisResult(
      analysis: 'Risk comparison',
      outcome: outcome,
      group: group,
      n: entries[0].value.length + entries[1].value.length,
      metrics: {'risk_${entries[0].key}': r1, 'risk_${entries[1].key}': r2, 'absolute_risk_difference': arr, 'relative_risk': rr, 'nnt_or_nnh_abs': nnt},
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: r1, label: entries[0].key),
        ChartPoint(x: 1, y: r2, label: entries[1].key),
      ],
      interpretation: 'Risk comparison: ${entries[0].key} risk ${r1.toStringAsFixed(3)}, ${entries[1].key} risk ${r2.toStringAsFixed(3)}, RR ${rr.isInfinite ? '∞' : rr.toStringAsFixed(3)}.',
    );
  }

  AnalysisResult kaplanMeier({required DatasetSummary summary, required String time, String? event}) {
    if (event == null || event == time) {
      return _error(analysis: 'Kaplan-Meier', outcome: time, predictor: event, message: 'Choose time variable and event indicator.');
    }

    final pairs = <(double, double)>[];
    for (final row in _rows(summary)) {
      final t = double.tryParse('${row[time]}'.replaceAll(',', '.'));
      final e = _binaryValue(row[event]);
      if (t != null && e != null) pairs.add((t, e));
    }

    if (pairs.isEmpty) {
      return _error(analysis: 'Kaplan-Meier', outcome: time, predictor: event, message: 'No valid time-event pairs found.');
    }

    pairs.sort((a, b) => a.$1.compareTo(b.$1));
    var atRisk = pairs.length;
    var survival = 1.0;
    final points = <ChartPoint>[ChartPoint(x: 0, y: 1)];

    final times = pairs.map((p) => p.$1).toSet().toList()..sort();
    for (final t in times) {
      final eventsAtT = pairs.where((p) => p.$1 == t && p.$2 == 1).length;
      final censoredAtT = pairs.where((p) => p.$1 == t && p.$2 == 0).length;
      if (atRisk > 0 && eventsAtT > 0) survival *= (1 - eventsAtT / atRisk);
      points.add(ChartPoint(x: t, y: survival));
      atRisk -= eventsAtT + censoredAtT;
    }

    return AnalysisResult(
      analysis: 'Kaplan-Meier',
      outcome: time,
      predictor: event,
      n: pairs.length,
      metrics: {'final_survival': survival},
      chartKind: 'line',
      chartPoints: points,
      interpretation: 'Kaplan-Meier estimate built from $time and $event. Final survival estimate ${survival.toStringAsFixed(3)}.',
      warning: 'Grouped survival and confidence intervals will be added through the Python/lifelines backend.',
    );
  }

  AnalysisResult logRank({required DatasetSummary summary, required String time, String? event, String? group}) {
    if (event == null || group == null || time == event || time == group) {
      return _error(analysis: 'Log-rank', outcome: time, predictor: event, group: group, message: 'Choose time, event and group variable.');
    }

    final groups = _stringColumn(summary, group).toSet().toList();
    if (groups.length != 2) {
      return _error(analysis: 'Log-rank', outcome: time, predictor: event, group: group, message: 'Prototype log-rank requires exactly two groups.');
    }

    final records = <({double time, double event, String group})>[];
    for (final row in _rows(summary)) {
      final t = double.tryParse('${row[time]}'.replaceAll(',', '.'));
      final e = _binaryValue(row[event]);
      final g = row[group]?.toString();
      if (t != null && e != null && g != null && g.trim().isNotEmpty) {
        records.add((time: t, event: e, group: g));
      }
    }

    final times = records.where((r) => r.event == 1).map((r) => r.time).toSet().toList()..sort();
    var observed1 = 0.0;
    var expected1 = 0.0;
    var variance1 = 0.0;

    for (final t in times) {
      final atRisk = records.where((r) => r.time >= t).toList();
      final events = records.where((r) => r.time == t && r.event == 1).toList();

      final n = atRisk.length;
      final d = events.length;
      if (n <= 1 || d == 0) continue;

      final n1 = atRisk.where((r) => r.group == groups[0]).length;
      final d1 = events.where((r) => r.group == groups[0]).length;

      observed1 += d1;
      expected1 += d * n1 / n;
      variance1 += (n1 * (n - n1) * d * (n - d)) / (n * n * (n - 1));
    }

    final chi2 = variance1 == 0 ? 0.0 : pow(observed1 - expected1, 2) / variance1;

    return AnalysisResult(
      analysis: 'Log-rank',
      outcome: time,
      predictor: event,
      group: group,
      n: records.length,
      metrics: {'observed_group1': observed1, 'expected_group1': expected1, 'chi_square': chi2.toDouble(), 'df': 1},
      chartKind: 'bar',
      chartPoints: [
        ChartPoint(x: 0, y: observed1, label: 'Observed ${groups[0]}'),
        ChartPoint(x: 1, y: expected1, label: 'Expected ${groups[0]}'),
      ],
      interpretation: 'Prototype log-rank test for $group: χ² = ${chi2.toStringAsFixed(3)}.',
      warning: 'Robust survival modelling and p-values will be added through the Python/lifelines backend.',
    );
  }

  AnalysisResult normalityJarqueBera({required DatasetSummary summary, required String variable}) {
    final x = _numericColumn(summary, variable);
    if (x.length < 3) {
      return _error(analysis: 'Normality / Jarque-Bera', outcome: variable, message: 'At least 3 numeric observations are required.');
    }

    final n = x.length;
    final mean = _mean(x);
    final sd = sqrt(_variance(x));
    if (sd == 0) {
      return _error(analysis: 'Normality / Jarque-Bera', outcome: variable, message: 'Variable has zero variance.');
    }

    final skew = x.map((v) => pow((v - mean) / sd, 3)).reduce((a, b) => a + b) / n;
    final kurt = x.map((v) => pow((v - mean) / sd, 4)).reduce((a, b) => a + b) / n;
    final jb = n / 6 * (pow(skew, 2) + pow(kurt - 3, 2) / 4);

    x.sort();
    return AnalysisResult(
      analysis: 'Normality / Jarque-Bera',
      outcome: variable,
      n: n,
      metrics: {'mean': mean, 'sd': sd, 'skewness': skew.toDouble(), 'kurtosis': kurt.toDouble(), 'jarque_bera': jb.toDouble()},
      chartKind: 'histogram',
      chartPoints: _histogram(x, bins: 12),
      interpretation: 'Normality screen for $variable: skewness ${skew.toStringAsFixed(3)}, kurtosis ${kurt.toStringAsFixed(3)}, JB ${jb.toStringAsFixed(3)}.',
      warning: 'Shapiro-Wilk and p-values will be added through the Python/Scipy backend.',
    );
  }

  AnalysisResult residualDiagnostics({required DatasetSummary summary, required String outcome, String? predictor}) {
    final reg = simpleLinearRegression(summary: summary, outcome: outcome, predictor: predictor);
    if (reg.metrics == null || predictor == null) return reg;

    final intercept = reg.metrics!['intercept'] ?? 0;
    final slope = reg.metrics!['slope'] ?? 0;
    final pairs = _numericPairs(summary, predictor, outcome);
    final residuals = pairs.map((p) => p.$2 - (intercept + slope * p.$1)).toList();
    residuals.sort();

    final meanResidual = _mean(residuals);
    final sdResidual = sqrt(_variance(residuals));

    return AnalysisResult(
      analysis: 'Residual diagnostics',
      outcome: outcome,
      predictor: predictor,
      n: residuals.length,
      metrics: {'residual_mean': meanResidual, 'residual_sd': sdResidual, 'residual_min': residuals.first, 'residual_max': residuals.last},
      chartKind: 'histogram',
      chartPoints: _histogram(residuals, bins: 12),
      interpretation: 'Residual diagnostics for $outcome ~ $predictor: residual mean ${meanResidual.toStringAsFixed(3)}, residual SD ${sdResidual.toStringAsFixed(3)}.',
      warning: 'Breusch-Pagan, QQ plots and VIF will be added through the Python/statsmodels backend.',
    );
  }

  Map<String, List<double>> _numericByGroup(DatasetSummary summary, String outcome, String? group) {
    final result = <String, List<double>>{};
    if (group == null || group.isEmpty || group == outcome) return result;

    for (final row in _rows(summary)) {
      final groupValue = row[group]?.toString();
      final value = double.tryParse('${row[outcome]}'.replaceAll(',', '.'));
      if (groupValue == null || groupValue.trim().isEmpty || value == null) continue;
      result.putIfAbsent(groupValue, () => []).add(value);
    }
    return result;
  }

  (Map<String, Map<String, int>>, int)? _contingency(DatasetSummary summary, String a, String? b) {
    if (b == null || b.isEmpty || a == b) return null;

    final table = <String, Map<String, int>>{};
    var n = 0;

    for (final row in _rows(summary)) {
      final av = row[a]?.toString();
      final bv = row[b]?.toString();
      if (av == null || bv == null || av.trim().isEmpty || bv.trim().isEmpty) continue;
      table.putIfAbsent(av, () => {});
      table[av]![bv] = (table[av]![bv] ?? 0) + 1;
      n++;
    }

    if (n == 0) return null;
    return (table, n);
  }

  List<ChartPoint> _histogram(List<double> values, {int bins = 10}) {
    if (values.isEmpty) return [];
    final minValue = values.first;
    final maxValue = values.last;
    if (minValue == maxValue) {
      return [ChartPoint(x: minValue, y: values.length.toDouble(), label: minValue.toStringAsFixed(2))];
    }

    final width = (maxValue - minValue) / bins;
    final counts = List<int>.filled(bins, 0);
    for (final value in values) {
      var idx = ((value - minValue) / width).floor();
      if (idx >= bins) idx = bins - 1;
      if (idx < 0) idx = 0;
      counts[idx]++;
    }

    return List.generate(bins, (i) {
      final center = minValue + width * (i + 0.5);
      return ChartPoint(x: center, y: counts[i].toDouble(), label: center.toStringAsFixed(2));
    });
  }

  List<ChartPoint> _rocPoints(List<double> labels, List<double> scores) {
    final combined = List.generate(labels.length, (i) => (label: labels[i], score: scores[i]));
    combined.sort((a, b) => b.score.compareTo(a.score));

    final positives = labels.where((v) => v == 1).length;
    final negatives = labels.where((v) => v == 0).length;
    if (positives == 0 || negatives == 0) return [];

    var tp = 0;
    var fp = 0;
    final points = <ChartPoint>[ChartPoint(x: 0, y: 0)];

    for (final item in combined) {
      if (item.label == 1) {
        tp++;
      } else {
        fp++;
      }
      points.add(ChartPoint(x: fp / negatives, y: tp / positives));
    }

    points.add(ChartPoint(x: 1, y: 1));
    return points;
  }

  double _aucFromScores(List<double> labels, List<double> scores) {
    final points = _rocPoints(labels, scores);
    if (points.length < 2) return 0.0;

    var auc = 0.0;
    for (var i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final avgY = (points[i].y + points[i - 1].y) / 2;
      auc += dx * avgY;
    }
    return auc.abs();
  }

  double _sigmoid(double z) => 1 / (1 + exp(-z));

  double _safeDiv(num a, num b) => b == 0 ? 0.0 : a / b;

  double _mean(List<double> values) => values.reduce((a, b) => a + b) / values.length;

  double _variance(List<double> values) {
    if (values.length < 2) return 0.0;
    final m = _mean(values);
    return values.map((x) => pow(x - m, 2).toDouble()).reduce((a, b) => a + b) / (values.length - 1);
  }

  double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0.0;
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  double _medianSortedCopy(List<double> values) {
    final copy = [...values]..sort();
    return _median(copy);
  }

  double _pearson(List<double> xs, List<double> ys) {
    final n = min(xs.length, ys.length);
    final x = xs.take(n).toList();
    final y = ys.take(n).toList();

    final mx = _mean(x);
    final my = _mean(y);

    var sxx = 0.0;
    var syy = 0.0;
    var sxy = 0.0;

    for (var i = 0; i < n; i++) {
      final dx = x[i] - mx;
      final dy = y[i] - my;
      sxx += dx * dx;
      syy += dy * dy;
      sxy += dx * dy;
    }

    final denom = sqrt(sxx * syy);
    if (denom == 0) return 0.0;
    return sxy / denom;
  }

  List<double> _rank(List<double> values) {
    final indexed = <({int index, double value})>[];
    for (var i = 0; i < values.length; i++) {
      indexed.add((index: i, value: values[i]));
    }

    indexed.sort((a, b) => a.value.compareTo(b.value));

    final ranks = List<double>.filled(values.length, 0.0);
    var i = 0;

    while (i < indexed.length) {
      var j = i;
      while (j + 1 < indexed.length && indexed[j + 1].value == indexed[i].value) {
        j++;
      }

      final avgRank = ((i + 1) + (j + 1)) / 2.0;

      for (var k = i; k <= j; k++) {
        ranks[indexed[k].index] = avgRank;
      }

      i = j + 1;
    }

    return ranks;
  }
}
