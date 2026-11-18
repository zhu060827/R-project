# EDA Data Access

The EDA source files use the following processed tables:

| Report | Required data |
|---|---|
| Douyin EDA | `data/processed/douyin_master_dataset.csv` |
| KuGou EDA | `data/processed/kugou_analysis_dataset.csv` |
| Integrated EDA | `data/processed/platform_song_coding.csv`, `data/processed/platform_song_daily_panel.csv`, and `data/audit/platform_combined_overlap_observations.csv` |

The full processed tables remain in the local project and in the data-processing submission package. They are not duplicated in this GitHub EDA source upload because the Douyin and KuGou tables exceed GitHub's recommended individual-file size limit. The HTML reports rendered from the local full project are retained in the local submission package; the uploaded GitHub folder contains the reproducible R Markdown source, render script, and data-access documentation.
