# MusicPulse Final Submission Package

本目录是项目最终代码与数据提交包。四个子包各自承担不同职责，正式版本以本目录中的内容为准。

## 目录结构

```text
submission_packages/
├── data_processing/       数据采集、清洗、整合和验证脚本
├── data_submission/       EDA 与 Shiny 使用的处理后数据
├── eda_submission/        EDA 源文件和 HTML 结果
├── shiny_submission/      唯一正式的 Shiny 源码、资源和部署包
└── final_materials/       最终报告、文献综述、设计说明、幻灯片和反思材料
```

## 正式版本规则

- 所有 Shiny 修改、测试和部署只使用 `shiny_submission/`。
- 大型 CSV 必须保留在本地最终提交包中；GitHub 镜像可使用 Git LFS 或只保存源代码。
- `eda_submission/` 保存可重现源文件和可直接阅读的 HTML 报告。
- 原始采集数据保留在 `data_processing/`，不与展示层代码混合。
- `.DS_Store`、`.Rhistory` 和 `Rplots.pdf` 属于本地临时文件，不是项目成果。

## 推荐检查顺序

1. 在 `data_processing/` 运行数据处理和验证流程。
2. 在 `eda_submission/` 重新渲染 EDA 报告。
3. 在 `shiny_submission/` 运行 `requirements.R` 和 `run_app.R`。
4. 检查 `final_materials/` 中的最终报告、幻灯片和个人反思。

## Shiny 应用

本地启动：

```r
setwd("submission_packages/shiny_submission")
source("requirements.R")
source("run_app.R")
```

线上版本：<https://zhu060827.shinyapps.io/musicpulse/>