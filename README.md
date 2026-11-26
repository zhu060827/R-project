# MusicPulse / R-project

本仓库保留四个最终 EDA HTML 页面和一个 Shiny 应用入口。

## EDA 页面

- [US EDA](US_Music_Dataset_EDA.html)
- [Douyin EDA](douyin_eda.html)
- [KuGou EDA](kugou_eda.html)
- [Integrated EDA](integrated_eda.html)

## Shiny 应用

[打开 MusicPulse Shiny 应用](https://zhu060827.shinyapps.io/musicpulse/)

## 代码结构

- `data_processing/`：数据采集、清洗、整合和验证。
- `data_submission/`：EDA 和 Shiny 使用的处理后数据，大型文件使用 Git LFS。
- `eda_submission/`：EDA 源文件。
- `submission_packages/shiny_submission/`：唯一正式的 Shiny 源码、资源和部署版本。

除上述四个最终 HTML 外，仓库不再保留额外的 HTML 入口。