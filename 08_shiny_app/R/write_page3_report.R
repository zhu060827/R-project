args<-commandArgs(FALSE);script<-sub('^--file=','',args[grepl('^--file=',args)][1]);app<-normalizePath(file.path(dirname(script),'..'),winslash='/')
source(file.path(app,'R/data_loader.R'));project<-configure_musicpulse(app)
suppressPackageStartupMessages({library(dplyr);library(tidyr)})
for(f in c('page1_logic.R','page2_data.R','page3_data.R','page3_plots.R'))source(file.path(app,'R',f))
out<-file.path(app,'evidence/page3');read<-function(f)readr::read_csv(file.path(out,f),show_col_types=FALSE)
rc<-read('DATA_CHECKS.csv');bc<-read('BROWSER_CHECKS.csv');p1<-read('page1_regression/TEST_RESULTS.csv');p2<-read('page2_regression/KEYWORD_BROWSER_CHECKS.csv')
stopifnot(all(rc$passed),all(bc$passed),all(p1$passed),all(p2$passed))
protected<-readRDS(file.path(out,'protected_before.rds'));stopifnot(identical(protected,vapply(names(protected),function(p)digest::digest(file=p,algo='sha256'),character(1))))
overview<-load_page1_data(project);features<-load_page2_data(project,app);data<-load_page3_data(project,overview,features)
e<-readRDS(file.path(out,'expected.rds'));full<-e$full;top<-e$top;actual<-top[!top$placeholder,]
counts<-actual%>%count(lead_direction,name='candidates')
directions<-full$stats%>%count(lead_direction,name='candidates')
membership<-bind_rows(lapply(c('Mood','Genre'),function(a){x<-dyn_scatter_data(full,a,if(a=='Mood')data$mood_order else data$genre_order);tibble(attribute=a,distinct_candidates=n_distinct(x$cross_platform_song_id),candidate_label_memberships=nrow(x))}))
example<-function(category,label=NULL,sort='union')dyn_top10(full,category,label,sort)%>%mutate(category=category,filter_label=if(is.null(label))'All'else label,sort_by=sort)
examples<-bind_rows(example('All Songs'),example('All Songs',sort='gap'),example('Genre','Rock'),example('Mood','Calm / Healing'))
readr::write_csv(examples,file.path(out,'top10_filter_examples.csv'))
mdtable<-function(x){clean<-function(v)gsub('|',' / ',gsub('[\r\n]+',' ',as.character(v)),fixed=TRUE);c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),apply(as.data.frame(x),1,function(r)paste0('| ',paste(clean(r),collapse=' | '),' |')))}
examples_md<-examples%>%transmute(Category=category,Label=filter_label,Sort=sort_by,Row=slot,Candidate=cross_platform_song_id,Title=ifelse(placeholder,'No eligible song',song_title),Union=union_days,Overlap=same_day_days,Gap=lead_lag_days)
report<-c('# MusicPulse Page 3 V2 — Popularity Dynamics & Cross-platform Diffusion','',
 sprintf('已实际使用 R %s 启动同一 Shiny 应用，并用真实 Edge 测试。Page 3 R %d/%d、浏览器 %d/%d；Page 1 回归 %d/%d、Page 2 回归 %d/%d 全部通过。',getRversion(),sum(rc$passed),nrow(rc),sum(bc$passed),nrow(bc),sum(p1$passed),nrow(p1),sum(p2$passed),nrow(p2)),
 '用户已确认没有可复用的队友 Page 3 源码，因此本页基于现有 MusicPulse 设计从零实现四模块，A 保持横向时序图，B 保持分类散点图并加入中位数标记。没有声称对照不存在的原型源码。','',
 '## 实现与文件','',
 '- 新增 `R/page3_data.R`：只读输入、唯一候选组日核对、窗口指标、原生 ID 分类关联、五种 Top 10 排序、月度分母及首次月份标记。',
 '- 新增 `R/page3_plots.R`：A 真实观测片段、B 分类散点/零线/中位数、C 成对月度色块和完整 Hover。',
 '- 新增 `R/page3_module.R`：A 三个控件、B 唯一模式切换器、共享选择状态、C 同序联动、D 总览/详情/返回。',
 '- 新增 `www/page3.css`、`www/page3.js`：仅作用 Page 3 的样式和月度色块鼠标/键盘联动。新增共享 `www/navigation.js` 支持三页切换。',
 '- 共享 `app.R` 仅加载新模块、挂接 Page 3 UI/server 与样式/路由，并将 Dynamics 导航启用；China vs US 仍禁用、保留 Coming soon。',
 '- Page 1/2 专属 R、CSS、JS、分类映射及数据均未改变；旧 page2.js 已保留原样，共享导航扩展放在新 navigation.js。旧 EDA 报告与原 CSV/JSON未覆盖。',
 sprintf('- 受保护的 %d 个既有输入/页面文件，构建前后 SHA-256 完全一致。回归使用原测试代码的包装器，仅适配新增导航、隐藏视图及单独证据目录，未改原测试与历史结果。',length(protected)),
 '- 验收入口：`tests/test_page3_data.R`、`tests/test_page3_browser.R`、`tests/test_page3_regressions.R --page1/--page2`。完整证据位于 `evidence/page3/`。','',
 '## 数据版本、粒度与时间口径','',
 '主分析仅用已存在的 95 个 shared-song candidates、69,350 个唯一候选组—日期，范围 2024-11-14—2026-11-13。原始 panel 有 117,530 行；重新按现成标记是否出现 1 核对去重结果，与既有唯一面板的两平台标记逐组日一致，不按重复行加权。没有重新匹配标题或重建原始数据。',
 '候选是 normalized-title grouping，不是已验证的同一录音。所有首次观察、日数、方向、中位数、Top 10 和月度密度都使用当前选定窗口，且图注明确 First observed within selected window。一端没有正观察时，日期差为 NA，不赋 0，不误称另一平台更晚。',
 '`lead_lag_days = first_kugou_date - first_douyin_date`：正值 Douyin earlier；负值 Kugou earlier；0 Same day。A/C/D 显示绝对领先天数并保留方向，B 横轴保留带符号值。',
 '总体日数是两平台正观察日期的并集；Same-day 是交集。Top 10 仅纳入窗口内至少一端有观察的候选。union/overlap/douyin/kugou 降序；gap 按绝对值降序且排除单平台 NA。所有同值先按 union 降序，再按候选 ID 升序。',
 '固定十行：不足十个候选时使用非交互浅灰占位，不拼入别类，不计入摘要分母。未观察不表示 Heat/User Count 为 0，本页不合成跨平台热度分数。','',
 '## 月度归档分母，特别是 2024-12-11','',
 'C 的密度 = 本月窗口内该候选平台正观察日期数 / 该平台本月窗口内可用归档日期数。边界月份按所选范围裁切；分母为 0 则密度 NA，不能当 0。真实可用归档日数来自完整来源日历，而不是仅看 95 个共享候选哪天出现。',
 'Page 3 沿用现成旧面板的观察标记，其未包含后来恢复的 2024-12-11 Douyin 记录。因此 Douyin 分母使用原 EDA 有效 snapshots，Kugou 分母使用已提供完整 daily 表实际日期。默认窗口 Douyin 729 日、Kugou 730 日；2024-12 为 30 / 31；2024-11 的边界为 17 / 17；2026-11 为 13 / 13。',
 '现有含恢复的 Douyin master 在该日已有有效记录，这里并非声称当天无数据。为不混用不同版本，本页没有将恢复元数据日历直接算成旧 panel 的机会日，更没有修改 Page 1 或旧面板。未来如需纳入恢复日，应单独审核更新 panel 后再换版本。',
 '归档日存在也不证明官方榜单完整或全天无遗漏；这里的分母只是当前来源版本可观察的归档日，不是完整平台总体。','',
 '## 分类关联规则','',
 sprintf('仅使用现成 native_candidate_mapping 中唯一原生 ID 链接，共 %d 条涉及这 95 个候选；排除 %d 条歧义链接，不取第一条、不按标题再做模糊 JOIN。',nrow(data$links),nrow(data$excluded_ambiguous_links)),
 '每个平台原生 ID 在当前窗口、且属于对应面板有效归档日期内，选择最后一次实际观察的元数据，复用 Page 2 统一映射。候选组标签为所有唯一关联原生 ID、两个平台有效标签的并集；缺失不硬填。同候选同一类只留一个成员关系，不取第一个标签。这个并集可能反映不同素材/供应方编码，而非经核实的完整歌曲属性。',
 'B 仅要求有效双平台窗口首次日期，并按当前 Mood/Genre 成员关系展开；不受 A Category、Label、Sort 影响，不局限 Top 10。分类中位数按该类不同候选的带符号日期差计算。多标签候选可以跨行，但同类同候选只有一个点；点的细小纵向错位按 ID 确定，不用随机数。',
 mdtable(membership),
 '', '## 四模块与当前真实结果','',
 'A：蓝/青绿实心横向段仅覆盖实际连续正观察日；日期有断点就断开，不画从首次到末次之间的虚假连续条。段占据观测日的日历格，不证明整日或连续播放。按用户反馈，选中只增加描边，不再淡化其余歌曲。',
 'B：六类 Mood/Genre 散点，0 为参照，深色短线为真实类别中位数。正右/负左方向与公式一致。点击非 Top 10 候选只更新 D，标记 Outside current Top 10，不强插 A/C。',
 'C：按用户参考图使用有间隔、圆角的左右双平台色块；左 Douyin、右 Kugou。中性表示有效归档下的 0，正密度用平台浅到深色连续映射，Hover 保留精确分子/分母/比例；未知归档的 NA 单独用虚线边框。颜色调整不改变观察值。',
 '完整窗口为 25 个自然月，强行塞进同一卡片会变成细线，因此 C 保留每月最小 42px，并只在卡片内部横向滚动；歌曲名与领先摘要固定。默认首屏可见前一段月份，全部其余月份均可滚动到达，已真实点击最右 2026-11 并验证滚动位置保留。十个行位在 1440×900、1920×1080 均完整可见。',
 'D/K 只标在真实较早平台的首次月份，Same day 两边用 =；同月内仍按准确日期决定方向，不按月份猜。单平台不标先后。D 在选择月份后显示该月两平台观察日/可用日及密度；Back 真正清除选中。',
 'D 默认摘要针对当前真实 Top 10：',mdtable(counts),
 sprintf('有效双平台候选 %d；绝对首次观察日期差中位数 %.1f 天；方向条分母为有两端日期的候选。单平台另外计数，不归 Same day。',sum(!is.na(actual$lead_lag_days)),median(actual$absolute_gap,na.rm=TRUE)),
 '全体 95 候选的窗口内方向分布：',mdtable(directions),
 '', '## Top 10 示例（真实计算）','',
 '以下含默认、时间差排序、少于十首的 Genre 与一个 Mood 条件；占位字段空缺不表示数值 0。完整可读 CSV 为 evidence/page3/top10_filter_examples.csv。',mdtable(examples_md),
 '', '## 实际鼠标与视觉验收','',
 '已用 CDP 真实鼠标完成：A 悬停/点击→C 高亮/D 详情；C 色块悬停/点击→选中 ID 与月份；最右月份点击/滚动位置保持；C 行名点击→选择歌曲且清月份；B 非 Top 10 点真实悬停/点击→D。Back 使用浏览器原按钮点击，筛选使用原 Selectize/日期组件 API 触发真实 Shiny 变更；这些控件并非逐项用物理鼠标展开。验证了筛选移除 A/C 选中时回总览，以及单平台/零候选/部分月窗口。没有直接伪造 selected_song_id 替代图表点选。',
 '空窗口 B 只保留坐标/类别与参考线，无伪造点或中位数；A/C 保留十个不可点击占位。D 月份详情在 1440×900 内全部字段和返回按钮可见，没有强迫页面整体滚动。',
 'C 的 Hover 在视口内，不受卡片裁切；完整标题可由 Hover 和 D 查看，轴/行名对长标题作省略。A/C 的 Top 10 ID 与顺序由同一 reactive 结果传入，窗口与筛选变化均经浏览器核对。',
 '', '## 最新截图','',
 '- [全页 1440×900：A 实心颜色与成对 C 色块](evidence/page3/page3_overview_1440x900.png)',
 '- [全页 1920×1080](evidence/page3/page3_overview_1920x1080.png)',
 '- [A 点击与 D 详情](evidence/page3/page3_selected_A_1440x900.png)',
 '- [B Genre 模式](evidence/page3/page3_B_genre_1440x900.png)',
 '- [B 非 Top 10 详情](evidence/page3/page3_B_outside_top10_1440x900.png)',
 '- [C Hover、密度与日期](evidence/page3/page3_matrix_hover_1440x900.png)',
 '- [C 月份选择与 D 月摘要](evidence/page3/page3_selected_month_1440x900.png)',
 '- [C 横向滚动到最后月份](evidence/page3/page3_matrix_final_months_1440x900.png)',
 '- [稀少 Genre / 灰色占位](evidence/page3/page3_sparse_genre_1440x900.png)',
 '- [Mood 筛选](evidence/page3/page3_mood_filter_1440x900.png)',
 '- [首次日期绝对差排序](evidence/page3/page3_gap_sort_1440x900.png)',
 '- [无合格双平台时间差窗口](evidence/page3/page3_empty_gap_window_1440x900.png)',
 '- [部分月份窗口](evidence/page3/page3_partial_march_1440x900.png)',
 '', '## 检查清单','',mdtable(rc),mdtable(bc),
 '', '## 运行与限制','',
 '启动方式保持原项目 bundled R：', '```powershell',
 '$env:TMPDIR=(Resolve-Path outputs/musicpulse_eda/.tmp).Path',"$env:LC_ALL='English_United States.utf8'","$env:LANG='English_United States.utf8'",
 '& outputs/musicpulse_eda/.runtime/R/bin/Rscript.exe --vanilla outputs/musicpulse_shiny_prototype/run_app.R','```',
 '访问 http://127.0.0.1:8765/，点击 Dynamics。依赖复用 Shiny、tidyverse、Plotly / htmlwidgets / htmltools；未安装新包。A/B 由 R Plotly 生成，C 由 R 生成 HTML/CSS 色块表，以保留足够格宽和稳定 ID 交互；它们处在同一个 Shiny 应用。',
 '当前没有未完成的指定功能；未开发 Page 4。测试针对 Windows/Edge 与上述实际窗口、筛选及尺寸，没有声称覆盖所有浏览器和所有筛选组合。',
 '解释边界：标题候选不是同录音；平台分类来源仍不同且 Kugou 辅助编码待复核；首次观察有左截断和窗口边界效应；日度密度不证明音乐全天持续可见；旧面板版本缺档不等同平台当日无热门音乐。观察先后不能证明传播方向、带动效应或因果机制。','',
 '## sessionInfo()','', '```text',capture.output(sessionInfo()),'```')
writeLines(report,file.path(app,'PAGE3_V2_REPORT.md'),useBytes=TRUE)
cat('Wrote Page 3 V2 report from actual R and browser results.\n')
