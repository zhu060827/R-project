#!/usr/bin/env Rscript
# Reconstruct KuGou intermediate tables from the retained canonical table.

if (!exists("package_dir", inherits = FALSE)) {
  args <- commandArgs(trailingOnly = FALSE)
  script_arg <- grep("^--file=", args, value = TRUE)
  script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[[1]]) else ""
  package_dir <- normalizePath(file.path(dirname(script_path), "../.."), mustWork = FALSE)
  if (!dir.exists(file.path(package_dir, "03_kugou_cleaning"))) package_dir <- normalizePath(getwd())
}
input_path <- file.path(package_dir, "03_kugou_cleaning/data/processed/kugou_analysis_dataset.csv")
output_dir <- file.path(package_dir, "03_kugou_cleaning/data/intermediate")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
daily_path <- file.path(output_dir, "kugou_eda_daily.csv")
if (!file.exists(daily_path)) {
  write.csv(data, daily_path, row.names = FALSE, na = "")
}

data <- data[order(data$kugou_song_id, data$chart_date), ]
track_path <- file.path(output_dir, "kugou_eda_track.csv")
if (file.exists(track_path)) {
  track <- read.csv(track_path, stringsAsFactors = FALSE, check.names = FALSE)
} else {
  track <- data[!duplicated(data$kugou_song_id), , drop = FALSE]
  write.csv(track, track_path, row.names = FALSE, na = "")
}

coding_cols <- intersect(c(
  "kugou_song_id", "pop", "rock", "rnb_soul", "hiphop_rap_trap", "dance",
  "genre_evidence", "theme_evidence", "coding_method", "coding_confidence",
  "manual_review_required", "genre_category", "genre_harmonized",
  "mood_category", "mood_grouped", "taxonomy_source", "taxonomy_method",
  "taxonomy_review_required"
), names(track))
write.csv(track[coding_cols], file.path(output_dir, "kugou_manual_coding_sheet.csv"),
          row.names = FALSE, na = "")

cat(sprintf("daily=%d; tracks=%d; coding=%d\n", nrow(data), nrow(track), nrow(track)))
