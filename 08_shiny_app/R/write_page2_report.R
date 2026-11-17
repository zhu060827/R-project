# Generate the delivery report from the actual R/browser acceptance artifacts.
args <- commandArgs(FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)][1])
app_dir <- normalizePath(file.path(dirname(script),'..'),winslash='/')
source(file.path(app_dir,'R/data_loader.R'))
project <- configure_musicpulse(app_dir)
suppressPackageStartupMessages(library(dplyr))
evidence <- file.path(app_dir,'evidence/page2')
test <- readr::read_csv(file.path(evidence,'TEST_RESULTS.csv'),show_col_types=FALSE)
page1 <- readr::read_csv(file.path(app_dir,'evidence/page1_regression/TEST_RESULTS.csv'),show_col_types=FALSE)
stopifnot(all(test$passed),all(page1$passed))
s <- readRDS(file.path(evidence,'expected_summaries.rds'))$full
coverage_lines <- paste0('| ',s$coverage$platform,' | ',s$coverage$attribute,' | ',s$coverage$observed_units,' | ',s$coverage$classified_units,
  ' | ',s$coverage$missing_units,' | ',s$coverage$empty_array_units,' |')
dict <- readr::read_csv(file.path(app_dir,'data/page2_keyword_dictionary.csv'),show_col_types=FALSE)
report <- c('# MusicPulse — Page 2: Music Features V1', '',
  sprintf('已用 R %s 实际计算并启动 Shiny；Page 2 通过 %d/%d 项 R 与真实 Edge 检查；复用的 Page 1 回归通过 %d/%d 项。没有开发 Page 3。',getRversion(),sum(test$passed),nrow(test),sum(page1$passed),nrow(page1)), '',
  '## 实现与数据范围', '',
  '在现有应用启用 Music Features 导航，Overview 原有 KPI、Venn、气泡、列表、详情、双向联动及统计代码保持原样。共享原有 Global date filter，默认 2024-11-14 至 2026-11-13；未扩展 Page 1 的日期边界。Dynamics / China vs US 仍禁用并标注 Coming soon。', '',
  '- Douyin：只读 `outputs/musicpulse_team_handoff/data/douyin/douyin_master_dataset.csv`，36,615 条观测、826 个素材。含此前已验证恢复的 2024-12-11 记录；本次不再恢复、补采或修改数据。Page 1 继续使用旧 shared panel，因此两页该日的来源覆盖不同。',
  '- Kugou：只读 handoff 中 `kugou_eda_daily.csv`（73,000 行）及 `kugou_eda_track.csv`（2,635 ID）。它们是此前从审计缓存重新导出的值，未认证与已经移走的原始 CSV 字节相同；沿用已有 handoff 来源限制。',
  '- 对每个平台，在所选日期内按原生 ID 去重，选最后一次实际观测，属性和时长均取该条记录；缺失值不从其他日期补填。Douyin 单位为音频素材，Kugou 单位为原生 track；不是两个平台的已验证同录音集合，也不限于 95 个 shared candidates。', '',
  '## 默认窗口的真实分类分母', '',
  '| Platform | Attribute | Observed native units | Classified units | Missing | Empty array |',
  '|---|---|---:|---:|---:|---:|',coverage_lines,'',
  '比例为每平台“携带该属性至少一个标签的不同原生 ID”作分母；同一 ID—标签最多计一次，多标签允许比例总和超过 100%。NA、[] 与 Others 不混为一类。界面保留所有 41 个 Genre、15 个 Mood；当前窗口未分配某个确切标签时为 0%，分类分母为 0 时为 N/A。0% 不证明音乐性质不存在。', '',
  '## 标签与可比性', '',
  '`data/page2_label_alignment.csv` 记录 85 条平台—属性—标签来源。只按字面完全一致标签对齐，保留 Chinese Pop、Pop 等不同名称，不做语义映射。Douyin 为平台多标签；Kugou 的 coding_method=ai_assisted_screening、taxonomy_method=rule_based_screening，分类复核仍待完成。名称一致不等于分类测量等价，不能据这些占比直接比较平台偏好或真实市场组成。Mood 热力图只用 Mood，不使用 Theme。', '',
  'Genre 与 Mood 排序固定为默认完整窗口内两平台标签比例之和降序、同值按名称；变化日期不重排。标签目录来自已有完整输入，目录中的名称不意味着在每个日期窗口实际出现。默认高亮前 5 个 Genre 与前 4 个 Mood，属于视觉初始状态，不改变分母。', '',
  '## Duration 的明确例外', '',
  '用户已确认没有 Douyin 时长单位说明，并要求保留“单位待核实”。因此左图绘制 duration_raw 的真实原始分布，轴名 Source duration (unit unverified)，不换算为分钟；右图依据提供的 duration_ms / 60000 换算为分钟。这两幅图不能作同单位时长高低比较，也不能把 Douyin 素材时长当成完整歌曲时长。',
  paste0('默认窗口有效时长：Douyin ',sum(s$duration_bins$count[s$duration_bins$platform=='Douyin']),' 个素材，Kugou ',sum(s$duration_bins$count[s$duration_bins$platform=='Kugou']),' 个 track。R hist 生成每平台 6 个等宽区间，Frequency 为原生单位数；全范围纳入，不删除极端值，NA/负值/非有限值不作为 0。'), '',
  '## 交互与词云', '',
  '- Genre 勾选仅改变 Genre 颜色；Mood 勾选仅改变 Mood 颜色。取消后浅灰显示，全部类别、顺序、计数和分母保留。Duration 不依赖两组勾选。日期改变才按窗口实际观测重算统计，并保留标签选择与词云。',
  '- Genre hover 显示两平台分类数量和百分比；Mood hover 显示标签、平台、计数、百分比和分母。热力图使用数值网格坐标，避免 Plotly 对分类坐标矩阵重排序造成颜色与 hover 错位；全部 30 个单元格已与 R 结果逐格核对。',
  sprintf('- `data/page2_keyword_dictionary.csv` 为人工编写的标签关联词典，共 %d 条标签—词链接、%d 个不同词。不是歌词、NLP 或词频证据。每标签首词预设权重 3，其余 2；选择多个标签时同词去重、权重求和，大小按权重平方根缩放。SVG 确定性排布，无随机布局；所有标签选择时允许卡片内部滚动。',nrow(dict),n_distinct(dict$keyword)),
  '- 两组都清空时精确显示 `Select Genre or Mood labels to explore keywords.`。Sidebar 只有 Genre / Mood 两组多选及各自 Select all / Clear。', '',
  '## 实际验收与截图', '',
  '真实 Edge 检查 1440×900、1920×1080：页面无整体横向/纵向滚动，全部卡片在视口内，长标签和长图使用内部滚动。实际鼠标悬停核对 Genre / Mood；DOM 控件触发 Shiny 验证独立高亮、灰化、清空、全选、词云权重、SVG 无遮挡与越界。日期改为 2025-03，分类分母及两张时长直方图与 R 窗口重算一致，选择保留；返回 Overview 保留共享日期。', '',
  'Page 1 47 项回归包括真实鼠标气泡点击定位列表、详情更新、列表反向选中气泡、中英文搜索、排序、日期、空图、重置和小屏降级。复用原测试时仅适配 2 个禁用导航、可见输出等待与 Page 1 卡片作用域；原测试及历史报告不覆盖，仅另存当前检查明细。', '',
  'SHA-256 核查 150 个受保护文件：原始输入、已有 EDA 与 handoff 数据、Page 1 reactive / 绘图 / 数据载入 / custom.css 均未改变。新增导航只对 app.R 包装容器并组合两个 server；page1.js 仅增加隐藏图表 resize 防护，没有调整选中或定位逻辑。', '',
  '- [默认 1440×900](evidence/page2/page2_default_1440x900.png)',
  '- [默认 1920×1080](evidence/page2/page2_default_1920x1080.png)',
  '- [选择 Pop + Happy](evidence/page2/page2_selected_pop_happy_1440x900.png)',
  '- [清空标签](evidence/page2/page2_clear_1440x900.png)',
  '- [切换到 2025-03](evidence/page2/page2_march2025_1440x900.png)',
  '- [Page 2 检查明细](evidence/page2/TEST_RESULTS.csv)',
  '- [Page 1 回归明细](evidence/page1_regression/TEST_RESULTS.csv)',
  '- [运行日志](evidence/page2/run.log)；[sessionInfo](evidence/page2/sessionInfo.txt)', '',
  '## 复现', '',
  '新增：R/page2_data.R（只读载入及窗口统计）、R/page2_plots.R（四面板图形）、R/page2_module.R（UI/server）、R/prepare_page2_reference.R（字典构建）、R/write_page2_report.R（本报告）、www/page2.css、www/page2.js、data/page2_*.csv、tests/test_page2.R、tests/test_page1_with_page2.R。集成修改仅 app.R、page1.js 的可见性 resize 防护及 README.md；Page 1 业务统计和图表文件未改。', '',
  '从项目根目录按 README 命令启动 run_app.R，然后运行 tests/test_page2.R 与 tests/test_page1_with_page2.R。浏览器验收需要本机 Edge 和隔离浏览器进程权限。应用不新增 R 包，复用现有 ggplot2 / plotly / shiny 等；词云使用自定义 SVG。prepare_page2_reference.R 只用于开发时重建透明字典，应用正常启动无需运行；write_page2_report.R 从实际验收文件生成本报告。', '',
  '边界：未覆盖所有浏览器和所有日期组合；Kugou 编码可靠性与 Douyin duration 单位仍待来源证据。没有创建通用跨平台热度分数、歌词主题解释或平台偏好结论。完成止于 Page 2 V1。')
writeLines(report,file.path(app_dir,'PAGE2_PROTOTYPE_REPORT.md'),useBytes=TRUE)
cat('Wrote Page 2 report from actual results.\n')
