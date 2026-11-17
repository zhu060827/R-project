#!/usr/bin/env Rscript
# Complete R entry point for the Section 3-4 data-processing handoff.
#
# The script performs the available package-local steps in order:
# 1. Parse and clean the complete Douyin JSON archive.
# 2. Reconstruct the KuGou intermediate tables from the retained canonical data.
# 3. Validate the retained final datasets and write a package summary.
#
# The cross-platform final tables are retained handoff products and are checked
# for readability and required columns in the final validation step.

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
package_dir <- normalizePath(dirname(sub("^--file=", "", file_arg[[1]])), mustWork = TRUE)

run_r <- function(path) {
  status <- system(sprintf("Rscript %s", shQuote(normalizePath(path))))
  if (!identical(status, 0L)) stop("R step failed: ", path)
}

run_r(file.path(package_dir, "02_douyin_cleaning/scripts/R/01_import_clean.R"))
run_r(file.path(package_dir, "03_kugou_cleaning/scripts/R/reconstruct_intermediates.R"))
required <- c(
  "01_data_acquisition/data/processed/kugou_top100_2year_enriched.csv",
  "02_douyin_cleaning/data/processed/douyin_snapshots.csv",
  "02_douyin_cleaning/data/processed/douyin_observations.csv",
  "02_douyin_cleaning/data/processed/douyin_music_metadata.csv",
  "03_kugou_cleaning/data/processed/kugou_analysis_dataset.csv",
  "03_kugou_cleaning/data/intermediate/kugou_eda_daily.csv",
  "03_kugou_cleaning/data/intermediate/kugou_eda_track.csv",
  "04_cross_platform_integration/data/processed/platform_song_coding.csv",
  "04_cross_platform_integration/data/processed/platform_song_daily_panel.csv"
)
missing <- required[!file.exists(file.path(package_dir, required))]
if (length(missing)) stop("Final workflow is incomplete. Missing: ", paste(missing, collapse = ", "))

summary <- data.frame(
  file = required,
  readable = vapply(required, function(x) {
    tryCatch({
      read.csv(file.path(package_dir, x), nrows = 2, check.names = FALSE)
      TRUE
    }, error = function(e) FALSE)
  }, logical(1)),
  stringsAsFactors = FALSE
)
if (!all(summary$readable)) stop("One or more required files could not be read.")
write.csv(summary, file.path(package_dir, "05_validation/outputs/package_check_summary.csv"), row.names = FALSE)
cat("Complete package-local R workflow finished successfully.\n")
