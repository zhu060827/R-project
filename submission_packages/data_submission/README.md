# MusicPulse Processed Data Package

This package contains the processed datasets used by the project reports and the formal Shiny submission.

## China EDA data

- `data/processed/douyin_master_dataset.csv`
- `data/processed/kugou_analysis_dataset.csv`
- `data/processed/platform_song_coding.csv`
- `data/processed/platform_song_daily_panel.csv`

The EDA source files in `../eda_submission/analysis/` automatically locate this package when rendered from the submission layout. The integrated EDA reconstructs its platform-level observations from the daily panel and coding table, so no fifth audit dataset is required.

## U.S. processed data

The processed U.S. data from the earlier cleaning step are stored under `data/processed/us/`:

- `coding_clean.csv`
- `daily_clean.csv`
- `spotify_clean.csv`
- `tiktok_clean.csv`

These tables are the cleaned inputs for the U.S. EDA and later China–U.S. comparative analysis. The U.S. Quarto source is `../eda_submission/analysis/US_Music_Dataset_EDA.qmd`.

The large platform-level CSVs may be excluded from the GitHub source-only mirror because they exceed GitHub's ordinary individual-file size limit. They must remain in this local final submission package and be included in the final compressed submission folder, or be stored with Git LFS when the full repository is uploaded.
