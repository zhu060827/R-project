# MusicPulse EDA Submission

This folder contains the three final exploratory data analysis reports for the MusicPulse project:

- `analysis/douyin_eda.Rmd` and `analysis/douyin_eda.html`
- `analysis/kugou_eda.Rmd` and `analysis/kugou_eda.html`
- `analysis/platform_combined_eda.Rmd` and `analysis/platform_combined_eda.html`
- `analysis/US_Music_Dataset_EDA.qmd` and `analysis/US_Music_Dataset_EDA.html`

The reports document data cleaning decisions, missing-value and duplicate handling, descriptive summaries, visual exploration, written interpretation, and limitations. The HTML files are the ready-to-read report outputs; the R Markdown/Quarto files are the reproducible source files.

## Data access

The four China processed datasets are provided in the separate sibling package `../data_submission/data/processed/`:

- `douyin_master_dataset.csv`
- `kugou_analysis_dataset.csv`
- `platform_song_coding.csv`
- `platform_song_daily_panel.csv`

The EDA source files automatically locate this sibling data package when rendered from the submission layout. The integrated EDA reconstructs its platform-level observation table from the daily panel, so a separate audit CSV is not required. The U.S. EDA reads the four processed U.S. tables from `../data_submission/data/processed/us/` and compares them with the China coding table.

The EDA package deliberately contains no `data/` folder. The four processed U.S. datasets used by the comparative EDA are kept in `../data_submission/data/processed/us/`: `coding_clean.csv`, `daily_clean.csv`, `spotify_clean.csv`, and `tiktok_clean.csv`.

## Render the U.S. Quarto report

From this folder, run:

```bash
quarto render analysis/US_Music_Dataset_EDA.qmd
```

The U.S. report requires Quarto, R, `tidyverse`, `scales`, and `RColorBrewer`.

## Reproduce the reports

From this folder, run:

```r
Rscript scripts/render_eda.R
```

The script renders all three reports from the local `analysis/` and `data/` folders. Required R packages are `rmarkdown`, `knitr`, `tidyverse`, `lubridate`, `jsonlite`, `patchwork`, `plotly`, `ggrepel`, and `scales`.

## Scope and interpretation

The reports are descriptive EDA. Douyin source usage counts are retained as source-provided usage-scale fields, not certified plays or daily-new-user measures. Genre and Mood are harmonized, multi-label variables; their counts and shares are descriptive and are not mutually exclusive song proportions. Cross-platform matching is title-based and should not be interpreted as confirmed recording identity.

## Submission alignment

This package addresses the EDA deliverable in the course requirements: reproducible R Markdown reports, visual exploration, written interpretation, data-quality decisions, initial findings, and limitations. The wider final-project package should additionally include the literature review, dashboard design, Shiny application, final report, slides, and individual reflections.
