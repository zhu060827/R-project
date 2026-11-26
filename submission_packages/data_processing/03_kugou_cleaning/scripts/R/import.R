#' Load the daily KuGou chart table
#' @param path Path to kugou_eda_daily.csv.
#' @return A tibble with parsed dates.
#' @export
load_kugou_daily <- function(path = "03_kugou_cleaning/data/intermediate/kugou_eda_daily.csv") {
  if (!file.exists(path)) stop("File not found: ", path)
  x <- readr::read_csv(path, show_col_types = FALSE)
  x$chart_date <- as.Date(x$chart_date)
  x$peak_date <- as.Date(x$peak_date)
  x$release_date <- as.Date(x$release_date)
  x
}

#' Load the unique-track KuGou table
#' @param path Path to kugou_eda_track.csv.
#' @return A tibble with parsed dates.
#' @export
load_kugou_track <- function(path = "03_kugou_cleaning/data/intermediate/kugou_eda_track.csv") {
  if (!file.exists(path)) stop("File not found: ", path)
  x <- readr::read_csv(path, show_col_types = FALSE)
  x$peak_date <- as.Date(x$peak_date)
  x$release_date <- as.Date(x$release_date)
  x
}
