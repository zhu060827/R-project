#!/usr/bin/env Rscript

options(width = 120)
root <- normalizePath(".", winslash = "/")
if (!file.exists(file.path(root, "analysis", "douyin_eda.Rmd"))) {
  stop("Run this script from submission_packages/eda_submission")
}

required <- c("rmarkdown", "knitr", "tidyverse", "lubridate", "jsonlite",
              "patchwork", "plotly", "ggrepel", "scales")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: ", paste(missing, collapse = ", "))
}

reports <- c("douyin_eda.Rmd", "kugou_eda.Rmd", "platform_combined_eda.Rmd")
for (report in reports) {
  message("Rendering ", report)
  rmarkdown::render(
    input = file.path("analysis", report),
    output_dir = file.path(root, "analysis"),
    quiet = TRUE,
    envir = new.env(parent = globalenv())
  )
}
message("EDA reports rendered successfully.")
