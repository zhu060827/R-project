# MusicPulse EDA Submission

This folder contains the three final exploratory data analysis reports for the MusicPulse project:

- `analysis/douyin_eda.Rmd` and `analysis/douyin_eda.html`
- `analysis/kugou_eda.Rmd` and `analysis/kugou_eda.html`
- `analysis/platform_combined_eda.Rmd` and `analysis/platform_combined_eda.html`

The reports document data cleaning decisions, missing-value and duplicate handling, descriptive summaries, visual exploration, written interpretation, and limitations. The HTML files are the ready-to-read report outputs; the R Markdown files are the reproducible source files.

## Data access

The large processed datasets are retained in the project data-processing package and are not duplicated in this compressed EDA submission archive. The source filenames used by the reports are `douyin_master_dataset.csv`, `kugou_analysis_dataset.csv`, `platform_song_coding.csv`, `platform_song_daily_panel.csv`, and `platform_combined_overlap_observations.csv`. The EDA reports expect them under `data/processed/` and `data/audit/` in a full project checkout. This keeps the GitHub submission below GitHub's individual-file size limits while preserving the complete report source and outputs.

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
