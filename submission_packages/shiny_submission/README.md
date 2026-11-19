# MusicPulse Shiny Submission

This is the cleaned Shiny submission package for the MusicPulse project. It preserves the four-page interaction design from the supplied `MusicPulse-Final` project while reading the processed datasets already stored in the sibling `data_submission` package.

## Run

From this directory:

```r
source("requirements.R")
source("run_app.R")
```

Then open `http://127.0.0.1:8765`.

The launcher is portable: it resolves the application directory from `run_app.R`, and `R/direct_data.R` reads the six processed CSV inputs from:

```text
../data_submission/data/processed/
```

The Shiny package does not duplicate the large analytical CSVs. Local preview metadata and the permitted audio excerpts remain under `data/music_preview_research/` so the preview interaction is preserved.

## Application structure

- `app.R`: assembles the UI and page server factories.
- `R/`: data loading, page-specific logic, plots, modules, theme, and preview helpers.
- `www/`: CSS and JavaScript assets for navigation, plots, styling, and audio controls.
- `data/music_preview_research/`: preview registries and permitted local preview assets.
- `requirements.R`: installs only missing R package dependencies.
- `run_app.R`: the supported local launcher.

## Data mapping

| Shiny input | Processed submission file |
|---|---|
| China coding | `../data_submission/data/processed/platform_song_coding.csv` |
| China daily panel | `../data_submission/data/processed/platform_song_daily_panel.csv` |
| Douyin native data | `../data_submission/data/processed/douyin_master_dataset.csv` |
| KuGou native data | `../data_submission/data/processed/kugou_analysis_dataset.csv` |
| U.S. coding | `../data_submission/data/processed/us/coding_clean.csv` |
| U.S. daily data | `../data_submission/data/processed/us/daily_clean.csv` |

The app loads these files once when the process starts. Filters operate on the in-memory tables and do not create or overwrite source data.

## Validation

The app was smoke-tested by sourcing `app.R`; the six processed inputs loaded successfully and the Shiny app object was created.
