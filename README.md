# MusicPulse Data Processing Evidence

This package contains the data acquisition, cleaning, harmonization, integration, and validation materials used in the report. It is a component of the final project submission, not the complete final report package.

## Structure

```text
data_processing_evidence/
├── README.md
├── run_all.R
├── requirements.txt
├── 01_data_acquisition/
│   ├── data/
│   │   ├── raw/
│   │   ├── intermediate/
│   │   ├── processed/
│   │   └── source/
│   └── scripts/
│       ├── R/
│       └── Python/
├── 02_douyin_cleaning/
│   ├── data/
│   │   ├── processed/
│   │   └── upstream/
│   ├── scripts/R/
│   └── validation/
├── 03_kugou_cleaning/
│   ├── data/
│   │   ├── intermediate/
│   │   └── processed/
│   └── scripts/R/
├── 04_cross_platform_integration/
│   ├── data/processed/
│   └── scripts/R/
├── 05_validation/
│   └── outputs/
└── 06_us_data_cleaning/
    ├── data/
    │   ├── raw/
    │   └── processed/
    ├── data_manifest.csv
    └── scripts/R/US_Music_Dataset_Cleaning.qmd
```

Every numbered folder uses the same principle: scripts are separated from data, and data are grouped as raw, intermediate, processed, source, or validation outputs.

## R workflow

Run from this directory:

```bash
Rscript run_all.R
```

`run_all.R` is the only package entry point. It runs the Douyin R cleaning step, reconstructs the KuGou intermediate tables, validates the integrated handoff files, and writes `05_validation/outputs/package_check_summary.csv`.

Rebuild the KuGou intermediate tables:

```bash
Rscript 03_kugou_cleaning/scripts/R/reconstruct_intermediates.R
```

Parse the retained raw files with R:

```bash
Rscript 01_data_acquisition/scripts/R/parse_kugou_api.R
Rscript 01_data_acquisition/scripts/R/parse_douyin_json.R
```

The KuGou raw API parser was tested on 730 JSON responses and produced 73,000 daily observations. The R package-level check reads the retained source and final schemas and writes `05_validation/outputs/package_check_summary.csv`.

## Main data products

- `01_data_acquisition/data/processed/kugou_top100_2year_enriched.csv`
- `02_douyin_cleaning/data/processed/douyin_master_dataset.csv`
- `03_kugou_cleaning/data/processed/kugou_analysis_dataset.csv`
- `04_cross_platform_integration/data/processed/platform_song_coding.csv`
- `04_cross_platform_integration/data/processed/platform_song_daily_panel.csv`

The recovered KuGou intermediate tables are in `03_kugou_cleaning/data/intermediate/`. The complete Douyin `hot-music.json` archive is in `01_data_acquisition/data/raw/douyin_json/`, with 2,133 daily files covering 2021-01-11 to 2026-11-13. The full cleaned Douyin observations and metadata handoff tables are in `02_douyin_cleaning/data/upstream/`.

## U.S. comparison-data branch

`06_us_data_cleaning/` contains the U.S. platform data that will be used in the later China--U.S. platform comparison. It is a formal data branch of the project, not merely supplementary evidence. The branch contains raw TikTok, Spotify, daily time-series, and coding files, together with the corresponding cleaned tables. `data_manifest.csv` records the role and original source name of each file.

Within this branch, `data/raw/` contains the original imported datasets and `data/processed/` contains the cleaned analysis datasets. The processed tables should be used for the later comparative EDA, while the raw tables provide acquisition and cleaning evidence. To reproduce the cleaning document, open `06_us_data_cleaning/scripts/R/US_Music_Dataset_Cleaning.qmd` in RStudio or render it from the `06_us_data_cleaning` directory.

## Category handling

Original Genre and Mood fields are retained. Harmonized Genre uses six categories: `Pop`, `Rock`, `R&B / Soul`, `Hip Hop / Rap`, `Dance / Electronic`, and `Other`. Platform-specific classifications are preserved alongside combined fields and conflict flags. KuGou category values may be AI-assisted or rule-assisted derived variables, not official native labels.

## Scope

This package excludes formal EDA reports, the final report, presentation slides, individual reflections, and the Shiny application. Those items belong in the parent final submission package.

Python is optional for the retained processed-data workflow and is only needed for the original KuGou API acquisition utilities. R packages used by the main workflow include `tidyverse`, `jsonlite`, `lubridate`, and `digest`.
