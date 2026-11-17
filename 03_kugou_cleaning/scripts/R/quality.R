#' Validate the daily KuGou chart table
#' @param data A daily KuGou table.
#' @return A tibble of validation checks.
#' @export
validate_kugou_daily <- function(data) {
  daily <- data |>
    dplyr::group_by(chart_date) |>
    dplyr::summarise(
      n_rows = dplyr::n(),
      n_ranks = dplyr::n_distinct(rank, na.rm = TRUE),
      missing_rank = sum(is.na(rank)),
      duplicate_rank = any(duplicated(rank)),
      .groups = "drop"
    )
  tibble::tibble(
    check = c("date_count", "missing_dates", "max_rows_per_date", "rank_range",
              "missing_rank", "duplicate_rank", "missing_track_id"),
    value = c(
      as.character(nrow(daily)),
      as.character(if (nrow(daily) > 1) any(diff(sort(daily$chart_date)) > 1) else FALSE),
      as.character(if (nrow(daily)) max(daily$n_rows) else 0),
      as.character(all(is.na(data$rank) | data$rank %in% 1:100)),
      as.character(sum(daily$missing_rank)),
      as.character(any(daily$duplicate_rank)),
      as.character(any(is.na(data$kugou_song_id) | data$kugou_song_id == ""))
    )
  )
}

#' Summarise unique KuGou tracks
#' @param data A unique-track KuGou table.
#' @return A tibble with one row per track summary.
#' @export
kugou_track_summary <- function(data) {
  duration_ms <- if ("duration_ms" %in% names(data)) {
    as.numeric(data$duration_ms)
  } else if ("duration_minutes" %in% names(data)) {
    as.numeric(data$duration_minutes) * 60000
  } else {
    rep(NA_real_, nrow(data))
  }
  data |>
    dplyr::mutate(.duration_ms_for_summary = duration_ms) |>
    dplyr::summarise(
      tracks = dplyr::n_distinct(kugou_song_id),
      median_peak_rank = median(peak_rank, na.rm = TRUE),
      median_time_on_chart = median(time_on_chart, na.rm = TRUE),
      median_duration_min = if (all(is.na(.duration_ms_for_summary))) NA_real_ else median(.duration_ms_for_summary, na.rm = TRUE) / 60000,
      lyrics_available = sum(!is.na(lyrics_status) & lyrics_status == "found"),
      .groups = "drop"
    )
}
