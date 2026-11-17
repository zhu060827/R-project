#!/usr/bin/env python3
"""Recover recent KuGou historical chart periods and the first Top-K tracks.

This uses KuGou's public mobile chart-period and chart-song responses. It does
not infer dates from the current web page: every row is bound to a returned
volid and rank publication timestamp.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import time
from pathlib import Path

import pandas as pd
import requests


BASE = "http://mobilecdnbj.kugou.com/api/v3/rank"
UA = "Mozilla/5.0 (compatible; research-pilot/1.0)"


def get_json(session, url, params):
    r = session.get(url, params=params, headers={"User-Agent": UA}, timeout=45)
    r.raise_for_status()
    # The endpoint sometimes returns a harmless anti-JSON marker.
    text = r.text
    if "<!--KG_TAG_RES_START-->" in text:
        text = text.split("<!--KG_TAG_RES_START-->", 1)[1]
    if "<!--KG_TAG_RES_END-->" in text:
        text = text.split("<!--KG_TAG_RES_END-->", 1)[0]
    return json.loads(text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rank-id", default="8888")
    ap.add_argument("--top-k", type=int, default=100)
    ap.add_argument("--days", type=int, default=14)
    ap.add_argument("--start-date", default=None, help="YYYY-MM-DD; inclusive, overrides days when end-date is set")
    ap.add_argument("--end-date", default=None, help="YYYY-MM-DD; defaults to today in local timezone")
    ap.add_argument("--out", default="kugou_history_14day")
    ap.add_argument("--sleep", type=float, default=0.5)
    args = ap.parse_args()

    end = dt.date.fromisoformat(args.end_date) if args.end_date else dt.date.today()
    start = dt.date.fromisoformat(args.start_date) if args.start_date else end - dt.timedelta(days=args.days - 1)
    requested_days = (end - start).days + 1
    out = Path(args.out)
    raw = out / "raw_api"
    raw.mkdir(parents=True, exist_ok=True)
    session = requests.Session()

    periods = get_json(session, f"{BASE}/vol", {
        "ranktype": 2, "plat": 0, "rankid": args.rank_id,
        "with_res_tag": 1,
    })
    (raw / "rank_vol.json").write_text(json.dumps(periods, ensure_ascii=False, indent=2), encoding="utf-8")
    all_periods = []
    for year in periods.get("data", {}).get("info", []):
        all_periods.extend(year.get("vols", []))
    selected = []
    for p in all_periods:
        date_text = (p.get("voltime") or "")[:10]
        try:
            d = dt.date.fromisoformat(date_text)
        except ValueError:
            continue
        if start <= d <= end:
            selected.append({"chart_date": date_text, "volid": str(p["volid"]), "volname": p.get("volname")})
    selected.sort(key=lambda x: x["chart_date"])
    if len(selected) != requested_days:
        raise RuntimeError(f"Expected {requested_days} historical periods from {start} to {end}, found {len(selected)}: {selected}")

    rows = []
    for period in selected:
        data = get_json(session, f"{BASE}/song", {
            "version": 9108, "ranktype": 2, "plat": 0,
            "pagesize": 100, "area_code": 1, "page": 1,
            "volid": period["volid"], "rankid": args.rank_id,
            "with_res_tag": 1,
        })
        (raw / f"rank_song_{period['chart_date']}_{period['volid']}.json").write_text(
            json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
        )
        info = data.get("data", {}).get("info", [])
        if len(info) < args.top_k:
            raise RuntimeError(f"Period {period} returned only {len(info)} songs")
        for i, song in enumerate(info[:args.top_k], start=1):
            authors = song.get("authors") or []
            artist_names = [a.get("author_name") for a in authors if a.get("author_name")]
            rows.append({
                "platform": "kugou",
                "chart_name": "KuGou Top 100",
                "chart_date": period["chart_date"],
                "period_id": period["volid"],
                "collected_at": dt.datetime.now().astimezone().isoformat(timespec="seconds"),
                "rank": i,
                "rank_source": "kugou_historical_api",
                "kugou_song_id": str(song.get("audio_id") or song.get("mixsongid") or song.get("album_audio_id") or ""),
                "kugou_hash": song.get("hash"),
                "track_name": song.get("songname"),
                "artist_name": ", ".join(artist_names),
                "artist_ids": ",".join(str(a.get("author_id")) for a in authors if a.get("author_id")),
                "album_id": song.get("album_id"),
                "album_name": song.get("album_name"),
                "duration_ms": int(song.get("duration", 0) or 0) * 1000,
                "release_date": None,
                "lyrics": None,
                "native_score": None,
                "source_url": f"https://www.kugou.com/mixsong/{song.get('encode_album_audio_id','')}.html",
                "historical_source": "kugou_mobile_rank_api",
            })
        time.sleep(args.sleep)

    df = pd.DataFrame(rows)
    # Derived trajectory fields use only the recovered daily rank panel.
    # A positive velocity means the song improved its rank versus the prior
    # available day; rank 1 is the best rank.
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
    rank_stats = (
        df.groupby("kugou_song_id", sort=False)
        .apply(lambda x: [{"rank": int(r), "timestp": d.strftime("%Y-%m-%d")} for d, r in zip(x["chart_date"], x["rank"])], include_groups=False)
        .rename("rankStats")
    )
    df = df.merge(rank_stats, on="kugou_song_id", how="left")
    df["chart_date"] = df["chart_date"].dt.strftime("%Y-%m-%d")
    snapshot = out / f"kugou_top{args.top_k}_{start}_{end}.csv"
    df.to_csv(snapshot, index=False, encoding="utf-8-sig")
    periods_df = pd.DataFrame(selected)
    periods_df.to_csv(out / "historical_periods.csv", index=False, encoding="utf-8-sig")
    print(json.dumps({
        "date_range": [str(start), str(end)],
        "periods": len(selected),
        "rows": len(df),
        "unique_period_ids": int(df.period_id.nunique()),
        "unique_track_ids": int(df.kugou_song_id.nunique()),
        "snapshot": str(snapshot),
        "period_index": str(out / "historical_periods.csv"),
        "raw_api": str(raw),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
