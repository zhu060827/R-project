#!/usr/bin/env python3
import argparse
from pathlib import Path
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--history", type=Path, default=Path("kugou_history_2year_final/kugou_top100_2024-11-14_2026-11-13.csv"))
    ap.add_argument("--master", type=Path, default=Path("kugou_history_2year_final/kugou_track_master.csv"))
    ap.add_argument("--out", type=Path, default=Path("kugou_history_2year_final/kugou_top100_2year_enriched.csv"))
    args = ap.parse_args()
    h = pd.read_csv(args.history)
    m = pd.read_csv(args.master)
    add = m[["kugou_song_id", "album_name", "release_date", "lyrics", "lyrics_source", "lyrics_status", "cover_url"]].drop_duplicates("kugou_song_id")
    h = h.drop(columns=[c for c in ["album_name", "release_date", "lyrics"] if c in h.columns]).merge(add, on="kugou_song_id", how="left")
    h.to_csv(args.out, index=False, encoding="utf-8-sig")
    print(f"wrote {len(h)} rows to {args.out}")


if __name__ == "__main__":
    main()
