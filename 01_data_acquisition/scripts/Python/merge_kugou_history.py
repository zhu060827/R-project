#!/usr/bin/env python3
"""Merge chunked KuGou history files and recompute full-window trajectories."""

import argparse
import json
from pathlib import Path
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parts", type=Path, default=Path("kugou_2y_parts"))
    ap.add_argument("--out", type=Path, default=Path("kugou_history_2year_final"))
    args = ap.parse_args()
    files = sorted(args.parts.glob("p*/kugou_top100_*.csv"))
    if len(files) != 12:
        raise RuntimeError(f"Expected 12 chunk files, found {len(files)}")
    df = pd.concat([pd.read_csv(p) for p in files], ignore_index=True)
    # Chunk files may already contain local derived columns; discard them
    # before recomputing against the complete two-year window.
    df = df.drop(columns=[c for c in ["pre_rank", "velocity", "peak_rank", "peak_date", "time_on_chart", "rankStats"] if c in df.columns])
    df["chart_date"] = pd.to_datetime(df["chart_date"])
    df = df.sort_values(["kugou_song_id", "chart_date"]).reset_index(drop=True)
    df["pre_rank"] = df.groupby("kugou_song_id")["rank"].shift(1)
    df["velocity"] = (df["pre_rank"] - df["rank"]) / df["pre_rank"]
    stats = df.groupby("kugou_song_id").agg(
        peak_rank=("rank", "min"),
        time_on_chart=("rank", "count"),
    ).reset_index()
    peak_dates = (
        df.sort_values(["kugou_song_id", "rank", "chart_date"])
        .drop_duplicates("kugou_song_id")[["kugou_song_id", "chart_date"]]
        .rename(columns={"chart_date": "peak_date"})
    )
    df = df.merge(stats, on="kugou_song_id", how="left").merge(peak_dates, on="kugou_song_id", how="left")
    rank_stats = df.groupby("kugou_song_id", sort=False).apply(
        lambda x: json.dumps(
            [{"rank": int(r), "timestp": d.strftime("%Y-%m-%d")} for d, r in zip(x["chart_date"], x["rank"])],
            ensure_ascii=False,
        ), include_groups=False
    ).rename("rankStats")
    df = df.merge(rank_stats, on="kugou_song_id", how="left")
    df["chart_date"] = df["chart_date"].dt.strftime("%Y-%m-%d")
    df["peak_date"] = pd.to_datetime(df["peak_date"]).dt.strftime("%Y-%m-%d")
    args.out.mkdir(parents=True, exist_ok=True)
    output = args.out / "kugou_top100_2024-11-14_2026-11-13.csv"
    df.to_csv(output, index=False, encoding="utf-8-sig")
    print(json.dumps({
        "rows": len(df),
        "dates": int(df.chart_date.nunique()),
        "unique_tracks": int(df.kugou_song_id.nunique()),
        "min_date": df.chart_date.min(),
        "max_date": df.chart_date.max(),
        "output": str(output),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
