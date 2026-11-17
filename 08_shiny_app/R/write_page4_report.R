args<-commandArgs(FALSE);script<-sub('^--file=','',args[grepl('^--file=',args)][1]);app<-normalizePath(file.path(dirname(script),'..'),winslash='/')
source(file.path(app,'R/data_loader.R'));project<-configure_musicpulse(app)
suppressPackageStartupMessages({library(dplyr);library(tidyr)})
source(file.path(app,'R/page4_data.R'));source(file.path(app,'R/page4_plots.R'))
out<-file.path(app,'evidence/page4');d<-readRDS(file.path(out,'data.rds'));s<-readRDS(file.path(out,'expected.rds'))
before<-readRDS(file.path(out,'protected_before.rds'))
after<-vapply(names(before),function(p)digest::digest(file=p,algo='sha256'),character(1))
protected<-tibble(file=sub(paste0(project,'/'),'',names(before),fixed=TRUE),before_sha256=unname(before),after_sha256=unname(after),unchanged=unname(before)==unname(after))
readr::write_csv(protected,file.path(out,'PROTECTED_FILES.csv'));stopifnot(all(protected$unchanged))
files<-c('DATA_CHECKS.csv','BROWSER_CHECKS.csv','page1_regression/TEST_RESULTS.csv','page2_regression/KEYWORD_BROWSER_CHECKS.csv','page3_regression/BROWSER_CHECKS.csv')
# The prior keyword suite names its result file; discover within the new destination only.
if(!file.exists(file.path(out,files[4])))files[4]<-file.path('page2_regression',basename(list.files(file.path(out,'page2_regression'),pattern='.*CHECKS.*csv$',full.names=TRUE)[1]))
checks<-bind_rows(lapply(files,function(f){a<-readr::read_csv(file.path(out,f),show_col_types=FALSE);stopifnot(all(a$passed));tibble(suite=f,checks=nrow(a),passed=sum(a$passed))}))
readr::write_csv(checks,file.path(out,'VALIDATION_SUMMARY.csv'))
mapping<-bind_rows(tibble(market='China',source_field='genre_harmonized',source_value=cmp_genres,unified_genre=cmp_genres,rule='identity; semicolon labels retained; one candidate per distinct label',priority=NA_integer_),
 tibble(market='United States',source_field=c('pop','rock','rnb_soul','hiphop_rap_trap','dance','Other'),source_value='1',unified_genre=cmp_genres,rule='first positive flag by this priority, then first source row within group_id',priority=1:6))
readr::write_csv(mapping,file.path(out,'genre_mapping.csv'))
coverage<-tibble(market=cmp_countries,paired_candidates=s$countries$n,paired_missing_genre=s$countries$unclassified,
 paired_genre_conflicts=vapply(cmp_countries,function(m)sum(d$events$genre_conflict[d$events$country==m],na.rm=TRUE),integer(1)),
 conflict_definition=c('supplied China genre_platform_conflict; cross-platform coding flag','multiple priority labels across source rows within US group_id'))
readr::write_csv(coverage,file.path(out,'genre_coverage.csv'))
unknown<-d$audit$us_unknown_flag_rows;readr::write_csv(unknown,file.path(out,'us_unencoded_source_rows.csv'))
catalog<-tibble(source_file=c('data/processed/platform_song_coding.csv','data/processed/platform_song_daily_panel.csv','data/reference/us_platform_clean/data_clean/coding_clean.csv','data/reference/us_platform_clean/data_clean/daily_clean.csv'),
 rows=c(d$audit$china_coding_rows,d$audit$china_panel_rows,d$audit$us_coding_rows,d$audit$us_daily_rows))
readr::write_csv(catalog,file.path(out,'source_catalog.csv'))
rows<-function(x)apply(as.data.frame(x),1,function(v)paste0('| ',paste(v,collapse=' | '),' |'))
market_table<-s$countries%>%transmute(Market=country,n,`Short-video first`=paste0(short,' (',cmp_pct(short_share),')'),`Streaming first`=paste0(stream,' (',cmp_pct(stream_share),')'),`Same day`=paste0(same,' (',cmp_pct(same_share),')'))
genre_table<-s$genre%>%transmute(Market=country,Genre=genre,n,`Short-video first`=short,`Streaming first`=stream,`Same day`=same,`Net Priority (pp)`=sprintf('%+.1f',net_priority),`Small sample`=ifelse(small_sample,'yes',''))
report<-c('# MusicPulse — Page 4 整合与视觉验收', '',
 'Page 4 已接入现有四页 Shiny 应用，没有使用 iframe、替代数据、重新匹配或采集。数据计算由项目 R 4.6.2 实际执行；Plotly 负责浏览器交互。', '',
 '## 1. 修改范围与整合方式', '',
 '- 修改 `app.R`：加载 Page 4 数据、UI、server，启用第四个导航按钮，新增仅 Page 4 可见的相对窗口提示。原 Page 1–3 UI/server 调用和 Global Date Filter 数值、范围与逻辑保留。',
 '- 修改 `www/navigation.js`：增加第四页显隐和 `is-compare` 状态；离开 Page 4 恢复原品牌副标题与全局日期控件。',
 '- 新增 `R/page4_data.R`：只读四份 handoff CSV，显式保护字符串 ID，复用首次日期、正负方向、Genre、相对月 cohort 与筛选计算。候选 ID 分别加 `CN::`、`US::`，两国之间不匹配歌曲。',
 '- 新增 `R/page4_plots.R`、`R/page4_module.R`：四图和 KPI 使用同一个筛选 reactive / summary，使用已有 Shiny/Plotly 组件。重写绘图层以控制轴、Hover、空数据及标签；未改原分析数据。',
 '- 新增 `www/page4.css`、`www/page4.js`：仅作用于 Page 4 的样式与验收状态消息。复用当前背景、system-ui、卡片边框/圆角、蓝色 #537F94、青绿色 #4F8985、控件外观与横屏排布；无独立导航或重复站点标题。',
 '- 新增 `tests/test_page4_data.R`、`tests/test_page4_browser.R`、`tests/test_page4_regressions.R`、本报告生成脚本；更新 README。所有新证据仅写入 `evidence/page4/`。',
 sprintf('- SHA-256 核对：%d 份既有输入、EDA/交接资料及 Page 1–3 专属代码文件全部保持原样，明细见 [PROTECTED_FILES.csv](evidence/page4/PROTECTED_FILES.csv)。共享 app.R/navigation.js 为本次必要接入点；其修改前副本也已保留。',nrow(protected)), '',
 '## 2. 真实输入、复用及兼容性', '',
 '队友完整原型保留在 `../shiny4_handoff/shiny4_handoff/app.R`，四份输入均来自该文件夹的 data 子目录：', '',
 '| 文件（相对于 handoff） | 实际行数 |','|---|---:|',rows(catalog), '',
 '中国原面板虽有重复组日记录，但本页沿用按真实观察标记取最早日期，重复行不改变 min；其唯一候选组—日期数为 69,350。美国每日表唯一键为 group_id + date；以非缺失 best_rank 识别观察，与队友原逻辑一致。未把占位日期计为歌曲观察。', '',
 '163 个 paired candidate 的两个首次日期、lead_days、cohort_month、Genre 均与运行队友原数据处理代码生成的参考对象逐条一致。原始首日期在全样本内计算一次；过滤不会重新寻找窗口内首日期。保留 A 的三方向构成、B 的 winner 月份分布、C 的真实间隔分布；D 的新净领先值由同一组真实计数推导。', '',
 '依赖全部使用现有项目包，无新增安装：shiny、bslib、dplyr、tidyr、readr、lubridate、plotly、htmltools；测试另用已安装的 chromote/jsonlite/digest。实际版本与系统信息见 [sessionInfo.txt](evidence/page4/sessionInfo.txt)。显式列类型读取避免了队友原型对不使用字段的自动类型推断警告。', '',
 '## 3. 基准样本与六类 Genre', '',
 '| Market | n | Short-video first | Streaming first | Same day |','|---|---:|---:|---:|---:|',rows(market_table), '',
 '这里是各市场自身的共享候选，不是中国与美国之间的同一录音匹配；中国仍为标准化标题 shared-song candidates。样本比例不能外推全市场。', '',
 '有效映射见 [genre_mapping.csv](evidence/page4/genre_mapping.csv)，缺失与冲突见 [genre_coverage.csv](evidence/page4/genre_coverage.csv)：', '',
 '- 中国：直接保留 handoff 的 genre_harmonized 六类及完整分号多标签。一个候选在同一 Genre 中仅计一次；不同标签允许重叠。不是改用 Page 2 的另一套元数据代表规则。',
 sprintf('- 中国 paired 样本中 %d 组带有原文件 genre_platform_conflict 标记；这是中国平台间分类标记，与美国下述组内来源行冲突的定义不同，不能直接比较两个冲突率。原 harmonized 标签仍按交接结果保留。',coverage$paired_genre_conflicts[1]),
 '- 美国：复用原优先级 `pop → rock → rnb_soul → hiphop_rap_trap → dance → Other` 对应 `Pop → Rock → R&B / Soul → Hip Hop / Rap → Dance / Electronic → Other`；一个 group_id 取原文件第一行的归类。该规则并非对多标签的完整保留，文件行次序和优先级会影响结果，不能声称两国分类测量完全相同。',
 sprintf('- 美国全部 %d 条 coding 中 %d 条为 multi-hot；配对样本相关的 %d 行中有 %d 条 multi-hot，%d 个配对组存在按优先级归类后仍不一致的来源行。保留原代表规则并输出 [us_genre_rule_audit.csv](evidence/page4/us_genre_rule_audit.csv)，未静默改成并集或重新匹配。',d$audit$us_coding_rows,d$audit$us_multihot_rows,d$audit$us_paired_coding_rows,d$audit$us_paired_multihot_rows,sum(d$events$genre_conflict[d$events$country=='United States'])),
 sprintf('- 中国完整 coding 中 %d 组 Genre 缺失；美国有 %d 条全零/未编码来源行，原型将其默认归 Other，本版保留为未知。这些未编码行均不在 paired 样本，因此没有改变 163 个有效候选或任何显示统计。当前配对样本中国/美国缺失 Genre 均为 0，没有强行映射未知类别。',d$audit$china_coding_missing_genre,nrow(unknown)),
 '- Genre 多选沿用 OR 条件；C/D 随后展开被选中候选的全部真实标签，因此可能仍出现其他标签。这是队友原筛选含义，不能把各 Genre 的 n 相加当作独立歌曲总数。', '',
 '## 4. 窗口与四图口径', '',
 '中国：2024-11-14 至 2026-11-13；美国：2020-06-01 至 2022-05-31。它们是不同历史窗口，不是同期市场比较，也不因文件截止日期就保证当天已完整采集。', '',
 '`relative month = floor(interval(market_start, first_date) / one calendar month) + 1`；`cohort_month = max(short_month, stream_month)`。Slider 筛选的是双方首次观察都已发生时所在的相对月；较早一方首日期可能早于选中月份区间。中国按每月 14 日切月，美国按每月 1 日切月。',
 '修正的仅是原型 date_window 的显示偏差：原型使用 floor_date(start, month)，会将中国全窗口末日误标为 2026-10-31；现在显示 2026-11-13，实际 cohort 及筛选结果完全不变。Page 4 隐藏中国专用 Global Date Filter，使用自己的 Relative observation window；返回前三页恢复原日期值，没有年份强行对齐。', '',
 '**A — Which Platform Appears First?** 当前筛选子集内按国家统计三方向，各国 denominator 为该国全部有效 paired candidates，包含 Same day；同长度 100% 条、方向统一配色、国家 n、内部百分比与 Hover。已选 Short-video first 时自然显示该条件子集 100%，页面明确标注 current filtered subset。', '',
 '**B — Distribution of First Observations by Calendar Month.** 沿用原型：先排除 Same day，再取两平台首日期中较早者的自然月份及其 winner platform；按国家、平台、月份计数。`share = 本国该平台该月份 winner 数 / 本国当前筛选全部非 Same day 候选数`。默认中国 denominator=82，美国=58；不是当月内部领先概率，也不是两平台各自全部首日期的双重计数。跨年按 Jan–Dec 合并。补全月份的 0 仅表示该事件计数为 0；denominator=0 时为 NA/No data，不把未观察歌曲补成热度零。', '',
 '**C — Timing Difference by Genre.** 两国同一定义 `lead_days = streaming_first_date − short_video_first_date`：正值短视频较早、负值流媒体较早、0 同日。保留真实极值；n < 5 或无变异时只显示观测点和中位数，不制造 KDE 小提琴。其余类别保留按 Genre 对齐的双国小提琴和中位数、零线。Hover 提供 n、median、Q1/Q3、range。', '',
 '**D — Genre Effects on Platform Priority.** 按国家 × Genre 的唯一候选计数：`n = short + stream + same`，`Net Priority = 100 × (short − stream) / n`，单位 pp。两个面板固定同序六类和 −100 至 +100 pp；零线为 0，正向右、负向左。Same day 留在 denominator；0 pp 可由两方向相等产生，不等于全为同日。n=0 不画方向条并显示 No data，n<5 降透明度并在 Hover 提醒；有效净值为0显示中央菱形。数值与 n 置于卡片范围内，完整 Hover 保留三方向数量、比例与净值。', '',
 '| Market | Genre | n | Short-video first | Streaming first | Same day | Net Priority (pp) | Small sample |',
 '|---|---|---:|---:|---:|---:|---:|---|',rows(genre_table), '',
 '## 5. 实际运行验收', '',
 '| Suite | 检查数 | 通过 |','|---|---:|---:|',rows(checks), '',
 'R 检查覆盖原型 163 条结果逐项一致、两市场 ID、方向、同日、分母、D 公式、六类顺序、三种 Dataset × 四种 First × 所有单 Genre、24 个月份、OR 多选、真实 US 第24月空数据、同日零净值、真实小样本、NA/NaN/Inf 和 Plotly 构建。',
 '真实隔离 Edge + Chromote 验收覆盖 Dataset/Genre/First/Month 四种控件、四图与 KPI 同步、B/C/D Hover、空数据、日期隔离及导航往返。1440×900 与1920×1080 均无页面横向溢出或纵向滚动，默认侧栏全部可见，图例、标题、坐标与 D 标签无明显遮挡。Genre 多选较多时允许侧栏内部滚动，不扩大页面。',
 '也实际测试了一个国家有有效候选、另一个国家为空的组合；A/B 明确显示 No data，不向 Plotly 提交缺失比例点，不产生静默剔除警告。',
 'Page 1 的47项原有数据/浏览器测试、Page 2 的51项当前统一分类/词云浏览器测试、Page 3 的31项 A/B/C/D联动/Top10/过滤浏览器测试均通过。包装器只调整新导航已启用、隐藏页等待和新证据目录，不覆盖原测试源文件或历史证据；原测试中“Coming soon”检查名称是旧名称，当前实际断言为没有禁用导航。', '',
 '## 6. 截图', '',
 '- [Page 4 — 1440×900](evidence/page4/page4_1440x900.png)',
 '- [Page 4 — 1920×1080](evidence/page4/page4_1920x1080.png)',
 '- [A — 100% bars](evidence/page4/page4_chart_a.png) · [B — Calendar months](evidence/page4/page4_chart_b.png) · [C — Violin](evidence/page4/page4_chart_c.png) · [D — Diverging bars](evidence/page4/page4_chart_d.png)',
 '- [D 小样本 Hover](evidence/page4/page4_D_small_sample_hover.png) · [Genre 多选](evidence/page4/page4_multi_genre.png) · [相对月筛选](evidence/page4/page4_relative_months_6_12.png) · [Same day](evidence/page4/page4_same_day.png) · [No data](evidence/page4/page4_no_data.png)', '',
 '## 7. 复现与剩余限制', '',
 '从项目根目录执行 README 中项目 R 4.6.2 的启动命令，保持 http://127.0.0.1:8765 服务运行，再执行：', '',
 '```powershell',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/tests/test_page4_data.R',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/tests/test_page4_browser.R',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/tests/test_page4_regressions.R --page1',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/tests/test_page4_regressions.R --page2',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/tests/test_page4_regressions.R --page3',
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/R/write_page4_report.R',
 '```', '',
 '运行日志、sessionInfo、数值表和验收 CSV 均位于 evidence/page4。浏览器测试需要本机 Edge，使用隔离临时 profile，不读取个人浏览器会话。', '',
 'First observed 仅指归档中的首次观察，受窗口左截断、样本覆盖、来源缺失与平台观察/位置口径影响；不等于发行、首次流行、官方首次上榜或传播因果起点。未将 Douyin 未核实名次升级为官方排名，也未将中美 Genre 测量或平台原生指标认定为等价。D 使用按 Genre 条件构成的描述性净差，不是控制变量后的“类型效应”，标题中的 Effects 不应作因果解释。',
 '当前最小后续行动是由团队确认美国多标签优先级/首行代表规则是否继续作为研究定义；若改变，需单独的口径变更与敏感性分析，本次没有擅自替换。Page 1–3 继续使用自己的中国时间范围与既有代表规则，与 Page 4 的全样本首日期定义明确区分。')
writeLines(enc2utf8(report),file.path(app,'PAGE4_INTEGRATION_REPORT.md'),useBytes=TRUE)
packages<-c('shiny','bslib','dplyr','tidyr','readr','lubridate','plotly','ggplot2','htmltools','chromote','jsonlite','digest')
readr::write_csv(tibble(package=packages,version=vapply(packages,function(p)as.character(utils::packageVersion(p)),character(1))),file.path(out,'dependency_versions.csv'))
writeLines(capture.output(sessionInfo()),file.path(out,'report_sessionInfo.txt'))
cat('Protected:',nrow(protected),'unchanged; validations:',sum(checks$checks),'passed. Report generated.\n')
