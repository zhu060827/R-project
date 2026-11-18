# MusicPulse Processed Data Package

This package contains the four processed datasets used by the three EDA reports:

- `data/processed/douyin_master_dataset.csv`
- `data/processed/kugou_analysis_dataset.csv`
- `data/processed/platform_song_coding.csv`
- `data/processed/platform_song_daily_panel.csv`

The EDA source files in `../eda_submission/analysis/` automatically locate this package when rendered from the submission layout. The integrated EDA reconstructs its platform-level observations from the daily panel and coding table, so no fifth audit dataset is required.

The two large platform-level CSVs are intentionally kept outside the GitHub source-only EDA upload because they exceed GitHub's ordinary individual-file size limit. They should be included in the final compressed submission folder or stored with Git LFS when the full repository is uploaded.
