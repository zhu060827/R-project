# MusicPulse Douyin EDA Phase 1. All parsing, cleaning, reshaping, checks and exports are R.
suppressPackageStartupMessages({
  args_all <- commandArgs(trailingOnly = FALSE)
  file_arg <- args_all[grepl("^--file=", args_all)]
  if (length(file_arg)) {
    eda_lib <- file.path(dirname(sub("^--file=", "", file_arg[1])), "..", ".Rlib")
    if (dir.exists(eda_lib)) .libPaths(c(normalizePath(eda_lib), .libPaths()))
  }
  library(tidyverse)
  library(jsonlite)
  library(lubridate)
  library(digest)
})

json_text <- function(x) {
  if (is.null(x)) return(NA_character_)
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null", digits = NA))
}
char_value <- function(x) if (is.character(x) && length(x) == 1L && !is.na(x)) x else NA_character_
id_value <- function(x) {
  value <- char_value(x)
  if (is.na(value) || !str_detect(value, "^[0-9]+$") || value == "0") NA_character_ else value
}
source_text <- function(x) {
  if (is.null(x)) NA_character_ else if (length(x) == 1L && is.atomic(x)) as.character(x) else json_text(x)
}
number_check <- function(x, integer_only = FALSE) {
  raw <- source_text(x)
  if (is.null(x) || identical(raw, "")) return(list(value = NA_real_, raw = raw, issue = NA_character_))
  n <- if (is.logical(x) || length(x) != 1L || !is.atomic(x)) NA_real_ else suppressWarnings(as.double(raw))
  issue <- if (!is.finite(n)) "invalid_or_nonfinite" else if (abs(n) >= 2^53) "unsafe_double_precision" else
    if (n < 0) "negative_source_value" else if (integer_only && n != floor(n)) "noninteger_count" else NA_character_
  list(value = if (is.na(issue)) n else NA_real_, raw = raw, issue = issue)
}
parse_extra <- function(x) {
  if (is.null(x) || identical(x, "")) return(list(value = list(), status = "missing", raw = source_text(x)))
  if (is.list(x)) return(list(value = x, status = "object", raw = json_text(x)))
  if (!is.character(x) || length(x) != 1L) return(list(value = list(), status = "invalid_type", raw = source_text(x)))
  result <- tryCatch(jsonlite::fromJSON(x, simplifyVector = FALSE, bigint_as_char = TRUE), error = function(e) e)
  if (inherits(result, "error")) return(list(value = list(), status = "parse_error", raw = x))
  if (!is.list(result) || !str_starts(str_trim(x), fixed("{"))) return(list(value = list(), status = "invalid_root", raw = x))
  list(value = result, status = "ok", raw = x)
}
tag_json <- function(x) {
  if (is.null(x)) return(NA_character_)
  # Explicit [] remains []; absent/null stays NA; all labels preserved.
  if (!length(x)) return("[]")
  as.character(toJSON(if (is.list(x)) x else as.list(x), auto_unbox = TRUE, null = "null", na = "null"))
}
response_clock <- function(raw) {
  n <- suppressWarnings(as.double(source_text(raw)))
  if (length(n) != 1L || !is.finite(n) || n <= 0) return(list(raw = source_text(raw), utc = NA_character_, bj = NA_character_, unit = "unknown"))
  unit <- if (n >= 1e11) "milliseconds" else "seconds"
  dt <- as_datetime(if (unit == "milliseconds") n / 1000 else n, tz = "UTC")
  list(raw = source_text(raw), utc = format(dt, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
       bj = format(with_tz(dt, "Asia/Shanghai"), "%Y-%m-%dT%H:%M:%S%z", tz = "Asia/Shanghai"), unit = unit)
}
path_date <- function(path) {
  parts <- rev(str_split(str_replace_all(path, "\\\\", "/"), "/", simplify = FALSE)[[1]])
  values <- str_extract(parts, "(?<![0-9])[0-9]{4}-[0-9]{2}-[0-9]{2}(?![0-9])")
  values <- values[!is.na(values)]
  valid <- suppressWarnings(as.Date(values, "%Y-%m-%d"))
  if (any(!is.na(valid))) as.character(valid[which(!is.na(valid))[1]]) else NA_character_
}
flag_join <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x)) paste(x, collapse = ";") else "none"
}

parse_observation <- function(item, position, snapshot_id, day, clock) {
  m <- item$music_info
  song <- if (is.list(m$song)) m$song else list()
  ex <- parse_extra(m$extra)
  tagging <- ex$value$music_tagging
  if (!is.list(tagging)) tagging <- list()
  heat <- number_check(item$heat)
  users <- number_check(m$user_count, TRUE)
  duration <- number_check(m$duration)
  title <- char_value(m$title)
  markers <- c("Cover", "Remix", "Sped Up", "Slowed", "剪辑版", "氛围版", "DJ", "纯音乐")
  versions <- markers[str_detect(coalesce(title, ""), regex(markers, ignore_case = TRUE))]
  mid <- id_value(m$id_str)
  sid <- id_value(song$id_str)
  flags <- c(if (is.na(mid)) "missing_or_invalid_material_id", if (is.na(sid)) "missing_or_invalid_song_id",
             if (is.na(title) || !nzchar(str_trim(title))) "missing_title",
             if (is.na(char_value(m$author)) || !nzchar(str_trim(char_value(m$author)))) "missing_author",
             if (ex$status %in% c("parse_error", "invalid_root", "invalid_type")) paste0("extra_", ex$status),
             if (!is.na(heat$issue)) paste0("heat_", heat$issue), if (!is.na(users$issue)) paste0("user_count_", users$issue),
             if (!is.na(duration$issue)) paste0("duration_", duration$issue), if (!is.na(duration$value) && duration$value == 0) "zero_duration")
  tibble(snapshot_id = snapshot_id, archive_date = as.Date(day), response_time = clock$bj,
         douyin_music_id = mid, douyin_song_id = sid, music_id_source_raw = source_text(m$id_str),
         song_id_source_raw = source_text(song$id_str), title_raw = title, author_raw = char_value(m$author),
         heat_raw = heat$value, user_count_raw = users$value, list_position = as.integer(position), duration_raw = duration$value,
         heat_source_text = heat$raw, user_count_source_text = users$raw, duration_source_text = duration$raw,
         heat_issue = heat$issue, user_count_issue = users$issue, duration_issue = duration$issue,
         album_raw = char_value(m$album), genre_raw = tag_json(tagging$Genres), mood_raw = tag_json(tagging$Moods),
         theme_tags_raw = tag_json(tagging$Themes), language_raw = tag_json(tagging$Languages),
         singing_versions_raw = tag_json(tagging$SingingVersions), aeds_raw = tag_json(tagging$AEDs),
         version_type_raw = as.character(toJSON(as.list(versions), auto_unbox = TRUE)), extra_raw = ex$raw,
         extra_parse_status = ex$status, aigc_clip_raw = if (is.logical(ex$value$aigc_clip) && length(ex$value$aigc_clip) == 1L) ex$value$aigc_clip else NA,
         music_label_id_raw = source_text(ex$value$music_label_id), peak_raw = source_text(ex$value$peak),
         loudness_raw = source_text(ex$value$loudness), is_original_sound = if (is.logical(m$is_original_sound) && length(m$is_original_sound) == 1L) m$is_original_sound else NA,
         lyric_url = char_value(m$lyric_url), group_id = NA_character_, observation_quality_flag = flag_join(flags))
}

read_snapshot <- function(path, day, relative) {
  hash <- digest(file = path, algo = "sha256")
  info <- file.info(path)
  manifest <- tibble(source_file = relative, archive_date = as.Date(day), file_size = as.double(info$size), sha256_before = hash,
                     parse_status = "unprocessed", parse_error = NA_character_, record_count = NA_integer_)
  result <- tryCatch({
    text <- readr::read_file(path, locale = locale(encoding = "UTF-8"))
    obj <- fromJSON(text, simplifyVector = FALSE, bigint_as_char = TRUE)
    if (!is.list(obj) || is.null(names(obj))) stop("invalid_root")
    if (is.null(obj$status_code)) stop("missing_status_code")
    if (!identical(as.character(obj$status_code), "0")) stop(paste0("source_status_", source_text(obj$status_code)))
    if (!is.list(obj$music_list) || !length(obj$music_list)) stop("empty_or_missing_music_list")
    if (!all(map_lgl(obj$music_list, ~ is.list(.x) && is.list(.x$music_info)))) stop("invalid_music_record_structure")
    clock <- response_clock(if (is.list(obj$extra)) obj$extra$now else NULL)
    snapshot_id <- paste0("dy_", day, "_", substr(hash, 1, 16))
    observations <- map2_dfr(obj$music_list, seq_along(obj$music_list), ~ parse_observation(.x, .y, snapshot_id, day, clock))
    response_same_day <- if (is.na(clock$bj)) NA else substr(clock$bj, 1, 10) == day
    snap <- tibble(snapshot_id = snapshot_id, archive_date = as.Date(day), response_time = clock$bj,
                   response_time_utc = clock$utc, response_time_raw = clock$raw, timestamp_unit = clock$unit,
                   source_release_date = char_value(obj$release_date), source_file = relative, source_sha256 = hash,
                   record_count = as.integer(length(obj$music_list)), fetch_status = "source_status_code_0",
                   is_complete = "unknown", rank_verified = FALSE, response_matches_archive = response_same_day,
                   chart_date = as.Date(NA), chart_period = "unknown", collected_at = NA_character_,
                   has_more_raw = source_text(obj$has_more), cursor_raw = source_text(obj$cursor),
                   source_status_code = source_text(obj$status_code), quality_flag = "pending")
    fields <- c("id_str", "title", "author", "album", "duration", "user_count", "song", "extra", "position", "music_chart_ranks", "is_original_sound", "lyric_url")
    schema <- map_dfr(fields, function(field) {
      values <- map(obj$music_list, ~ .x$music_info[[field]])
      tibble(archive_date = as.Date(day), year = year(as.Date(day)), field = paste0("music_info.", field),
             present_count = sum(map_lgl(values, ~ !is.null(.x))), record_count = length(values),
             type_signature = paste(sort(unique(map_chr(values, ~ if (is.null(.x)) "null" else class(.x)[1]))), collapse = "|"))
    })
    manifest$parse_status <- "ok"; manifest$record_count <- nrow(observations)
    list(manifest = manifest, snapshot = snap, observations = observations, schema = schema)
  }, error = function(e) {
    manifest$parse_status <- "invalid"; manifest$parse_error <- conditionMessage(e)
    list(manifest = manifest, snapshot = tibble(), observations = tibble(), schema = tibble())
  })
  result
}

write_data <- function(x, path) {
  printable <- x %>% mutate(across(where(~ inherits(.x, "POSIXct")), function(v) {
    zone <- attr(v, "tzone"); if (is.null(zone) || !length(zone)) zone <- "UTC"
    format(v, "%Y-%m-%dT%H:%M:%S%z", tz = zone[1])
  }))
  write_excel_csv(printable, path, na = "")
}

import_clean <- function(root, out, project = NULL, start = as.Date("2021-01-11"), end = as.Date("2026-11-13")) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  data_dir <- file.path(out, "data", "processed"); report_dir <- file.path(out, "validation")
  dir.create(data_dir, showWarnings = FALSE); dir.create(report_dir, showWarnings = FALSE)
  report_inputs <- character(0)
  prior <- tibble(source_file = character(), sha256_before = character())
  candidates <- list.files(root, pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
  candidates <- candidates[str_detect(basename(candidates), regex("hot[-_]music", ignore_case = TRUE))]
  relative <- substring(str_replace_all(candidates, "\\\\", "/"), nchar(root) + 2)
  inventory <- tibble(path = candidates, source_file = relative, date_text = map_chr(relative, path_date)) %>%
    mutate(archive_date = as.Date(date_text), in_requested_range = !is.na(archive_date) & archive_date >= start & archive_date <= end)
  write_data(inventory %>% select(-path), file.path(data_dir, "discovered_music_files.csv"))
  selected <- inventory %>% filter(in_requested_range) %>% arrange(archive_date, source_file)
  if (!nrow(selected)) stop("No matching files in requested range")
  message("R discovered ", nrow(selected), " candidate files in target interval; parsing all files.")
  parsed <- vector("list", nrow(selected))
  for (i in seq_len(nrow(selected))) {
    parsed[[i]] <- read_snapshot(selected$path[i], selected$date_text[i], selected$source_file[i])
    if (i %% 50L == 0L || i == nrow(selected)) message("Parsed ", i, "/", nrow(selected))
  }
  manifest <- map_dfr(parsed, "manifest") %>%
    group_by(archive_date) %>% mutate(valid_files_on_date = sum(parse_status == "ok")) %>% ungroup() %>%
    mutate(selected_for_core_tables = parse_status == "ok" & valid_files_on_date == 1L,
           selection_reason = case_when(parse_status != "ok" ~ parse_error,
                                        valid_files_on_date > 1L ~ "ambiguous_multiple_valid_files_on_date",
                                        TRUE ~ "unique_valid_file_on_date"))
  keep <- which(manifest$selected_for_core_tables)
  write_data(manifest, file.path(data_dir, "file_manifest.csv"))
  if (!length(keep)) stop("No unambiguous valid snapshots; inspect inventory")
  snapshots <- map_dfr(parsed[keep], "snapshot") %>%
    mutate(response_time = ymd_hms(response_time, tz = "Asia/Shanghai", quiet = TRUE),
           response_time_utc = ymd_hms(response_time_utc, tz = "UTC", quiet = TRUE)) %>% arrange(archive_date, response_time, snapshot_id)
  obs_raw <- map_dfr(parsed[keep], "observations") %>%
    mutate(response_time = ymd_hms(response_time, tz = "Asia/Shanghai", quiet = TRUE)) %>% arrange(archive_date, snapshot_id, list_position)
  schema <- map_dfr(parsed[keep], "schema")
  rm(parsed); invisible(gc())
  obs_raw <- obs_raw %>% group_by(snapshot_id, douyin_music_id) %>%
    mutate(id_count_in_snapshot = if_else(is.na(douyin_music_id), NA_integer_, n()),
           duplicate_music_id = !is.na(douyin_music_id) & n() > 1L) %>% ungroup() %>%
    mutate(quarantine_reason = case_when(is.na(douyin_music_id) ~ "missing_or_invalid_material_id",
                                         duplicate_music_id ~ "duplicate_material_id_within_snapshot", TRUE ~ NA_character_))
  quarantine <- obs_raw %>% filter(!is.na(quarantine_reason))
  observations <- obs_raw %>% filter(is.na(quarantine_reason))
  per_snapshot <- obs_raw %>% group_by(snapshot_id) %>%
    summarise(missing_music_id_rows = sum(is.na(douyin_music_id)), duplicate_music_id_rows = sum(duplicate_music_id),
              quarantined_rows = sum(!is.na(quarantine_reason)), clean_record_count = sum(is.na(quarantine_reason)),
              extra_parse_error_rows = sum(extra_parse_status %in% c("parse_error", "invalid_root", "invalid_type")),
              numeric_anomaly_rows = sum(!is.na(heat_issue) | !is.na(user_count_issue) | !is.na(duration_issue)), .groups = "drop")
  snapshots <- snapshots %>% left_join(per_snapshot, by = "snapshot_id") %>%
    group_by(source_sha256) %>% mutate(repeated_hash_across_dates = n_distinct(archive_date) > 1L) %>% ungroup() %>%
    rowwise() %>% mutate(quality_flag = flag_join(c("official_rank_unverified", "complete_chart_unknown", "release_date_semantics_unknown",
                        "heat_time_mechanism_not_uniform", "user_count_semantics_unverified", "duration_unit_unverified",
                        if (is.na(response_matches_archive)) "response_time_missing" else if (!response_matches_archive) "response_archive_date_mismatch",
                        if (repeated_hash_across_dates) "identical_content_across_dates", if (quarantined_rows > 0) "identity_rows_quarantined",
                        if (extra_parse_error_rows > 0) "metadata_extra_parse_errors", if (numeric_anomaly_rows > 0) "numeric_anomalies",
                        if (archive_date == end) "last_day_partial_snapshot_not_full_day")),
                        usable_for_snapshot_description = isTRUE(response_matches_archive) && !repeated_hash_across_dates) %>%
    ungroup() %>% arrange(archive_date)
  date_check <- tibble(archive_date = seq(start, end, by = "day")) %>%
    left_join(manifest %>% group_by(archive_date) %>% summarise(candidate_files = n(), parse_valid_files = sum(parse_status == "ok"),
                                                            selected_files = sum(selected_for_core_tables), .groups = "drop"), by = "archive_date") %>%
    mutate(across(c(candidate_files, parse_valid_files, selected_files), ~ replace_na(.x, 0L)),
           availability = case_when(candidate_files == 0L ~ "missing_file", parse_valid_files == 0L ~ "no_valid_file",
                                    selected_files == 0L ~ "ambiguous_multiple_valid_files", TRUE ~ "valid_snapshot")) %>%
    left_join(snapshots %>% select(archive_date, snapshot_id, response_time, source_release_date, source_file, record_count,
                                  clean_record_count, repeated_hash_across_dates, quality_flag), by = "archive_date")

  metadata_fields <- c("douyin_song_id", "title_raw", "author_raw", "album_raw", "genre_raw", "mood_raw", "theme_tags_raw", "language_raw",
                       "singing_versions_raw", "aeds_raw", "version_type_raw", "aigc_clip_raw", "music_label_id_raw", "peak_raw", "loudness_raw",
                       "is_original_sound", "lyric_url", "duration_raw")
  metadata_history <- observations %>% select(snapshot_id, archive_date, response_time, douyin_music_id, all_of(metadata_fields)) %>%
    arrange(douyin_music_id, archive_date, response_time, snapshot_id)
  metadata_changes <- metadata_history %>% mutate(across(all_of(metadata_fields), as.character)) %>%
    pivot_longer(all_of(metadata_fields), names_to = "field", values_to = "value") %>%
    group_by(douyin_music_id, field) %>% arrange(archive_date, response_time, snapshot_id, .by_group = TRUE) %>%
    mutate(previous_date = lag(archive_date), previous_snapshot_id = lag(snapshot_id), previous_value = lag(value),
           changed = row_number() > 1L & coalesce(value, "<NA>") != coalesce(previous_value, "<NA>")) %>%
    filter(changed) %>% ungroup() %>%
    select(douyin_music_id, field, previous_date, archive_date, previous_snapshot_id, snapshot_id, previous_value, value)
  metadata <- metadata_history %>% group_by(douyin_music_id) %>% slice_tail(n = 1L) %>% ungroup() %>%
    rename(metadata_as_of = archive_date, metadata_snapshot_id = snapshot_id, metadata_response_time = response_time) %>%
    mutate(metadata_selection_rule = "last_observed_by_archive_date_then_response_time; changes retained separately")

  missing_fields <- c("douyin_music_id", "douyin_song_id", "title_raw", "author_raw", "heat_raw", "user_count_raw", "duration_raw", "genre_raw", "mood_raw", "theme_tags_raw", "language_raw")
  field_missing <- obs_raw %>% select(all_of(missing_fields)) %>% mutate(across(everything(), as.character)) %>%
    pivot_longer(everything(), names_to = "field", values_to = "value") %>%
    group_by(field) %>% summarise(missing_count = sum(is.na(value) | str_trim(value) == "" | value %in% c("[]", "{}", "null")),
                                  denominator = n(), missing_rate = missing_count / denominator, .groups = "drop")
  annual <- obs_raw %>% mutate(year = year(archive_date)) %>% group_by(year) %>%
    summarise(raw_observations = n(), distinct_material_ids = n_distinct(douyin_music_id, na.rm = TRUE),
              snapshots = n_distinct(snapshot_id), duplicate_id_rows = sum(duplicate_music_id),
              quarantined_rows = sum(!is.na(quarantine_reason)), .groups = "drop")
  yearly_fields <- schema %>% group_by(year, field, type_signature) %>%
    summarise(snapshots = n(), present_count = sum(present_count), record_count = sum(record_count),
              coverage = present_count / record_count, .groups = "drop")
  tag_coverage <- obs_raw %>% mutate(year = year(archive_date)) %>% select(year, genre_raw, mood_raw, theme_tags_raw, language_raw, aigc_clip_raw) %>%
    mutate(across(-year, as.character)) %>% pivot_longer(-year, names_to = "field", values_to = "value") %>%
    group_by(year, field) %>% summarise(present_count = sum(!is.na(value) & !value %in% c("", "[]", "{}", "null")),
                                       record_count = n(), coverage = present_count / record_count, .groups = "drop")
  basic <- tibble(section = "overall", metric = c("requested_start", "requested_end", "requested_calendar_days", "valid_snapshot_count",
                    "effective_archive_start", "effective_archive_end", "missing_file_dates", "invalid_or_ambiguous_dates", "selected_source_raw_observations",
                    "clean_observations", "distinct_clean_music_ids", "quarantined_rows", "duplicate_id_rows", "extra_parse_error_rows", "numeric_anomaly_rows",
                    "record_count_min", "record_count_q25", "record_count_median", "record_count_q75", "record_count_max", "record_count_mean"),
                  value = as.character(c(as.character(start), as.character(end), nrow(date_check), nrow(snapshots),
                    as.character(min(snapshots$archive_date)), as.character(max(snapshots$archive_date)), sum(date_check$availability == "missing_file"),
                    sum(date_check$availability %in% c("no_valid_file", "ambiguous_multiple_valid_files")), nrow(obs_raw), nrow(observations),
                    n_distinct(observations$douyin_music_id), nrow(quarantine), sum(obs_raw$duplicate_music_id), sum(snapshots$extra_parse_error_rows),
                    sum(snapshots$numeric_anomaly_rows), min(snapshots$record_count), quantile(snapshots$record_count, .25), median(snapshots$record_count),
                    quantile(snapshots$record_count, .75), max(snapshots$record_count), mean(snapshots$record_count))))
  quality_summary <- bind_rows(basic,
    field_missing %>% transmute(section = "missing_rate", metric = field, value = as.character(missing_rate)),
    annual %>% mutate(year = as.character(year), across(-year, as.character)) %>% pivot_longer(-year, names_to = "measure", values_to = "value") %>%
      transmute(section = "annual", metric = paste(year, measure, sep = ":"), value))

  # Existing Python-produced audit CSVs are read only as references; every new check is R.
  python_reference <- tibble(archive_date = as.Date(character()), window_id = character(),
                             python_record_count = integer(), python_source_file = character())
  crosscheck <- python_reference %>% left_join(date_check %>% select(archive_date, r_record_count = record_count, r_source_file = source_file), by = "archive_date") %>%
    mutate(count_matches = !is.na(r_record_count) & python_record_count == r_record_count,
           path_matches = !is.na(r_source_file) & python_source_file == r_source_file)
  field_reference <- tibble(archive_date = as.Date(character()), douyin_music_id = character(),
                            python_song_id = character(), python_title = character(),
                            python_heat = character(), python_usage = character())
  id_crosscheck <- field_reference %>% left_join(observations %>% select(archive_date, douyin_music_id, douyin_song_id, title_raw, heat_raw, user_count_raw), by = c("archive_date", "douyin_music_id")) %>%
    mutate(id_and_values_match = coalesce(python_song_id, "<NA>") == coalesce(douyin_song_id, "<NA>") &
             coalesce(python_title, "<NA>") == coalesce(title_raw, "<NA>") &
             suppressWarnings(as.double(python_heat)) == heat_raw & suppressWarnings(as.double(python_usage)) == user_count_raw)
  manifest <- manifest %>% mutate(sha256_after = map_chr(file.path(root, source_file), ~ digest(file = .x, algo = "sha256")),
                                  source_unchanged = sha256_before == sha256_after)
  prior <- prior %>% mutate(sha256_after = character(), source_unchanged = logical())
  stopifnot(all(manifest$source_unchanged))
  tables <- list(douyin_snapshots = snapshots, douyin_observations = observations, douyin_music_metadata = metadata,
                 data_quality_summary = quality_summary, file_manifest = manifest, date_record_count_check = date_check,
                 quarantined_observations = quarantine, metadata_history = metadata_history, metadata_changes = metadata_changes,
                 field_missingness = field_missing, yearly_data_scale = annual, yearly_schema_check = yearly_fields,
                 yearly_tag_coverage = tag_coverage, python_audit_count_crosscheck = crosscheck, python_audit_id_crosscheck = id_crosscheck)
  iwalk(tables, ~ write_data(.x, file.path(data_dir, paste0(.y, ".csv"))))
  write_data(prior, file.path(report_dir, "prior_report_integrity.csv"))
  saveRDS(list(snapshots = snapshots, observations = observations, metadata = metadata), file.path(data_dir, "douyin_core_tables.rds"), version = 3)
  checks <- validate_exports(data_dir, snapshots, observations, metadata, obs_raw, quarantine, crosscheck, id_crosscheck)
  write_data(checks, file.path(report_dir, "validation_checks.csv"))
  writeLines(capture.output(sessionInfo()), file.path(report_dir, "sessionInfo.txt"))
  installed <- installed.packages()
  write_data(as_tibble(installed[, c("Package", "Version", "Built"), drop = FALSE]), file.path(report_dir, "installed_packages.csv"))
  run_info <- list(engine = "R", r_version = R.version.string, requested_start = as.character(start), requested_end = as.character(end),
                   effective_start = as.character(min(snapshots$archive_date)), effective_end = as.character(max(snapshots$archive_date)),
                   expected_dates = nrow(date_check), valid_snapshots = nrow(snapshots), raw_observations = nrow(obs_raw),
                   clean_observations = nrow(observations), unique_material_ids = n_distinct(observations$douyin_music_id),
                   missing_file_dates = sum(date_check$availability == "missing_file"), unusable_dates = sum(date_check$availability != "valid_snapshot"),
                   quarantined_rows = nrow(quarantine), metadata_change_events = nrow(metadata_changes),
                   python_count_checks = nrow(crosscheck), python_id_checks = nrow(id_crosscheck), all_validation_checks_passed = all(checks$passed))
  write_json(run_info, file.path(report_dir, "run_summary.json"), pretty = TRUE, auto_unbox = TRUE)
  # The package keeps one English README as its only narrative document.
  # Validation tables remain the machine-readable audit record.
  if (!all(checks$passed)) stop("R export validation failed; inspect reports/validation_checks.csv")
  message(toJSON(run_info, auto_unbox = TRUE, pretty = TRUE))
  invisible(run_info)
}

validate_exports <- function(data_dir, snapshots, observations, metadata, obs_raw, quarantine, crosscheck, id_crosscheck) {
  sn <- read_csv(file.path(data_dir, "douyin_snapshots.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
  ob <- read_csv(file.path(data_dir, "douyin_observations.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
  me <- read_csv(file.path(data_dir, "douyin_music_metadata.csv"), col_types = cols(.default = col_character()), show_col_types = FALSE)
  tag_fields <- c("genre_raw", "mood_raw", "theme_tags_raw", "language_raw", "version_type_raw")
  tags_valid <- all(map_lgl(unlist(me[tag_fields], use.names = FALSE), ~ is.na(.x) || (jsonlite::validate(.x) && str_starts(.x, fixed("[")))))
  checks <- c(snapshot_rows = nrow(sn) == nrow(snapshots), observation_rows = nrow(ob) == nrow(observations), metadata_rows = nrow(me) == nrow(metadata),
              snapshot_unique_key = !anyDuplicated(sn$snapshot_id), observation_unique_key = !anyDuplicated(paste(ob$snapshot_id, ob$douyin_music_id)),
              metadata_unique_key = !anyDuplicated(me$douyin_music_id), observation_foreign_key = all(ob$snapshot_id %in% sn$snapshot_id),
              metadata_foreign_key = all(ob$douyin_music_id %in% me$douyin_music_id),
              material_id_string_roundtrip = identical(ob$douyin_music_id, observations$douyin_music_id),
              song_id_string_roundtrip = identical(ob$douyin_song_id, observations$douyin_song_id),
              zero_missing_separate = sum(is.na(ob$heat_raw)) == sum(is.na(observations$heat_raw)) && sum(ob$heat_raw == "0", na.rm = TRUE) == sum(observations$heat_raw == 0, na.rm = TRUE),
              raw_clean_quarantine_conservation = nrow(obs_raw) == nrow(ob) + nrow(quarantine),
              source_record_conservation = sum(snapshots$record_count) == nrow(obs_raw),
              tags_valid_json_arrays = tags_valid, official_rank_not_assumed = all(sn$rank_verified == "FALSE") && all(sn$is_complete == "unknown"),
              python_date_count_agreement = all(crosscheck$count_matches & crosscheck$path_matches),
              python_id_and_value_agreement = all(id_crosscheck$id_and_values_match %in% TRUE))
  tibble(check = names(checks), passed = as.logical(checks), execution_engine = "R", note = "CSV round-trip and real prior-reference check")
}

write_phase_report <- function(report_dir, info, snapshots, manifest, missing, annual, changes) {
  year_lines <- apply(as.data.frame(annual), 1, function(x) paste0("|", paste(x, collapse = "|"), "|"))
  missing_lines <- pmap_chr(missing, function(field, missing_count, denominator, missing_rate) paste0("|", field, "|", missing_count, "/", denominator, "|", sprintf("%.2f%%", missing_rate * 100), "|"))
  text <- c("# MusicPulse — Douyin EDA Phase 1：R导入与清洗", "", "## 执行状态与范围", "",
    paste0("本阶段已实际使用 ", R.version.string, " 运行。JSON解析、清洗、变形、质量统计、CSV导出读回和参考对照均由R完成，没有使用Python/pandas处理EDA。"),
    paste0("请求区间 ", info$requested_start, "—", info$requested_end, "，共", info$expected_dates, "个日历日期；实际有效覆盖 ", info$effective_start, "—", info$effective_end, "。"),
    paste0("有效快照", info$valid_snapshots, "；缺文件日期", info$missing_file_dates, "；不可用日期", info$unusable_dates, "；选中源响应原始观测", info$raw_observations,
           "；清洗观测", info$clean_observations, "；不同素材", info$unique_material_ids, "；身份隔离行", info$quarantined_rows, "。"),
    "2026-11-13只有归档中已保存的一次响应，不是该日完整采集、日终统计或官方日榜。", "", "## 清洗与追溯", "",
    "递归发现音乐JSON并解析路径日期，不假设唯一目录布局；缺日、不合法JSON、非零状态、空列表、同日多份有效文件均记录。多份有效文件的日期保守排除，不静默择一。相同哈希跨日保留为质量异常。没有向缺失日期或未出现音乐补值。",
    "ID只读取id_str字符，缺失、非字符或非法格式不借用数字ID回填；jsonlite使用bigint_as_char保护大型整数解析。原始顺序保留为list_position，跨快照同ID保留；同快照重复或无有效素材ID的行隔离并记录，不任意保留第一条。",
    "heat/user_count/duration转换为数值；缺失不补0，非法/负数/非有限或不安全大数设NA并保留_source_text及问题原因。user_count要求整数；原始负增量不在本阶段解释或重新计算。extra原字符串与解析状态保留，多标签完整保存JSON数组，空数组与缺失有区别。",
    paste0("元数据采用按归档日期及响应时间排序的最后一次实际观察；每个素材一行。逐次元数据历史及", info$metadata_change_events, "项属性变化另表保留；不会默默覆盖。缺值参与变化检测，最后观察缺失不会擅自向前填补。"),
    "原文件SHA-256执行前后核验，结果在file_manifest.csv；所读此前报告/字典的哈希在prior_report_integrity.csv。所有源文件只读。", "", "## 年度规模", "",
    paste0("|", paste(names(annual), collapse = "|"), "|"), paste0("|", paste(rep("---", ncol(annual)), collapse = "|"), "|"), year_lines,
    "", "## 主要字段缺失率（选中源响应原始观测为分母）", "", "|字段|缺失/分母|缺失率|", "|---|---|---|", missing_lines,
    "", "## 异常与字段变化", "",
    paste0("无效候选文件", sum(manifest$parse_status != "ok"), "；同日多有效文件候选", sum(manifest$valid_files_on_date > 1L), "；重复ID行", sum(snapshots$duplicate_music_id_rows),
           "；extra解析异常行", sum(snapshots$extra_parse_error_rows), "；数值异常行", sum(snapshots$numeric_anomaly_rows), "；跨日期相同哈希快照", sum(snapshots$repeated_hash_across_dates), "。"),
    "yearly_schema_check.csv按年份/字段/类型签名记录覆盖差异；yearly_tag_coverage.csv另列标签及aigc覆盖。字段类型稳定不等于来源统计口径稳定。详情见逐快照日期计数表与质量标记，不在本阶段绘图或进行正式描述性研究。",
    "", "## R验收及既有Python审计对照", "",
    paste0("R生成date_record_count_check.csv，逐日保留可用性；对照既有Phase 3的", info$python_count_checks, "个样本行核对数量/路径，另对Phase 2的", info$python_id_checks,
           "条记录核对素材ID、歌曲ID、标题、heat和user_count。Python输出仅为参考，本阶段未运行Python。"),
    paste0("导出验收全部通过：", info$all_validation_checks_passed, "。详见validation_checks.csv与sessionInfo.txt；CSV读回显式保护ID，RDS同时保留R类型。"),
    "", "## 已知语义限制与Phase 2准入", "",
    "is_complete=unknown、rank_verified=FALSE表示官方完整性/排名未验证，不能因为JSON可读就自动设TRUE。source_release_date只是来源日期标签；不造官方统计周。list_position不是官方rank，本阶段也不生成官方或研究者排名。",
    "Themes不是完整歌词主题，music_label_id不是已验证厂牌，aigc_clip=false不证明非AI；duration单位与完整歌曲时长均未被官方认证。user_count记录值和差值不能直接称新增用户。不同素材版本不合并，group_id留空，未整合酷狗。",
    if (info$all_validation_checks_passed) "已具备进入Phase 2受限描述性统计的条件：只描述归档可见样本、来源记录值和平台标签，按质量标记与字段覆盖选择样本。尚不支持官方Top K在榜时长或全平台流行度推断。" else "验收仍有失败，暂不能进入Phase 2；先修复validation_checks.csv中的失败项。",
    "本阶段到此停止；未制作正式EDA可视化或Shiny Dashboard。")
  writeLines(enc2utf8(text), file.path(report_dir, "PHASE1_REPORT.md"), useBytes = TRUE)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  option <- function(name, default) { i <- match(name, args); if (is.na(i)) default else args[i + 1L] }
  script <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grepl("^--file=", commandArgs(trailingOnly = FALSE))][1])
  package_dir <- normalizePath(file.path(dirname(script), "../../.."), mustWork = FALSE)
  default_root <- file.path(package_dir, "01_data_acquisition/data/raw/douyin_json")
  default_out <- file.path(package_dir, "02_douyin_cleaning")
  import_clean(option("--root", default_root), option("--output", default_out))
}
if (sys.nframe() == 0L) main()
