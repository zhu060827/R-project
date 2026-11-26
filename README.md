# MusicPulse / R-project

本仓库保留四个最终 EDA HTML 页面、完整的正式提交包，以及 Shiny 应用入口。

## EDA 页面

- [US EDA](US_Music_Dataset_EDA.html)
- [Douyin EDA](douyin_eda.html)
- [KuGou EDA](kugou_eda.html)
- [Integrated EDA](platform_combined_eda.html)

## Shiny 应用

[打开 MusicPulse Shiny 应用](https://zhu060827.shinyapps.io/musicpulse/)

## 正式提交包

四个正式目录直接位于仓库根目录：

- [`data_processing/`](data_processing/)：数据采集、清洗、整合和验证代码及其数据。
- [`data_submission/`](data_submission/)：报告和 Shiny 使用的处理后数据。
- [`eda_submission/`](eda_submission/)：四个 EDA 报告的源文件和渲染结果。
- [`shiny_submission/`](shiny_submission/)：唯一正式的 Shiny 源码、资源和部署配置。

处理后的大型 CSV、RDS、Shiny 音频和原始采集导出文件使用 Git LFS 管理；`.DS_Store`、备份目录和重复的根目录代码不纳入仓库。

原始采集数据以 [`data_processing/raw_acquisition_data.tar.gz`](data_processing/raw_acquisition_data.tar.gz) 归档上传。解压到 `data_processing/` 后，可恢复 `01_data_acquisition/data/raw/` 和 `06_us_data_cleaning/data/raw/` 两个原始目录。
