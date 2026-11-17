#!/usr/bin/env Rscript
# Parse saved KuGou rank API responses into a daily observation table.

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(dplyr))

parse_one <- function(path) {
  x <- fromJSON(path, simplifyVector = FALSE)
  info <- x$data$info %||% list()
  if (!length(info)) return(tibble::tibble())
  tibble::tibble(
    chart_date = sub("^rank_song_([0-9-]+)_.*$", "\\1", basename(path)),
    rank = seq_along(info),
    kugou_song_id = vapply(info, function(z) as.character(z$audio_id %||% z$mixsongid %||% ""), character(1)),
    track_name = vapply(info, function(z) as.character(z$songname %||% NA_character_), character(1)),
    artist_name = vapply(info, function(z) {
      a <- z$authors %||% list()
      paste(vapply(a, function(y) as.character(y$author_name %||% ""), character(1)), collapse = ", ")
    }, character(1)),
    duration_ms = vapply(info, function(z) as.numeric(z$duration %||% NA_real_) * 1000, numeric(1)),
    source_file = basename(path)
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x
args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args)) args[[1]] else "01_data_acquisition/data/raw/kugou_api"
output <- if (length(args) > 1) args[[2]] else "01_data_acquisition/data/intermediate/kugou_api_daily_raw.csv"
files <- sort(list.files(input_dir, pattern = "^rank_song_.*\\.json$", full.names = TRUE))
if (!length(files)) stop("No KuGou rank-song JSON files found: ", input_dir)
result <- bind_rows(lapply(files, parse_one))
write.csv(result, output, row.names = FALSE, na = "")
cat("Parsed", nrow(result), "KuGou observations from", length(files), "JSON files.\n")
