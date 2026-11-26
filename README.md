# MusicPulse / R-project

本仓库按功能分为四个正式区域：

- `data_processing/`：数据采集、清洗、整合和验证脚本与审计结果。
- `data_submission/`：EDA 和 Shiny 使用的处理后数据。大型文件使用 Git LFS。
- `eda_submission/`：EDA 的 R Markdown/Quarto 源文件和 HTML 报告。
- `submission_packages/shiny_submission/`：唯一正式的 Shiny 源码、资源和部署版本。

## Shiny 应用

线上应用：[MusicPulse Shiny](https://zhu060827.shinyapps.io/musicpulse/)

本地入口：`submission_packages/shiny_submission/run_app.R`

## EDA 页面

- [US EDA](US_Music_Dataset_EDA.html)
- [Douyin EDA](douyin_eda.html)
- [KuGou EDA](kugou_eda.html)
- [Integrated EDA](integrated_eda.html)

根目录中的 HTML 文件是 GitHub Pages 的公开入口，不是额外的源代码副本。后续 Shiny 修改只在 `submission_packages/shiny_submission/` 中进行。
