configure_musicpulse <- function(app_dir) {
  # The app and its supplied data folders live directly under the extracted
  # project directory (dabao/). Keep all data references relative to it.
  # This package is launched from submission_packages/shiny4_handoff;
  # project data remain in the repository's original data/ directory.
  project <- normalizePath(file.path(app_dir, '..', '..'), winslash = '/', mustWork = TRUE)
  .libPaths(c(file.path(app_dir, '.Rlib'), file.path(project, 'outputs/musicpulse_eda/.Rlib'), .libPaths()))
  cache <- file.path(app_dir, '.cache')
  dir.create(cache, showWarnings = FALSE)
  Sys.setenv(R_USER_CACHE_DIR = cache)
  project
}

load_page1_data <- function(project) {
  tables <- file.path(project, 'outputs/musicpulse_integrated_eda/tables')
  coding <- readr::read_csv(file.path(project, 'platform_song_coding.csv'),
    col_types = readr::cols(.default = readr::col_character()), na = c('', '\\N'), show_col_types = FALSE)
  daily <- readr::read_csv(file.path(tables, 'shared_candidate_daily_unique.csv'),
    col_types = readr::cols_only(cross_platform_song_id = readr::col_character(), observation_date = readr::col_date(),
      douyin_observed = readr::col_integer(), kugou_observed = readr::col_integer(),
      douyin_rank = readr::col_double(), kugou_rank = readr::col_double()), na = '\\N', show_col_types = FALSE)
  candidates <- readr::read_csv(file.path(tables, 'shared_candidate_group_statistics.csv'),
    col_types = readr::cols_only(cross_platform_song_id = readr::col_character(), song_title = readr::col_character()),
    na = '\\N', show_col_types = FALSE)
  stopifnot(nrow(readr::problems(coding)) == 0L, nrow(readr::problems(daily)) == 0L,
    nrow(coding) == 2568L, nrow(candidates) == 95L, nrow(daily) == 69350L,
    !anyDuplicated(coding$cross_platform_song_id), !anyDuplicated(candidates$cross_platform_song_id),
    !anyDuplicated(daily[c('cross_platform_song_id', 'observation_date')]),
    setequal(daily$cross_platform_song_id, candidates$cross_platform_song_id),
    all(daily$douyin_observed %in% 0:1), all(daily$kugou_observed %in% 0:1))
  is_d <- stringr::str_detect(coding$platforms, stringr::fixed('douyin'))
  is_k <- stringr::str_detect(coding$platforms, stringr::fixed('kugou'))
  coverage <- c(douyin_only = sum(is_d & !is_k), kugou_only = sum(is_k & !is_d), shared = sum(is_d & is_k))
  stopifnot(identical(as.integer(coverage), c(400L, 2073L, 95L)),
    identical(candidates$song_title, coding$song_title[match(candidates$cross_platform_song_id, coding$cross_platform_song_id)]))
  bounds <- range(daily$observation_date)
  kpis <- c(song_candidates = nrow(coding), shared_candidates = nrow(candidates), calendar_days = as.integer(diff(bounds)) + 1L)
  stopifnot(kpis[['calendar_days']] == 730L)
  list(coding = coding, daily = daily, candidates = candidates, coverage = coverage, bounds = bounds, kpis = kpis,
    # Reviewed Phase 1 variable_dictionary and Phase 1/2 reports. No verified generation mapping is provided.
    douyin_position_label = 'Douyin Provided Position (unverified)',
    douyin_axis_label = 'Douyin Average Provided Position (unverified)')
}
