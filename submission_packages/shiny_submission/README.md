# MusicPulse Shiny Submission

四页 Shiny 交互应用：Overview、Music Features、Dynamics、China vs US。

## 运行

在当前目录运行：

```r
source("requirements.R")
source("run_app.R")
```

然后打开 `http://127.0.0.1:8765`。

## 数据

应用读取上一级提交包中的处理后数据：

```text
../data_submission/data/processed/
```

包括中国平台的四个 CSV 和美国数据的两个 CSV。应用启动时一次性读取数据，筛选和图表均基于内存中的数据运行。

## 目录

- `app.R`：应用入口与页面组合
- `R/`：数据读取、页面逻辑、图表和模块
- `www/`：页面样式、导航脚本和交互资源
- `data/music_preview_research/`：音乐预览所需资源
- `requirements.R`：安装运行依赖
- `run_app.R`：本地启动脚本
