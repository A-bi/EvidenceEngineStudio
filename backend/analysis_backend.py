#!/usr/bin/env python3
import argparse
import json
import math
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from scipy import stats
from sklearn.metrics import roc_auc_score, roc_curve, confusion_matrix
import statsmodels.api as sm


OUTPUT_DIR = Path(__file__).resolve().parent / "outputs"
OUTPUT_DIR.mkdir(exist_ok=True)


def clean_value(x):
    if pd.isna(x):
        return None
    if isinstance(x, (np.integer, int)):
        return int(x)
    if isinstance(x, (np.floating, float)):
        if math.isnan(float(x)):
            return None
        return float(x)
    if isinstance(x, (np.bool_, bool)):
        return bool(x)
    return str(x)


def infer_bool_series(s: pd.Series) -> pd.Series:
    def conv(v):
        if pd.isna(v):
            return np.nan
        t = str(v).strip().lower()
        if t in ["1", "true", "yes", "ja", "positive", "pos", "case", "event", "dead", "died"]:
            return 1
        if t in ["0", "false", "no", "nein", "negative", "neg", "control", "none", "alive"]:
            return 0
        try:
            return 1 if float(t.replace(",", ".")) > 0 else 0
        except Exception:
            return np.nan
    return s.map(conv)


def read_dataset(path: str) -> pd.DataFrame:
    p = Path(path)
    ext = p.suffix.lower()

    if ext in [".csv", ".txt"]:
        try:
            return pd.read_csv(p)
        except Exception:
            return pd.read_csv(p, sep=";")

    if ext == ".tsv":
        return pd.read_csv(p, sep="\t")

    if ext in [".xlsx", ".xls"]:
        return pd.read_excel(p)

    if ext == ".json":
        return pd.read_json(p)

    if ext in [".parquet"]:
        return pd.read_parquet(p)

    raise ValueError(f"Unsupported file type for Python backend: {ext}")


def save_plot(fig, name: str) -> str:
    path = OUTPUT_DIR / f"{name}.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180)
    plt.close(fig)
    return str(path)


def numeric_series(df, col):
    return pd.to_numeric(df[col], errors="coerce").dropna()


def paired_numeric(df, x, y):
    tmp = df[[x, y]].copy()
    tmp[x] = pd.to_numeric(tmp[x], errors="coerce")
    tmp[y] = pd.to_numeric(tmp[y], errors="coerce")
    return tmp.dropna()


def result(**kwargs):
    print(json.dumps(kwargs, ensure_ascii=False, indent=2))


def descriptive(df, outcome):
    s_num = pd.to_numeric(df[outcome], errors="coerce")
    if s_num.notna().sum() >= max(3, 0.7 * df[outcome].notna().sum()):
        x = s_num.dropna()
        fig, ax = plt.subplots(figsize=(7, 4))
        ax.hist(x, bins=20)
        ax.set_title(f"Histogram: {outcome}")
        ax.set_xlabel(outcome)
        ax.set_ylabel("Count")
        plot = save_plot(fig, "descriptive_histogram")

        metrics = {
            "n": int(x.shape[0]),
            "mean": float(x.mean()),
            "median": float(x.median()),
            "sd": float(x.std(ddof=1)) if x.shape[0] > 1 else 0.0,
            "min": float(x.min()),
            "max": float(x.max()),
            "missing": int(s_num.isna().sum()),
        }

        return {
            "analysis": "Descriptive statistics",
            "outcome": outcome,
            "n": int(x.shape[0]),
            "metrics": metrics,
            "plot_path": plot,
            "interpretation": f"{outcome}: mean={metrics['mean']:.3f}, median={metrics['median']:.3f}, sd={metrics['sd']:.3f}."
        }

    counts = df[outcome].astype(str).replace("nan", np.nan).dropna().value_counts()
    fig, ax = plt.subplots(figsize=(7, 4))
    counts.head(20).plot(kind="bar", ax=ax)
    ax.set_title(f"Category counts: {outcome}")
    ax.set_ylabel("Count")
    plot = save_plot(fig, "descriptive_categories")

    return {
        "analysis": "Category counts",
        "outcome": outcome,
        "n": int(counts.sum()),
        "category_counts": {str(k): int(v) for k, v in counts.items()},
        "plot_path": plot,
        "interpretation": f"{outcome}: {len(counts)} unique category value(s)."
    }


def pearson(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 3:
        raise ValueError("Pearson correlation needs at least 3 paired numeric observations.")
    r, p = stats.pearsonr(tmp[outcome], tmp[predictor])

    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(tmp[outcome], tmp[predictor], s=16)
    ax.set_xlabel(outcome)
    ax.set_ylabel(predictor)
    ax.set_title("Pearson correlation")
    plot = save_plot(fig, "pearson_scatter")

    return {
        "analysis": "Pearson correlation",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {"r": float(r), "p_value": float(p), "r_squared": float(r*r)},
        "plot_path": plot,
        "interpretation": f"Pearson r={r:.3f}, p={p:.4g}."
    }


def spearman(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 3:
        raise ValueError("Spearman correlation needs at least 3 paired numeric observations.")
    rho, p = stats.spearmanr(tmp[outcome], tmp[predictor])

    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(tmp[outcome], tmp[predictor], s=16)
    ax.set_xlabel(outcome)
    ax.set_ylabel(predictor)
    ax.set_title("Spearman correlation")
    plot = save_plot(fig, "spearman_scatter")

    return {
        "analysis": "Spearman correlation",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {"rho": float(rho), "p_value": float(p)},
        "plot_path": plot,
        "interpretation": f"Spearman ρ={rho:.3f}, p={p:.4g}."
    }


def grouped_numeric(df, outcome, group):
    tmp = df[[outcome, group]].copy()
    tmp[outcome] = pd.to_numeric(tmp[outcome], errors="coerce")
    tmp = tmp.dropna()
    groups = [g[outcome].values for _, g in tmp.groupby(group)]
    labels = [str(k) for k, _ in tmp.groupby(group)]
    return labels, groups


def welch_ttest(df, outcome, group):
    labels, groups = grouped_numeric(df, outcome, group)
    if len(groups) != 2:
        raise ValueError("Welch t-test requires exactly two groups.")
    a, b = groups
    t, p = stats.ttest_ind(a, b, equal_var=False, nan_policy="omit")
    mean_a, mean_b = np.mean(a), np.mean(b)
    pooled = math.sqrt((np.var(a, ddof=1) + np.var(b, ddof=1)) / 2)
    d = (mean_b - mean_a) / pooled if pooled else 0.0

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar(labels, [mean_a, mean_b])
    ax.set_ylabel(outcome)
    ax.set_title("Group means")
    plot = save_plot(fig, "welch_ttest_bar")

    return {
        "analysis": "Welch t-test",
        "outcome": outcome,
        "group": group,
        "n": int(len(a) + len(b)),
        "metrics": {
            f"{labels[0]}_mean": float(mean_a),
            f"{labels[1]}_mean": float(mean_b),
            "mean_difference": float(mean_b - mean_a),
            "t_statistic": float(t),
            "p_value": float(p),
            "cohen_d": float(d),
        },
        "plot_path": plot,
        "interpretation": f"Welch t={t:.3f}, p={p:.4g}, Cohen d={d:.3f}."
    }


def mann_whitney(df, outcome, group):
    labels, groups = grouped_numeric(df, outcome, group)
    if len(groups) != 2:
        raise ValueError("Mann-Whitney U requires exactly two groups.")
    u, p = stats.mannwhitneyu(groups[0], groups[1], alternative="two-sided")

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.boxplot(groups, labels=labels)
    ax.set_ylabel(outcome)
    ax.set_title("Mann-Whitney U")
    plot = save_plot(fig, "mann_whitney_boxplot")

    return {
        "analysis": "Mann-Whitney U",
        "outcome": outcome,
        "group": group,
        "n": int(sum(len(g) for g in groups)),
        "metrics": {"U": float(u), "p_value": float(p)},
        "plot_path": plot,
        "interpretation": f"Mann-Whitney U={u:.3f}, p={p:.4g}."
    }


def paired_ttest(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 2:
        raise ValueError("Paired t-test requires at least two paired observations.")
    t, p = stats.ttest_rel(tmp[outcome], tmp[predictor])
    diff = tmp[outcome] - tmp[predictor]

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.hist(diff, bins=20)
    ax.set_title("Paired differences")
    ax.set_xlabel(f"{outcome} - {predictor}")
    plot = save_plot(fig, "paired_ttest_diff")

    return {
        "analysis": "Paired t-test",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {
            "mean_difference": float(diff.mean()),
            "sd_difference": float(diff.std(ddof=1)),
            "t_statistic": float(t),
            "p_value": float(p),
        },
        "plot_path": plot,
        "interpretation": f"Paired t={t:.3f}, p={p:.4g}."
    }


def wilcoxon(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 2:
        raise ValueError("Wilcoxon signed-rank requires paired observations.")
    stat, p = stats.wilcoxon(tmp[outcome], tmp[predictor])
    diff = tmp[outcome] - tmp[predictor]

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.hist(diff, bins=20)
    ax.set_title("Wilcoxon paired differences")
    plot = save_plot(fig, "wilcoxon_diff")

    return {
        "analysis": "Wilcoxon signed-rank",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {"W": float(stat), "p_value": float(p)},
        "plot_path": plot,
        "interpretation": f"Wilcoxon W={stat:.3f}, p={p:.4g}."
    }


def chi_square(df, outcome, group):
    table = pd.crosstab(df[outcome], df[group])
    if table.shape[0] < 2 or table.shape[1] < 2:
        raise ValueError("Chi-square requires at least a 2x2 table.")
    chi2, p, dof, expected = stats.chi2_contingency(table)

    fig, ax = plt.subplots(figsize=(7, 4))
    table.plot(kind="bar", stacked=True, ax=ax)
    ax.set_title("Contingency table")
    ax.set_ylabel("Count")
    plot = save_plot(fig, "chi_square_bar")

    return {
        "analysis": "Chi-square",
        "outcome": outcome,
        "group": group,
        "n": int(table.values.sum()),
        "metrics": {"chi_square": float(chi2), "p_value": float(p), "df": int(dof)},
        "plot_path": plot,
        "interpretation": f"χ²={chi2:.3f}, df={dof}, p={p:.4g}."
    }


def fisher_exact(df, outcome, group):
    table = pd.crosstab(df[outcome], df[group])
    if table.shape != (2, 2):
        raise ValueError("Fisher exact requires a 2x2 table.")
    odds, p = stats.fisher_exact(table.values)

    fig, ax = plt.subplots(figsize=(6, 4))
    table.plot(kind="bar", stacked=True, ax=ax)
    ax.set_title("2x2 table")
    plot = save_plot(fig, "fisher_bar")

    return {
        "analysis": "Fisher exact 2x2",
        "outcome": outcome,
        "group": group,
        "n": int(table.values.sum()),
        "metrics": {"odds_ratio": float(odds), "p_value": float(p)},
        "plot_path": plot,
        "interpretation": f"Fisher odds ratio={odds:.3f}, p={p:.4g}."
    }


def kruskal(df, outcome, group):
    labels, groups = grouped_numeric(df, outcome, group)
    if len(groups) < 2:
        raise ValueError("Kruskal-Wallis requires at least two groups.")
    h, p = stats.kruskal(*groups)

    fig, ax = plt.subplots(figsize=(7, 4))
    ax.boxplot(groups, labels=labels)
    ax.set_title("Kruskal-Wallis")
    ax.set_ylabel(outcome)
    plot = save_plot(fig, "kruskal_boxplot")

    return {
        "analysis": "Kruskal-Wallis",
        "outcome": outcome,
        "group": group,
        "n": int(sum(len(g) for g in groups)),
        "metrics": {"H": float(h), "p_value": float(p), "df": len(groups)-1},
        "plot_path": plot,
        "interpretation": f"Kruskal-Wallis H={h:.3f}, p={p:.4g}."
    }


def linear_regression(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 3:
        raise ValueError("Linear regression needs at least 3 observations.")

    y = tmp[outcome]
    X = sm.add_constant(tmp[[predictor]])
    model = sm.OLS(y, X).fit()

    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(tmp[predictor], y, s=16)
    xs = np.linspace(tmp[predictor].min(), tmp[predictor].max(), 100)
    ys = model.params["const"] + model.params[predictor] * xs
    ax.plot(xs, ys)
    ax.set_xlabel(predictor)
    ax.set_ylabel(outcome)
    ax.set_title("Linear regression")
    plot = save_plot(fig, "linear_regression")

    return {
        "analysis": "Simple linear regression",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {
            "intercept": float(model.params["const"]),
            "slope": float(model.params[predictor]),
            "r_squared": float(model.rsquared),
            "p_value_predictor": float(model.pvalues[predictor]),
            "aic": float(model.aic),
            "bic": float(model.bic),
        },
        "plot_path": plot,
        "interpretation": f"{outcome} ~ {predictor}: beta={model.params[predictor]:.3f}, R²={model.rsquared:.3f}, p={model.pvalues[predictor]:.4g}."
    }


def logistic_regression(df, outcome, predictor):
    tmp = df[[outcome, predictor]].copy()
    tmp[outcome] = infer_bool_series(tmp[outcome])
    tmp[predictor] = pd.to_numeric(tmp[predictor], errors="coerce")
    tmp = tmp.dropna()
    if len(tmp) < 10:
        raise ValueError("Logistic regression needs at least 10 observations.")

    y = tmp[outcome]
    X = sm.add_constant(tmp[[predictor]])
    model = sm.Logit(y, X).fit(disp=False)

    probs = model.predict(X)
    auc = roc_auc_score(y, probs)

    fig, ax = plt.subplots(figsize=(6, 5))
    ax.scatter(tmp[predictor], probs, s=16)
    ax.set_xlabel(predictor)
    ax.set_ylabel("Predicted probability")
    ax.set_title("Logistic regression")
    plot = save_plot(fig, "logistic_regression")

    return {
        "analysis": "Logistic regression",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {
            "intercept": float(model.params["const"]),
            "beta": float(model.params[predictor]),
            "odds_ratio": float(np.exp(model.params[predictor])),
            "p_value_predictor": float(model.pvalues[predictor]),
            "auc": float(auc),
            "aic": float(model.aic),
        },
        "plot_path": plot,
        "interpretation": f"Logistic regression: OR={np.exp(model.params[predictor]):.3f}, p={model.pvalues[predictor]:.4g}, AUC={auc:.3f}."
    }


def roc_auc(df, outcome, predictor):
    tmp = df[[outcome, predictor]].copy()
    tmp[outcome] = infer_bool_series(tmp[outcome])
    tmp[predictor] = pd.to_numeric(tmp[predictor], errors="coerce")
    tmp = tmp.dropna()
    if len(tmp) < 3:
        raise ValueError("ROC/AUC needs valid binary truth and numeric score.")

    y = tmp[outcome]
    scores = tmp[predictor]
    auc = roc_auc_score(y, scores)
    fpr, tpr, _ = roc_curve(y, scores)

    fig, ax = plt.subplots(figsize=(5, 5))
    ax.plot(fpr, tpr)
    ax.plot([0, 1], [0, 1], linestyle="--")
    ax.set_xlabel("False positive rate")
    ax.set_ylabel("True positive rate")
    ax.set_title("ROC curve")
    plot = save_plot(fig, "roc_auc")

    return {
        "analysis": "ROC / AUC",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {"auc": float(auc)},
        "plot_path": plot,
        "interpretation": f"AUC={auc:.3f}."
    }


def diagnostic_metrics(df, outcome, predictor):
    tmp = df[[outcome, predictor]].copy()
    tmp[outcome] = infer_bool_series(tmp[outcome])
    tmp[predictor] = infer_bool_series(tmp[predictor])
    tmp = tmp.dropna()

    if len(tmp) == 0:
        raise ValueError("No valid binary truth/test pairs found.")

    tn, fp, fn, tp = confusion_matrix(tmp[outcome], tmp[predictor], labels=[0, 1]).ravel()

    sensitivity = tp / (tp + fn) if tp + fn else np.nan
    specificity = tn / (tn + fp) if tn + fp else np.nan
    ppv = tp / (tp + fp) if tp + fp else np.nan
    npv = tn / (tn + fn) if tn + fn else np.nan
    accuracy = (tp + tn) / (tp + tn + fp + fn)
    youden = sensitivity + specificity - 1

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar(["TP", "TN", "FP", "FN"], [tp, tn, fp, fn])
    ax.set_title("Confusion matrix counts")
    plot = save_plot(fig, "diagnostic_metrics")

    return {
        "analysis": "Diagnostic metrics",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {
            "tp": int(tp),
            "tn": int(tn),
            "fp": int(fp),
            "fn": int(fn),
            "accuracy": float(accuracy),
            "sensitivity": float(sensitivity),
            "specificity": float(specificity),
            "ppv": float(ppv),
            "npv": float(npv),
            "youden_index": float(youden),
        },
        "plot_path": plot,
        "interpretation": f"Sensitivity={sensitivity:.3f}, specificity={specificity:.3f}, accuracy={accuracy:.3f}."
    }


def risk_comparison(df, outcome, group):
    tmp = df[[outcome, group]].copy()
    tmp[outcome] = infer_bool_series(tmp[outcome])
    tmp = tmp.dropna()
    grouped = list(tmp.groupby(group))
    if len(grouped) != 2:
        raise ValueError("Risk comparison requires exactly two groups.")

    labels = [str(g[0]) for g in grouped]
    risks = [float(g[1][outcome].mean()) for g in grouped]
    arr = risks[1] - risks[0]
    rr = risks[1] / risks[0] if risks[0] != 0 else np.inf
    nnt = 1 / abs(arr) if arr != 0 else np.inf

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar(labels, risks)
    ax.set_ylabel("Risk")
    ax.set_title("Risk by group")
    plot = save_plot(fig, "risk_comparison")

    return {
        "analysis": "Risk comparison",
        "outcome": outcome,
        "group": group,
        "n": int(len(tmp)),
        "metrics": {
            f"risk_{labels[0]}": risks[0],
            f"risk_{labels[1]}": risks[1],
            "absolute_risk_difference": float(arr),
            "relative_risk": float(rr),
            "nnt_or_nnh_abs": float(nnt),
        },
        "plot_path": plot,
        "interpretation": f"Risk difference={arr:.3f}, RR={rr:.3f}."
    }


def normality(df, outcome):
    x = numeric_series(df, outcome)
    if len(x) < 3:
        raise ValueError("Normality testing needs at least 3 observations.")

    shapiro_w, shapiro_p = stats.shapiro(x) if len(x) <= 5000 else (np.nan, np.nan)
    jb, jb_p = stats.jarque_bera(x)

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.hist(x, bins=20)
    ax.set_title("Normality histogram")
    plot = save_plot(fig, "normality_histogram")

    return {
        "analysis": "Normality / Jarque-Bera",
        "outcome": outcome,
        "n": int(len(x)),
        "metrics": {
            "shapiro_w": float(shapiro_w),
            "shapiro_p": float(shapiro_p),
            "jarque_bera": float(jb),
            "jarque_bera_p": float(jb_p),
            "skewness": float(stats.skew(x)),
            "kurtosis": float(stats.kurtosis(x)),
        },
        "plot_path": plot,
        "interpretation": f"Jarque-Bera={jb:.3f}, p={jb_p:.4g}."
    }


def residual_diagnostics(df, outcome, predictor):
    tmp = paired_numeric(df, outcome, predictor)
    if len(tmp) < 3:
        raise ValueError("Residual diagnostics need numeric outcome and predictor.")
    y = tmp[outcome]
    X = sm.add_constant(tmp[[predictor]])
    model = sm.OLS(y, X).fit()
    resid = model.resid

    bp = sm.stats.diagnostic.het_breuschpagan(resid, model.model.exog)

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.scatter(model.fittedvalues, resid, s=16)
    ax.axhline(0, linestyle="--")
    ax.set_xlabel("Fitted values")
    ax.set_ylabel("Residuals")
    ax.set_title("Residuals vs fitted")
    plot = save_plot(fig, "residual_diagnostics")

    return {
        "analysis": "Residual diagnostics",
        "outcome": outcome,
        "predictor": predictor,
        "n": int(len(tmp)),
        "metrics": {
            "residual_mean": float(np.mean(resid)),
            "residual_sd": float(np.std(resid, ddof=1)),
            "breusch_pagan_lm": float(bp[0]),
            "breusch_pagan_p": float(bp[1]),
        },
        "plot_path": plot,
        "interpretation": f"Residual SD={np.std(resid, ddof=1):.3f}, Breusch-Pagan p={bp[1]:.4g}."
    }


def survival_km(df, time, event):
    try:
        from lifelines import KaplanMeierFitter
    except Exception:
        raise ValueError("lifelines is not installed. Run: pip install lifelines")

    tmp = df[[time, event]].copy()
    tmp[time] = pd.to_numeric(tmp[time], errors="coerce")
    tmp[event] = infer_bool_series(tmp[event])
    tmp = tmp.dropna()

    km = KaplanMeierFitter()
    km.fit(tmp[time], event_observed=tmp[event])

    fig, ax = plt.subplots(figsize=(7, 4))
    km.plot_survival_function(ax=ax)
    ax.set_title("Kaplan-Meier")
    plot = save_plot(fig, "kaplan_meier")

    return {
        "analysis": "Kaplan-Meier",
        "outcome": time,
        "predictor": event,
        "n": int(len(tmp)),
        "metrics": {
            "median_survival": clean_value(km.median_survival_time_),
        },
        "plot_path": plot,
        "interpretation": f"Kaplan-Meier median survival: {km.median_survival_time_}."
    }


def log_rank(df, time, event, group):
    try:
        from lifelines.statistics import logrank_test
        from lifelines import KaplanMeierFitter
    except Exception:
        raise ValueError("lifelines is not installed. Run: pip install lifelines")

    tmp = df[[time, event, group]].copy()
    tmp[time] = pd.to_numeric(tmp[time], errors="coerce")
    tmp[event] = infer_bool_series(tmp[event])
    tmp = tmp.dropna()

    groups = list(tmp.groupby(group))
    if len(groups) != 2:
        raise ValueError("Log-rank currently requires exactly two groups.")

    a_label, a = groups[0]
    b_label, b = groups[1]
    res = logrank_test(a[time], b[time], event_observed_A=a[event], event_observed_B=b[event])

    fig, ax = plt.subplots(figsize=(7, 4))
    km = KaplanMeierFitter()
    km.fit(a[time], a[event], label=str(a_label))
    km.plot_survival_function(ax=ax)
    km.fit(b[time], b[event], label=str(b_label))
    km.plot_survival_function(ax=ax)
    ax.set_title("Log-rank survival curves")
    plot = save_plot(fig, "log_rank")

    return {
        "analysis": "Log-rank",
        "outcome": time,
        "predictor": event,
        "group": group,
        "n": int(len(tmp)),
        "metrics": {
            "logrank_statistic": float(res.test_statistic),
            "p_value": float(res.p_value),
        },
        "plot_path": plot,
        "interpretation": f"Log-rank χ²={res.test_statistic:.3f}, p={res.p_value:.4g}."
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--method", required=True)
    parser.add_argument("--outcome", required=True)
    parser.add_argument("--predictor", default=None)
    parser.add_argument("--group", default=None)
    args = parser.parse_args()

    try:
        df = read_dataset(args.file)
        method = args.method

        if method == "descriptive":
            payload = descriptive(df, args.outcome)
        elif method == "pearson":
            payload = pearson(df, args.outcome, args.predictor)
        elif method == "spearman":
            payload = spearman(df, args.outcome, args.predictor)
        elif method == "welchTTest":
            payload = welch_ttest(df, args.outcome, args.group)
        elif method == "mannWhitneyU":
            payload = mann_whitney(df, args.outcome, args.group)
        elif method == "pairedTTest":
            payload = paired_ttest(df, args.outcome, args.predictor)
        elif method == "wilcoxonSignedRank":
            payload = wilcoxon(df, args.outcome, args.predictor)
        elif method == "chiSquare":
            payload = chi_square(df, args.outcome, args.group)
        elif method == "fisherExact2x2":
            payload = fisher_exact(df, args.outcome, args.group)
        elif method == "kruskalWallis":
            payload = kruskal(df, args.outcome, args.group)
        elif method in ["simpleLinearRegression", "multipleLinearRegression"]:
            payload = linear_regression(df, args.outcome, args.predictor)
            if method == "multipleLinearRegression":
                payload["analysis"] = "Multiple regression prototype"
                payload["warning"] = "Currently using one predictor. Multi-predictor UI comes next."
        elif method == "logisticRegression":
            payload = logistic_regression(df, args.outcome, args.predictor)
        elif method == "rocAuc":
            payload = roc_auc(df, args.outcome, args.predictor)
        elif method == "diagnosticMetrics":
            payload = diagnostic_metrics(df, args.outcome, args.predictor)
        elif method == "riskComparison":
            payload = risk_comparison(df, args.outcome, args.group)
        elif method == "kaplanMeier":
            payload = survival_km(df, args.outcome, args.predictor)
        elif method == "logRank":
            payload = log_rank(df, args.outcome, args.predictor, args.group)
        elif method == "normalityJarqueBera":
            payload = normality(df, args.outcome)
        elif method == "residualDiagnostics":
            payload = residual_diagnostics(df, args.outcome, args.predictor)
        else:
            raise ValueError(f"Unknown method: {method}")

        payload["ok"] = True
        result(**payload)

    except Exception as e:
        result(ok=False, error=str(e), analysis=args.method, interpretation=f"Analysis failed: {e}")


if __name__ == "__main__":
    main()
