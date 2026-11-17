# R-only final type, inventory-exception and metadata-history checks.
args_all <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args_all[grepl("^--file=", args_all)][1])
eda_dir <- normalizePath(file.path(dirname(script), ".."), winslash = "/")
.libPaths(c(file.path(eda_dir, ".Rlib"), .libPaths()))
suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(readr); library(purrr); library(jsonlite) })
core <- readRDS(file.path(eda_dir, "data", "douyin_core_tables.rds"))
types <- imap_dfr(core, function(table, name) tibble(table = name, field = names(table),
                                                  r_class = map_chr(table, ~ paste(class(.x), collapse = "|")),
                                                  missing_values = map_int(table, ~ sum(is.na(.x)))))
write_excel_csv(types, file.path(eda_dir, "reports", "r_types_and_missingness.csv"), na = "")
stopifnot(is.character(core$observations$douyin_music_id), is.character(core$observations$douyin_song_id),
          is.numeric(core$observations$heat_raw), is.numeric(core$observations$user_count_raw),
          inherits(core$snapshots$archive_date, "Date"), inherits(core$observations$response_time, "POSIXct"),
          attr(core$observations$response_time, "tzone") == "Asia/Shanghai", is.logical(core$snapshots$rank_verified))
manifest <- read_csv(file.path(eda_dir, "data", "file_manifest.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
bad <- manifest %>% filter(selected_for_core_tables != "TRUE")
changes <- read_csv(file.path(eda_dir, "data", "metadata_changes.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
history <- read_csv(file.path(eda_dir, "data", "metadata_history.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
stopifnot(nrow(history) == nrow(core$observations), all(changes$snapshot_id %in% core$snapshots$snapshot_id),
          all(changes$previous_snapshot_id %in% core$snapshots$snapshot_id), all(manifest$source_unchanged == "TRUE"))
exceptions <- if (nrow(bad)) pmap_chr(bad, function(...) {
  r <- list(...)
  paste0("- ", r$archive_date, "：`", r$source_file, "`，状态 `", r$parse_status,
         "`；原因 `", r$selection_reason, "`。未插补该日期的观测。")
}) else "没有未选用的候选文件。"
fields <- changes %>% count(field, name = "change_events", sort = TRUE)
field_lines <- pmap_chr(fields, ~ paste0("|", .x, "|", .y, "|"))
lines <- c("# R Phase 1: Type and Exception Validation", "",
           "Character IDs, numeric fields, Date values, Asia/Shanghai POSIXct values, and logical flags were checked directly in R. Complete field types and NA counts are recorded in r_types_and_missingness.csv.", "",
           "## Excluded files", "", exceptions, "", "## Attribute-change audit", "",
           "metadata_history has the same row count as the cleaned observations, and all before/after snapshot keys are valid. Attribute-change events are listed below; a URL change does not prove that lyric content changed.", "",
           "|Field|Change events|", "|---|---|", field_lines,
           "", "This file documents Phase 1 validation only. It does not provide music-distribution interpretation, formal visualization, or Shiny development.")
writeLines(enc2utf8(lines), file.path(eda_dir, "reports", "QUALITY_EXCEPTIONS.md"), useBytes = TRUE)
message("R typed-core and metadata-history checks passed; unselected candidate files: ", nrow(bad))
print(bad %>% select(archive_date, source_file, parse_status, selection_reason))
