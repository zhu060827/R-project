# MusicPulse Shiny Submission

四页 Shiny 交互应用：Overview、Music Features、Dynamics、China vs US。

## 正式版本说明

`shiny_submission/` 是本项目唯一正式的 Shiny 源码、测试和部署目录。

项目中其他位置的 `shiny/` 和 `dabao/shiny/` 仅保留作历史开发参考，不应继续单独修改、测试或部署。所有后续修改都应在本目录完成，并从本目录启动应用或部署到 shinyapps.io。

## 运行

在当前目录运行：

```r
source("requirements.R")
source("run_app.R")
```

然后打开 `http://127.0.0.1:8765`。

## 数据

应用读取本包内的处理后数据：

```text
data/processed/
```

包括中国平台的四个 CSV 和美国数据的两个 CSV。应用启动时优先读取 `data/cache/dashboard_data.rds`；缓存不存在时，从处理后的 CSV 重建缓存。筛选和图表均基于内存中的数据运行。

## 目录

- `app.R`：应用入口与页面组合
- `R/`：数据读取、页面逻辑、图表和模块
- `www/`：页面样式、导航脚本和交互资源
- `data/music_preview_research/`：音乐预览所需资源
- `requirements.R`：安装运行依赖
- `run_app.R`：本地启动脚本

## 部署

部署时从项目根目录运行：

```r
rsconnect::deployApp(
  appDir = "shiny_submission",
  appName = "musicpulse",
  account = "zhu060827",
  launch.browser = FALSE
)
```

线上应用：<https://zhu060827.shinyapps.io/musicpulse/>
