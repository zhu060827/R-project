args<-commandArgs(FALSE);script<-sub('^--file=','',args[grepl('^--file=',args)][1])
app<-normalizePath(file.path(dirname(script),'..'),winslash='/')
source(file.path(app,'R/data_loader.R'));project<-configure_musicpulse(app)
suppressPackageStartupMessages(library(dplyr))
source(file.path(app,'R/page2_data.R'));source(file.path(app,'R/page2_plots.R'))
data<-load_page2_data(project,app);out<-file.path(app,'evidence/page2_unified')
read<-function(f)readr::read_csv(file.path(out,f),show_col_types=FALSE)
rchecks<-read('UNIFIED_R_CHECKS.csv');kchecks<-read('KEYWORD_R_CHECKS.csv');browser<-read('KEYWORD_BROWSER_CHECKS.csv')
page1<-readr::read_csv(file.path(app,'evidence/page1_regression/TEST_RESULTS.csv'),show_col_types=FALSE)
all_selections<-read('ALL_KEYWORD_SELECTIONS.csv')
stopifnot(all(rchecks$passed),all(kchecks$passed),all(browser$passed),all(page1$passed),all_selections$failures==0)
before<-readRDS(file.path(out,'protected_before.rds'))
stopifnot(identical(before$hashes,vapply(names(before$hashes),function(p)digest::digest(file=p,algo='sha256'),character(1))))
genre<-read('unified_genre_statistics.csv');mood<-read('unified_mood_statistics.csv');coverage<-read('unified_coverage.csv')
mdtable<-function(x){
 clean<-function(v)gsub('|',' / ',as.character(v),fixed=TRUE)
 c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),apply(as.data.frame(x),1,function(r)paste0('| ',paste(clean(r),collapse=' | '),' |')))
}
stat_table<-function(x){
 d<-x[x$platform=='Douyin',];k<-x[x$platform=='Kugou',];k<-k[match(d$label,k$label),]
 tibble(Category=d$label,Douyin_Count=d$count,Douyin_Percentage=sprintf('%.2f%%',d$percentage),Kugou_Count=k$count,Kugou_Percentage=sprintf('%.2f%%',k$percentage))
}
report<-c('# MusicPulse Page 2 — 统一分类与词云定向修改','',
 sprintf('实际以 R %s 计算并运行 Shiny / Edge 验收。分类 R 检查 %d/%d；词云 R 检查 %d/%d；真实浏览器检查 %d/%d；原 Page 1 回归 %d/%d。另穷举 %d 种非空标签组合，未发现排布错误、重叠或边界溢出。',getRversion(),sum(rchecks$passed),nrow(rchecks),sum(kchecks$passed),nrow(kchecks),sum(browser$passed),nrow(browser),sum(page1$passed),nrow(page1),all_selections$tested_nonempty_selections),
 '', '## 变更范围','',
 '- 新增 `R/page2_category_mapping.R`：独立的团队映射与统一类别关键词字典；可供后续 R 分析复用。',
 '- 修改 `R/page2_data.R`：分析层映射、同原生 ID—统一类别去重、分类有效分母；词汇规范化、共享标签加权和 Top 18。',
 '- 修改 `R/page2_plots.R`：只替换 Genre/Mood 数据标签与必要的 Mood 左侧绘图区留白；词云采用三档字号和稳定的中部排布。`page2_duration_plot` 函数体逐字一致。',
 '- 修改 `R/page2_module.R`：左侧两个六类 Checkbox、上排图表在原卡片内显示六行、方法图注；Duration 的 UI 与统计均未改。',
 '- 新增当前版本验收脚本与本报告生成脚本，README 更新复现入口。`app.R`、全部 Page 1 文件、导航 JS、原 page2.css、全局日期控件、卡片尺寸与位置均未修改。',
 sprintf('- %d 个保护对象的 SHA-256 与修改前一致，含原始输入、EDA 结果、两个现有 Douyin master、Page 1、导航与布局文件。未改原 CSV / JSON，不重采或重匹配，不开发 Page 3/4。',length(before$hashes)),
 '', '## 映射规则与实际覆盖','',
 '严格采用附件及后续补充：`Rock → Rock`、`Folk Pop → Pop`、`Cute → Playful / Fun`。当前原始数据的 41 个不同 Genre、15 个不同 Mood 均已映射；未映射标签为 0。未知标签不自动归入 Other；本次没有触发未知标签排除。',
 '原附件未给完显示顺序，当前按后续完整映射中统一类别首次出现顺序固定，所有日期和高亮状态均不重排。',
 '', '### Genre 全部映射','',mdtable(tibble(Source_Genre=names(data$mapping$genre_map),Unified_Genre=unname(data$mapping$genre_map))),
 '', '### Mood 全部映射','',mdtable(tibble(Source_Mood=names(data$mapping$mood_map),Unified_Mood=unname(data$mapping$mood_map))),
 '', '## 真实统计：默认全局窗口 2024-11-14—2026-11-13','',
 '继续读取当前 Shiny 原输入：handoff 的 Douyin master 与 Kugou daily / track，不切换或重写数据集。所选窗口内按每平台原生 ID 选择最后一次实际观察；这个既有选择规则未改。默认窗口观察单位为 526 个 Douyin 音频素材、2,635 个 Kugou track，不是共同录音样本。',
 '每单位的所有原标签先映射，再对 unit_id + unified_label 去重；不同统一类别允许同一单位重复归属。分母是有至少一个有效统一标签的不同原生单位，不是日度重复行，也不是全部 826 个 Douyin 素材。Genre 分母为 Douyin 450 / Kugou 2,635；Mood 分母为 Douyin 470 / Kugou 2,635。',
 '', '### Music Genre Distribution','',mdtable(stat_table(genre)),
 '', '### Music Mood Heatmap','',mdtable(stat_table(mood)),
 '', '### 分类覆盖与缺失','',mdtable(coverage),
 '', '多标签占比总和可超过 100%。Pop、Chinese Pop 等落到同组只计一次；Funny 与 Cute 在 Douyin 的共同素材也不会叠加两遍。取消勾选只灰化，保留全部类别、顺序、计数及分母。Kugou 来源仍是待审核的供应方辅助/规则编码，团队归并不等于认证两平台原分类测量等价。',
 '', '## 词云规则','',
 '12 个统一类别各自人工配置 10 条关键词关联，共 120 条，基础权重 1—5；不是拼接原始细类别词表，也不是歌词 NLP 或真实词频。完整词典可在独立映射 R 文件的 `page2_team_keywords()` 检查。',
 '词语先小写、去首尾/连续空白，再使用明确的词形/拼写别名（例如 beats→beat、vocals→vocal、melodic→melody）。同一类别内归一后同词只保留最大基础权重，避免别名重复加分；类别之间按以下规则求和：',
 '`final_score = sum(base_weight) + 1.5 × (distinct_selected_label_count - 1)`。Genre 与 Mood 同名标签也按属性区分标签身份。',
 '按 final_score 降序、关键词字母序稳定排序，最多 Top 18；单类实际 10 词，不补造词。字号按当前排名分大（48—40）、中（32—24）、小（20—16）三个 SVG 层级，同分也按稳定名次保留层次，不按选择数量整体缩小。',
 '使用已安装的 systemfonts 测量 Segoe UI 字形宽度，自定义确定性横排，最重要的一行居中，其他词环绕在上下行；不随机布局，不旋转，不重叠，不靠丢词或缩小字号挤入。较拥挤的组合只压缩行间留白，维持 320 高度的 SVG 画布，字号不减。systemfonts 是现有项目依赖，本次未安装任何新包。',
 sprintf('对实际 12 个标签的全部 %d 种非空组合进行了 R 检查：最多 %d 词，最低字号 %.0f；最大 SVG 画布高度 %.2f。真实浏览器检查了单选 Genre、单选 Mood、部分多选、全选、全部取消及两种桌面尺寸。',all_selections$tested_nonempty_selections,all_selections$maximum_words,all_selections$minimum_font_size,all_selections$maximum_canvas_height),
 '全空时精确显示 `Select Genre or Mood labels to explore keywords.`；日期改变或导航切换保留词语、分数及位置。图注为 `Researcher-defined keyword associations, not lyric frequencies.`。',
 '', '## 保持不变与验收证据','',
 'Genre 选择不影响 Mood；Mood 选择不影响 Genre；两组选择只共同影响词云。两个 Duration 数据对象、直方图分箱与绘图函数均与修改前相同；默认窗口和 2025-03 窗口已逐值验证。Douyin 单位未核实的标记保留，没有换算分钟；Kugou 仍按此前方式换算。',
 '真实 Edge 在 1440×900、1920×1080检查全部卡片在视口内，词云无内部滚动与裁切；实际悬停验证 Unified Genre / Unified Mood 的两平台数量和百分比。日期变为 2025-03 时分类分母与 R 结果一致，高亮和词云不变。',
 'Page 1 复用全部 47 项真实浏览器回归，包括鼠标点气泡定位列表并更新详情、列表反向高亮、中英文搜索、排序、日期、空窗口与重置；全部通过。',
 '', '## 实际截图','',
 '- [完整 Page 2，全选，1440×900](evidence/page2_unified/keyword_all_1440x900.png)',
 '- [完整 Page 2，全选，1920×1080](evidence/page2_unified/keyword_all_1920x1080.png)',
 '- [仅 Pop](evidence/page2_unified/keyword_genre_1440x900.png)',
 '- [仅 Energetic / Positive](evidence/page2_unified/keyword_mood_1440x900.png)',
 '- [多个 Genre + Mood](evidence/page2_unified/keyword_partial_1440x900.png)',
 '- [全部清空](evidence/page2_unified/keyword_empty_1440x900.png)',
 '- [最拥挤组合，1440×900](evidence/page2_unified/keyword_dense_1440x900.png)',
 '- [最拥挤组合，1920×1080](evidence/page2_unified/keyword_dense_1920x1080.png)',
 '', '## 复现','',
 '启动命令不变：在项目根目录设置 README 中原有环境变量，再运行 bundled R 的 `outputs/musicpulse_shiny_prototype/run_app.R`。浏览器访问 http://127.0.0.1:8765/。',
 '当前版本测试：`tests/test_page2_unified.R`、`tests/test_page2_keyword_layout.R`、`tests/test_page2_keyword_browser.R`、`tests/test_page2_all_keyword_selections.R`，另运行 `tests/test_page1_with_page2.R`。原 `test_page2.R` 和原始细类字典构建脚本对应旧 V1，保留历史，不作为当前统一版验收入口。',
 '统计与验收明细在 evidence/page2_unified；全部来自实际 R/浏览器运行，未伪造图表或预设比例。未覆盖其他操作系统或浏览器；字体测量针对当前 Windows / Edge。','',
 '## 当前关键词字典','',mdtable(data$keywords),
 '', '## sessionInfo()','', '```text',capture.output(sessionInfo()),'```')
writeLines(report,file.path(app,'PAGE2_UNIFIED_REPORT.md'),useBytes=TRUE)
cat('Wrote report from actual statistics and acceptance results.\n')
