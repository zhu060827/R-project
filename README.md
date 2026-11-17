# MusicPulse China and U.S. Music Datasets

This project contains two music datasets and their associated data-processing materials: a China dataset and a U.S. dataset.

## Project structure

```text
R-project/
├── README.md
├── 01_data_acquisition/
├── 02_douyin_cleaning/
├── 03_kugou_cleaning/
├── 04_cross_platform_integration/
├── 05_validation/
├── 06_us_data_cleaning/
├── run_all.R
└── requirements.txt
```

## China dataset

The China dataset covers Douyin and KuGou data acquisition, cleaning, harmonization, cross-platform integration, and validation.

- `01_data_acquisition/` contains retained raw JSON/API inputs, source manifests, acquisition scripts, and intermediate tables.
- `02_douyin_cleaning/` contains Douyin import, cleaning, metadata, observation, and quality-validation outputs.
- `03_kugou_cleaning/` contains KuGou daily and track-level tables, processing scripts, and quality checks.
- `04_cross_platform_integration/` contains the harmonized China platform coding table and daily panel.
- `05_validation/` contains handoff and reproducibility checks.

Run the main R workflow from the project root:

```bash
Rscript run_all.R
```

## U.S. dataset

The U.S. dataset is used for the later China--U.S. platform comparison. It contains TikTok, Spotify, daily cross-platform time-series, and coded music records.

Within `06_us_data_cleaning/`:

- `data/raw/` contains the original imported datasets.
- `data/processed/` contains the cleaned datasets used for subsequent comparative EDA.
- `data_manifest.csv` records the role and source name of each file.
- `scripts/R/US_Music_Dataset_Cleaning.qmd` documents data selection, quality assessment, cleaning decisions, and exported analysis tables.

## Data-processing principles

Raw data are retained separately from processed data. Dates, identifiers, ranks, durations, missing values, duplicate keys, and platform-specific fields are checked before analysis. Original Genre and Mood fields are preserved, while harmonized fields are constructed for comparison. AI-assisted or rule-assisted classifications are treated as derived variables rather than official native labels.

## Reproducibility and scope

The scripts and data in this repository provide the acquisition and data-processing evidence for the project. Formal EDA reports, the final written report, presentation slides, individual reflections, and the Shiny application are maintained separately in the final course submission package.

R packages used by the main workflow include `tidyverse`, `jsonlite`, `lubridate`, and `digest`. Python is retained only for selected original KuGou acquisition utilities and supporting metadata operations.
