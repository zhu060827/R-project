#' Load the canonical KuGou analysis table
#' @param path Path to the canonical KuGou CSV.
#' @return A tibble with parsed dates and numeric chart fields.
#' @export
load_kugou_analysis <- function(path = "03_kugou_cleaning/data/processed/kugou_analysis_dataset.csv") {
  x <- readr::read_csv(path, show_col_types = FALSE)
  date_cols <- intersect(c("chart_date", "peak_date", "release_date"), names(x))
  x[date_cols] <- lapply(x[date_cols], as.Date)
  x
}

#' Clean a KuGou daily chart table
#' @param data A KuGou daily chart table.
#' @return A cleaned tibble.
#' @export
clean_kugou_daily <- function(data) {
  required <- c("chart_date", "rank", "kugou_song_id")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) stop("Missing required KuGou columns: ", paste(missing, collapse = ", "))
  data |>
    dplyr::mutate(
      chart_date = as.Date(chart_date), kugou_song_id = as.character(kugou_song_id),
      rank = as.numeric(rank),
      pre_rank = if ("pre_rank" %in% names(data)) as.numeric(pre_rank) else NA_real_,
      peak_rank = if ("peak_rank" %in% names(data)) as.numeric(peak_rank) else NA_real_,
      time_on_chart = if ("time_on_chart" %in% names(data)) as.numeric(time_on_chart) else NA_real_,
      duration_minutes = if ("duration_ms" %in% names(data)) as.numeric(duration_ms) / 60000 else NA_real_,
      is_top10 = as.integer(!is.na(rank) & rank <= 10),
      is_top20 = as.integer(!is.na(rank) & rank <= 20),
      is_new_entry = as.integer(is.na(pre_rank) | pre_rank == 0),
      observation_year = as.integer(format(chart_date, "%Y")),
      observation_month = format(chart_date, "%Y-%m")
    ) |>
    dplyr::distinct(chart_date, kugou_song_id, .keep_all = TRUE)
}

#' Combine cleaned KuGou daily and track tables
#' @param daily Daily chart table.
#' @param track One-row-per-track metadata table.
#' @return A canonical KuGou analysis table.
#' @export
prepare_kugou_analysis <- function(daily, track) {
  if (!"kugou_song_id" %in% names(track)) stop("track must contain kugou_song_id")
  track_one <- dplyr::distinct(track, kugou_song_id, .keep_all = TRUE)
  clean_kugou_daily(daily) |>
    dplyr::select(-dplyr::any_of(setdiff(names(track_one), "kugou_song_id"))) |>
    dplyr::left_join(track_one, by = "kugou_song_id")
}
