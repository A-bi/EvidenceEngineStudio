#!/usr/bin/env python3
import argparse
import json
import math
import sqlite3
from pathlib import Path

import numpy as np
import pandas as pd


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


def read_dataset(path: str, table: str | None = None) -> pd.DataFrame:
    p = Path(path)
    ext = p.suffix.lower()

    if ext == ".csv":
        try:
            return pd.read_csv(p, encoding="utf-8")
        except UnicodeDecodeError:
            return pd.read_csv(p, encoding="latin1")
        except Exception:
            return pd.read_csv(p, sep=";", encoding="latin1")

    if ext == ".tsv":
        return pd.read_csv(p, sep="\t", encoding="utf-8")

    if ext == ".txt":
        try:
            return pd.read_csv(p, sep=None, engine="python", encoding="utf-8")
        except UnicodeDecodeError:
            return pd.read_csv(p, sep=None, engine="python", encoding="latin1")

    if ext in [".xlsx", ".xls"]:
        return pd.read_excel(p)

    if ext == ".json":
        return pd.read_json(p)

    if ext == ".parquet":
        return pd.read_parquet(p)

    if ext == ".dta":
        return pd.read_stata(p)

    if ext == ".sav":
        return pd.read_spss(p)

    if ext in [".sqlite", ".db"]:
        con = sqlite3.connect(p)
        try:
            if table is None:
                tables = pd.read_sql_query(
                    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
                    con,
                )["name"].tolist()

                if not tables:
                    raise ValueError("SQLite database contains no tables.")

                table = tables[0]

            return pd.read_sql_query(f'SELECT * FROM "{table}"', con)
        finally:
            con.close()

    if ext in [".mdb", ".accdb"]:
        raise ValueError(
            "Access databases are recognized, but require an additional Access/ODBC or mdbtools adapter."
        )

    raise ValueError(f"Unsupported file type: {ext}")


def infer_variable_type(s: pd.Series) -> str:
    non_missing = s.dropna()

    if non_missing.empty:
        return "text"

    numeric = pd.to_numeric(non_missing, errors="coerce")
    numeric_ratio = numeric.notna().mean()

    lower_values = non_missing.astype(str).str.strip().str.lower()
    bool_like = lower_values.isin(
        ["0", "1", "true", "false", "yes", "no", "ja", "nein"]
    ).mean()

    unique_count = non_missing.nunique(dropna=True)

    if bool_like >= 0.95 and unique_count <= 2:
        return "boolean"

    if numeric_ratio >= 0.95:
        if unique_count <= 10:
            return "numeric_discrete"
        return "numeric_continuous"

    if unique_count <= 30:
        return "categorical"

    return "text"


def summarize(path: str, table: str | None = None, preview_rows: int = 50) -> dict:
    df = read_dataset(path, table=table)

    column_names = [str(c) for c in df.columns]
    variable_types = {str(c): infer_variable_type(df[c]) for c in df.columns}
    missing_counts = {str(c): int(df[c].isna().sum()) for c in df.columns}

    preview_df = df.head(preview_rows).copy()
    preview = [
        {str(k): clean_value(v) for k, v in row.items()}
        for row in preview_df.to_dict(orient="records")
    ]

    return {
        "ok": True,
        "file": path,
        "rows": int(df.shape[0]),
        "columns": int(df.shape[1]),
        "column_names": column_names,
        "variable_types": variable_types,
        "missing_counts": missing_counts,
        "preview": preview,
        "source": Path(path).suffix.lower().replace(".", "").upper() or "DATA",
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True)
    parser.add_argument("--table", default=None)
    args = parser.parse_args()

    try:
        payload = summarize(args.file, table=args.table)
    except Exception as e:
        payload = {
            "ok": False,
            "error": str(e),
            "file": args.file,
        }

    print(json.dumps(payload, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
