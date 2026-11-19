# Delivery dependency audit (2026-11-19)

Scope: current four-page app only. The working project was not edited or rolled back. No Conclusion code, historical backups, runtimes, installed libraries, logs, old evidence or intermediate EDA artifacts are included in the submission.

| Runtime input | Source rows | Columns | Grain / consumer |
|---|---:|---:|---|
| data/china/platform_song_coding.csv | 2,568 | 28 | normalized-title candidate; Pages 1/3/4 |
| data/china/platform_song_daily_panel.csv | 117,530 | 29 | supplied panel rows, same in-memory collapse to 69,350 unique candidate-days; Pages 1/3/4 |
| data/china/douyin_master_dataset.csv | 36,615 | 183 | native material/date, including prior recovered metadata; Pages 2/3 |
| data/china/kugou_analysis_dataset.csv | 73,000 | 53 | native record/date; Pages 2/3 |
| data/us/coding_clean.csv | 2,028 | 15 | reference track coding/group membership; Page 4 |
| data/us/daily_clean.csv | 49,640 | 12 | 68 paired groups x 730 dates; Page 4 |
| data/music_preview_research/page1_audio_previews.csv | 95 | retained | independent audio readiness/permission/hash mapping |
| data/music_preview_research/page3_kugou_links.csv | 95 | retained | independent official-link/native identity mapping |

The six CSVs are byte-identical source copies. The two runtime registries and 30 MP3s are also unchanged. All runtime resource paths are internal to this delivery root; source/provenance strings retained inside CSVs are not read as external dependencies.

Code adaptations: root/library configuration; two CSV-root replacements; direct-only dashboard loader; removal of uncalled legacy Page 2/3 loaders; Page 4 uses supplied shared tables instead of legacy fallback reads; explicit portable run_app.R. app.R only receives UI/server responsibility comments. Existing plots, styles, events, category mappings, weights and metric definitions are retained.

CSS/JavaScript and vinyl artwork are copied unchanged. R/modules are kept flat with descriptive page prefixes to preserve the mature module interfaces. UI builders and make_page*_server factories remain separate responsibilities; plotting and data helpers have their own files.

App startup reads the six CSVs and two registries once. Relative audio resources are hash/permission-checked when selected. User filters compute in memory. No RDS master file, recollection, new matching or statistics-definition change is introduced.

Excluded only from the delivery copy: original .Rlib/.cache, development reports/scripts, failed experiments, old migration modes, old screenshots/browser evidence, raw video originals, unneeded reference files and historical backups. No original project file was deleted.
