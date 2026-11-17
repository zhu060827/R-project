#!/usr/bin/env Rscript
# Parse saved Douyin hot-music JSON samples and retain source dates.

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(dplyr))

`%||%` <- function(x, y) if (is.null(x)) y else x
parse_one <- function(path) {
  x <- fromJSON(path, simplifyVector = FALSE)
  rows <- x$data %||% x$result %||% x
  if (!is.list(rows)) return(tibble::tibble())
  tibble::tibble(source_file = basename(path), source_path = path,
                 record_count = length(rows))
}

args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args)) args[[1]] else "01_data_acquisition/data/raw/douyin_json"
output <- if (length(args) > 1) args[[2]] else "01_data_acquisition/data/intermediate/douyin_json_sample_inventory.csv"
files <- sort(list.files(input_dir, pattern = "hot-music\\.json$", full.names = TRUE, recursive = TRUE))
if (!length(files)) stop("No Douyin JSON files found: ", input_dir)
write.csv(bind_rows(lapply(files, parse_one)), output, row.names = FALSE)
cat("Indexed", length(files), "Douyin JSON samples.\n")
