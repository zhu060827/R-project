# MusicPulse / R-project

MusicPulse is an R-based research project for collecting, cleaning, harmonizing, and comparing music observations from Douyin and KuGou, with an additional China–United States comparison based on the available U.S. platform data.

This repository contains the final exploratory data analysis (EDA) reports, the formal project code and data packages, and the deployed Shiny application source. The four formal project directories are located directly at the repository root so that the submission structure is easy to inspect.

## Live results

The four final EDA pages are published through GitHub Pages:

- [U.S. Music Dataset EDA](https://zhu060827.github.io/R-project/US_Music_Dataset_EDA.html)
- [Douyin EDA](https://zhu060827.github.io/R-project/douyin_eda.html)
- [KuGou EDA](https://zhu060827.github.io/R-project/kugou_eda.html)
- [Integrated Cross-platform EDA](https://zhu060827.github.io/R-project/platform_combined_eda.html)

The interactive four-page MusicPulse dashboard is deployed separately on shinyapps.io:

- [Open the MusicPulse Shiny application](https://zhu060827.shinyapps.io/musicpulse/)

The Shiny application is the interactive presentation layer for the processed data. The GitHub Pages reports are static rendered documents and do not replace the Shiny application.

## Repository structure

~~~text
.
├── data_processing/       # Acquisition, cleaning, integration, validation, and data notes
├── data_submission/       # Processed data used by reports and the Shiny application
├── eda_submission/        # EDA source files, scripts, and rendered report artifacts
├── shiny_submission/      # The only formal Shiny source and deployment package
├── US_Music_Dataset_EDA.html
├── douyin_eda.html
├── kugou_eda.html
├── platform_combined_eda.html
├── .github/workflows/     # GitHub Pages deployment workflow
├── .gitattributes         # Git LFS rules for large project artifacts
└── .gitignore             # Local and generated-file exclusions
~~~

### data_processing/

This directory contains the staged data workflow:

1. 01_data_acquisition/ — acquisition scripts, source manifests, intermediate data, and raw-data documentation.
2. 02_douyin_cleaning/ — Douyin import, cleaning, quality checks, and validation outputs.
3. 03_kugou_cleaning/ — KuGou import, coding, cleaning, reconstruction, and validation outputs.
4. 04_cross_platform_integration/ — harmonization and cross-platform integration functions and outputs.
5. 05_validation/ — package-level validation and reproducibility checks.
6. 06_us_data_cleaning/ — cleaning and preparation of the U.S. platform data.

The directory also contains run_all.R, project requirements, stage-specific READMEs, and the raw-data archive described below.

### data_submission/

This is the processed-data package used by the reports and by the formal Shiny submission. It contains the cleaned China platform tables, integrated platform tables, and processed U.S. tables. Large CSV and RDS files are stored through Git LFS.

### eda_submission/

This directory contains the EDA source files and rendering utilities, including the R Markdown/Quarto sources and rendered report files under analysis/. The four HTML files in eda_submission/analysis/ are synchronized byte-for-byte with the four public HTML entry points at the repository root. They are retained as formal submission artifacts; they are not alternative or newer versions.

### shiny_submission/

This is the only formal Shiny application directory. It contains:

- app.R — application entry point and page composition.
- R/ — data loading, reactive logic, plot construction, page modules, and audio-preview logic.
- data/ — processed data, cached dashboard data, and authorized preview assets.
- www/ — CSS, JavaScript, images, and navigation assets.
- requirements.R — package requirements.
- run_app.R — local launch helper.
- rsconnect/ — shinyapps.io deployment metadata.

Other historical Shiny directories are not part of the formal submission workflow. Future Shiny changes should be made in shiny_submission/ only.

## Raw acquisition data

The original acquisition exports are preserved in a single Git LFS archive:

- [data_processing/raw_acquisition_data.tar.gz](data_processing/raw_acquisition_data.tar.gz)

The archive contains the raw directories for the Douyin/KuGou acquisition workflow and the U.S. cleaning inputs. It can be restored from the repository root with:

~~~bash
tar -xzf data_processing/raw_acquisition_data.tar.gz -C data_processing
~~~

This recreates:

~~~text
data_processing/
├── 01_data_acquisition/data/raw/
└── 06_us_data_cleaning/data/raw/
~~~

The raw acquisition files are retained for reproducibility and auditability. They are not required by the deployed Shiny application at runtime; the application uses the processed data and cache included in shiny_submission/data/.

## Git LFS requirements

Large CSV, RDS, MP3, and raw-data archive files are tracked with Git LFS. Install Git LFS before cloning or downloading the complete repository:

~~~bash
git lfs install
git clone https://github.com/zhu060827/R-project.git
cd R-project
git lfs pull
~~~

When GitHub displays an LFS-managed file as a short pointer file in the web interface, the underlying large object is still stored in the Git LFS object store. A complete local checkout requires git lfs pull.

## Running the Shiny application locally

From the repository root, launch the formal application with:

~~~r
shiny::runApp("shiny_submission")
~~~

Or use the helper script from inside the application directory:

~~~r
setwd("shiny_submission")
source("requirements.R")
source("run_app.R")
~~~

The application first attempts to load cached dashboard data from shiny_submission/data/cache/dashboard_data.rds. If the cache is unavailable, it rebuilds the required in-memory tables from the processed CSV files shipped with the application package.

## Rendering the EDA reports

The EDA sources are stored in eda_submission/analysis/. The rendering helper expects to be run from eda_submission/:

~~~bash
cd eda_submission
Rscript scripts/render_eda.R
~~~

Rendered HTML files are written to eda_submission/analysis/. The public root-level HTML files should be updated whenever a new final rendering is accepted, so that the GitHub Pages entry points and the formal EDA package remain synchronized.

## Deploying the Shiny application

The deployed application is maintained separately from GitHub Pages. A deployment can be initiated from the repository root with rsconnect after account configuration is available:

~~~r
rsconnect::deployApp(
  appDir = "shiny_submission",
  appName = "musicpulse",
  account = "zhu060827",
  launch.browser = FALSE
)
~~~

The current deployed URL is <https://zhu060827.shinyapps.io/musicpulse/>.

## GitHub Pages deployment

.github/workflows/static.yml publishes the repository's static HTML entry points whenever main changes. The workflow is independent of the Shiny deployment. .gitattributes is required for the Git LFS rules, and .gitignore prevents local system files and application backup directories from being committed.

## Reproducibility and interpretation notes

- Observed platform dates describe the archived sample and should not be interpreted as official release dates or causal diffusion dates.
- Source ranking and position systems are not necessarily equivalent across platforms.
- Platform and genre labels may be multi-label or researcher-defined, depending on the source table and analysis page.
- The public HTML reports are rendered artifacts; reproducible sources and supporting scripts remain in eda_submission/ and data_processing/.

## Project scope

The repository is organized as a formal submission and reproducibility package. It intentionally excludes unrelated experiments, duplicate root-level code trees, system files, and temporary backup directories. The canonical Shiny source is shiny_submission/, and the canonical public EDA entry points are the four root-level HTML files listed above.
