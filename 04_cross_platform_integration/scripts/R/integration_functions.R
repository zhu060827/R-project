#' Load platform-long Douyin and KuGou observations
#' @param douyin_path Path to the Douyin observation CSV.
#' @param kugou_path Path to the KuGou analysis CSV.
#' @return A platform-long tibble with harmonised fields.
#' @export
load_platform_observations <- function(
    douyin_path = "01_data_acquisition/data/source/douyin_source_samples/douyin_overlap_observations.csv",
    kugou_path = "03_kugou_cleaning/data/processed/kugou_analysis_dataset.csv") {
  dy <- readr::read_csv(douyin_path, show_col_types = FALSE)
  kg <- readr::read_csv(kugou_path, show_col_types = FALSE)
  dy_out <- tibble::tibble(
    platform = "douyin", observation_date = as.Date(dy$observation_date),
    platform_track_id = as.character(dy$platform_music_id), title = dy$title_raw,
    artist = dy$artist_raw, rank = dy$source_list_position, heat = dy$source_heat,
    user_count = dy$source_user_count, duration_seconds = dy$duration_raw,
    genre = dy$genre_harmonized, mood = dy$mood_grouped, pre_rank = NA_real_,
    peak_rank = NA_real_, time_on_chart = NA_real_
  )
  kg_out <- tibble::tibble(
    platform = "kugou", observation_date = as.Date(kg$chart_date),
    platform_track_id = as.character(kg$kugou_song_id), title = kg$track_name,
    artist = kg$artist_name, rank = kg$rank, heat = NA_real_, user_count = NA_real_,
    duration_seconds = as.numeric(kg$duration_ms) / 1000, genre = kg$genre_harmonized,
    mood = kg$mood_grouped, pre_rank = kg$pre_rank, peak_rank = kg$peak_rank,
    time_on_chart = kg$time_on_chart
  )
  dplyr::bind_rows(dy_out, kg_out) |>
    dplyr::mutate(
      title = as.character(title), artist = as.character(artist),
      duration_minutes = duration_seconds / 60,
      observation_year = as.integer(format(observation_date, "%Y")),
      observation_month = format(observation_date, "%Y-%m"),
      is_top10 = as.integer(!is.na(rank) & rank <= 10),
      is_top20 = as.integer(!is.na(rank) & rank <= 20),
      platform_record_id = paste0(toupper(substr(platform, 1, 2)), "_", platform_track_id)
    )
}

#' Normalize song titles using one shared rule across integration steps
#' @param x Character vector of song titles.
#' @return A normalized character vector.
#' @export
normalize_song_title <- function(x) {
  x <- tolower(trimws(ifelse(is.na(x), "", x)))
  x <- gsub("[（(][^）)]*[）)]", "", x)
  gsub("[^[:alnum:]\\x{4e00}-\\x{9fff}]", "", x, perl = TRUE)
}

#' Create title-level cross-platform coding
#' @param observations Output from load_platform_observations().
#' @return A coding table with a shared title ID.
#' @export
build_cross_platform_coding <- function(observations) {
  observations |>
    dplyr::mutate(song_title_key = normalize_song_title(title)) |>
    dplyr::filter(song_title_key != "") |>
    dplyr::group_by(song_title_key) |>
    dplyr::summarise(
      song_title = dplyr::first(title), platforms = paste(sort(unique(platform)), collapse = " | "),
      platform_count = dplyr::n_distinct(platform), record_count = dplyr::n_distinct(platform_record_id),
      first_observed_date = min(observation_date, na.rm = TRUE), last_observed_date = max(observation_date, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      cross_platform_song_id = sprintf("CN_SONG_%04d", dplyr::row_number()),
      both_platforms = as.integer(platform_count == 2), match_method = "normalized_title_only",
      match_status = ifelse(both_platforms == 1, "title_match_for_eda", "single_platform_track"),
      manual_review_required = 1L
    )
}

#' Build a cross-platform daily panel
#' @param observations Output from load_platform_observations().
#' @param coding Output from build_cross_platform_coding().
#' @return One row per title candidate and date.
#' @export
build_cross_platform_panel <- function(observations, coding) {
  obs <- observations |>
    dplyr::mutate(song_title_key = normalize_song_title(title)) |>
    dplyr::left_join(dplyr::select(coding, song_title_key, cross_platform_song_id), by = "song_title_key")
  dates <- tibble::tibble(observation_date = seq(min(obs$observation_date), max(obs$observation_date), by = "day"))
  keys <- dplyr::distinct(obs, cross_platform_song_id, song_title_key, title) |>
    dplyr::filter(!is.na(cross_platform_song_id))
  daily <- obs |>
    dplyr::group_by(cross_platform_song_id, observation_date) |>
    dplyr::summarise(
      douyin_rank = suppressWarnings(min(rank[platform == "douyin"], na.rm = TRUE)),
      kugou_rank = suppressWarnings(min(rank[platform == "kugou"], na.rm = TRUE)),
      douyin_observed = as.integer(any(platform == "douyin")),
      kugou_observed = as.integer(any(platform == "kugou")), .groups = "drop"
    ) |>
    dplyr::mutate(
      douyin_rank = ifelse(is.infinite(douyin_rank), NA, douyin_rank),
      kugou_rank = ifelse(is.infinite(kugou_rank), NA, kugou_rank)
    )
  keys |>
    dplyr::mutate(.join = 1L) |>
    dplyr::left_join(dplyr::mutate(dates, .join = 1L), by = ".join") |>
    dplyr::select(-.join) |>
    dplyr::left_join(daily, by = c("cross_platform_song_id", "observation_date")) |>
    dplyr::mutate(
      douyin_observed = tidyr::replace_na(douyin_observed, 0L),
      kugou_observed = tidyr::replace_na(kugou_observed, 0L),
      both_platforms_observed = as.integer(douyin_observed == 1 & kugou_observed == 1)
    )
}

#' Validate integrated observations
#' @param observations Platform-long observations.
#' @return A platform-level validation summary.
#' @export
validate_integrated_data <- function(observations) {
  observations |>
    dplyr::group_by(platform) |>
    dplyr::summarise(
      records = dplyr::n(), dates = dplyr::n_distinct(observation_date),
      tracks = dplyr::n_distinct(platform_track_id), missing_title = sum(is.na(title) | title == ""),
      duplicate_track_date = dplyr::n() - dplyr::n_distinct(paste(observation_date, platform_track_id)),
      .groups = "drop"
    )
}
