#!/usr/bin/env python3
"""Enrich unique KuGou tracks with public album metadata and lyrics."""

from __future__ import annotations
import argparse, base64, json, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import pandas as pd
import requests

UA = "Mozilla/5.0 (compatible; research-pilot/1.0)"


def session():
    s = requests.Session()
    s.headers.update({"User-Agent": UA})
    return s


def fetch(row):
    s = session()
    out = dict(row)
    album_id = str(row.get("album_id") or "")
    h = str(row.get("kugou_hash") or "")
    try:
        if album_id and album_id != "nan":
            r = s.get("http://mobilecdnbj.kugou.com/api/v3/album/info", params={"albumid": album_id, "version": 9108, "plat": 0}, timeout=30)
            a = r.json().get("data") or {}
            out.update({"album_name": a.get("albumname"), "release_date": (a.get("publishtime") or "")[:10] or None, "cover_url": a.get("imgurl")})
        if h and h != "nan":
            r = s.get("http://krcs.kugou.com/search", params={"ver": 1, "man": "yes", "client": "mobi", "keyword": "", "duration": "", "hash": h, "album_audio_id": ""}, timeout=30)
            cands = r.json().get("candidates") or []
            # Prefer official/recommended lyrics over user-generated candidates.
            cands.sort(key=lambda x: ("官方" not in str(x.get("product_from", "")), -float(x.get("score", 0))))
            if cands:
                cand = cands[0]
                lr = s.get("https://lyrics.kugou.com/download", params={"ver": 1, "client": "pc", "fmt": "lrc", "charset": "utf8", "accesskey": cand.get("accesskey"), "id": cand.get("id")}, timeout=30)
                payload = lr.json()
                content = payload.get("content")
                if content:
                    out["lyrics"] = base64.b64decode(content).decode("utf-8", errors="replace")
                    out["lyrics_source"] = "kugou_lyrics_api"
                    out["lyrics_status"] = "found"
                else:
                    out["lyrics_status"] = "empty"
            else:
                out["lyrics_status"] = "not_found"
    except Exception as e:
        out["metadata_error"] = type(e).__name__
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", type=Path, default=Path("kugou_history_2year_final/kugou_top100_2024-11-14_2026-11-13.csv"))
    ap.add_argument("--out", type=Path, default=Path("kugou_history_2year_final/kugou_track_master.csv"))
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()
    d = pd.read_csv(args.input)
    cols = ["kugou_song_id", "kugou_hash", "track_name", "artist_name", "artist_ids", "album_id", "duration_ms"]
    master = d.sort_values("chart_date").drop_duplicates("kugou_song_id")[cols].copy()
    master["lyrics"] = None
    master["lyrics_source"] = None
    master["lyrics_status"] = None
    master["metadata_error"] = None
    rows = []
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = [ex.submit(fetch, row) for row in master.to_dict("records")]
        for i, f in enumerate(as_completed(futures), 1):
            rows.append(f.result())
            if i % 250 == 0:
                print(f"completed {i}/{len(futures)}", flush=True)
    out = pd.DataFrame(rows).sort_values("kugou_song_id")
    out.to_csv(args.out, index=False, encoding="utf-8-sig")
    print(json.dumps({"unique_tracks": len(out), "lyrics_found": int((out.lyrics_status == "found").sum()), "album_names": int(out.album_name.notna().sum()), "release_dates": int(out.release_date.notna().sum()), "output": str(args.out)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
