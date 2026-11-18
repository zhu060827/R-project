# EDA Data Access

The four processed datasets used by the EDA reports are stored in the sibling package `submission_packages/data_submission/data/processed/`.

The EDA source files use the following processed tables:

| Report | Required data |
|---|---|
| Douyin EDA | `data/processed/douyin_master_dataset.csv` |
| KuGou EDA | `data/processed/kugou_analysis_dataset.csv` |
| Integrated EDA | `data/processed/platform_song_coding.csv`, `data/processed/platform_song_daily_panel.csv`, and `data/audit/platform_combined_overlap_observations.csv` |

The EDA package intentionally contains no duplicate data folder. The integrated EDA reconstructs platform observations from the daily panel and therefore uses only these four tables.
