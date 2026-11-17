# Page 2 reads existing, audited tables only; each source date/ID key must be unique.
decode_feature_tags <- function(x) lapply(x, function(z) {
  if(is.na(z)) return(character())
  a <- jsonlite::fromJSON(z, simplifyVector = FALSE)
  if(!is.list(a) || !all(vapply(a, function(v) is.character(v) && length(v) == 1L, logical(1)))) stop('Invalid feature tag array.')
  unique(unlist(a, use.names = FALSE))
})

load_page2_data <- function(project, app_dir, references = TRUE) {
  category_env <- new.env(parent=environment())
  sys.source(file.path(app_dir,'R/page2_category_mapping.R'),envir=category_env)
  mapping <- category_env$page2_team_mapping()
  root <- file.path(project, 'outputs/musicpulse_team_handoff/data')
  d <- readr::read_csv(file.path(root, 'douyin/douyin_master_dataset.csv'),
    col_types = readr::cols_only(douyin_music_id = readr::col_character(), observation_date = readr::col_date(),
      response_time = readr::col_datetime(), title_raw = readr::col_character(), genre_raw = readr::col_character(),
      mood_raw = readr::col_character(), duration_raw = readr::col_double(), duration_unit = readr::col_character(),
      is_recovered_snapshot = readr::col_logical()), na = '\\N', trim_ws = FALSE,
    locale = readr::locale(tz = 'Asia/Shanghai'), show_col_types = FALSE)
  k <- readr::read_csv(file.path(root, 'kugou/kugou_eda_daily.csv'),
    col_types = readr::cols_only(kugou_song_id = readr::col_character(), chart_date = readr::col_date(),
      track_name = readr::col_character(), genre_category = readr::col_character(), mood_category = readr::col_character(),
      duration_ms = readr::col_double(), coding_method = readr::col_character(), taxonomy_source = readr::col_character(),
      taxonomy_method = readr::col_character(), taxonomy_review_required = readr::col_character()),
    na = c('', '\\N'), trim_ws = FALSE, show_col_types = FALSE)
  tracks <- readr::read_csv(file.path(root, 'kugou/kugou_eda_track.csv'),
    col_types = readr::cols_only(kugou_song_id = readr::col_character()), na = '\\N', show_col_types = FALSE)
  stopifnot(nrow(readr::problems(d)) == 0L, nrow(readr::problems(k)) == 0L,
    nrow(d) == 36615L, nrow(k) == 73000L, nrow(tracks) == 2635L,
    !anyDuplicated(d[c('douyin_music_id', 'observation_date')]), !anyDuplicated(k[c('kugou_song_id', 'chart_date')]),
    all(k$kugou_song_id %in% tracks$kugou_song_id), all(d$duration_unit == 'unverified_source_unit'))
  d <- d %>% dplyr::mutate(unit_id = douyin_music_id, genre_tags = decode_feature_tags(genre_raw), mood_tags = decode_feature_tags(mood_raw))
  k <- k %>% dplyr::mutate(unit_id = kugou_song_id, observation_date = chart_date,
    genre_tags = lapply(genre_category, function(z) if(is.na(z)) character() else z),
    mood_tags = lapply(mood_category, function(z) if(is.na(z)) character() else z))
  inventory <- dplyr::bind_rows(
    dplyr::tibble(platform = 'Douyin', attribute = 'Genre', source_label = sort(unique(unlist(d$genre_tags)))),
    dplyr::tibble(platform = 'Douyin', attribute = 'Mood', source_label = sort(unique(unlist(d$mood_tags)))),
    dplyr::tibble(platform = 'Kugou', attribute = 'Genre', source_label = sort(unique(unlist(k$genre_tags)))),
    dplyr::tibble(platform = 'Kugou', attribute = 'Mood', source_label = sort(unique(unlist(k$mood_tags)))))
  result <- list(douyin=d,kugou=k,inventory=inventory,mapping=mapping,
    genres=mapping$genre_order,moods=mapping$mood_order,genre_order=mapping$genre_order,mood_order=mapping$mood_order)
  result$unmapped <- inventory %>% dplyr::filter((attribute=='Genre' & !source_label %in% names(mapping$genre_map)) |
    (attribute=='Mood' & !source_label %in% names(mapping$mood_map)))
  if(references) {
    alignment <- readr::read_csv(file.path(app_dir, 'data/page2_label_alignment.csv'), col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE)
    stopifnot(identical(alignment$display_label, alignment$source_label),
      setequal(paste(inventory$platform, inventory$attribute, inventory$source_label), paste(alignment$platform, alignment$attribute, alignment$source_label)))
    result$keywords <- category_env$page2_team_keywords()
    stopifnot(all(result$keywords$attribute %in% c('Genre', 'Mood')),
      setequal(result$keywords$label[result$keywords$attribute == 'Genre'], result$genres),
      setequal(result$keywords$label[result$keywords$attribute == 'Mood'], result$moods),
      !anyDuplicated(result$keywords[c('attribute', 'label', 'keyword')]))
  }
  result
}

page2_latest_units <- function(x, dates) x %>% dplyr::filter(observation_date >= dates[1], observation_date <= dates[2]) %>%
  dplyr::arrange(unit_id, dplyr::desc(observation_date)) %>% dplyr::group_by(unit_id) %>% dplyr::slice_head(n = 1L) %>% dplyr::ungroup()

page2_window_summary <- function(data, dates) {
  dates <- as.Date(dates)
  stopifnot(length(dates) == 2L, !anyNA(dates), dates[1] <= dates[2])
  units <- list(Douyin = page2_latest_units(data$douyin, dates), Kugou = page2_latest_units(data$kugou, dates))
  coverage <- list()
  attribute_table <- function(attribute, labels) {
    field <- if(attribute == 'Genre') 'genre_tags' else 'mood_tags'
    dplyr::bind_rows(lapply(names(units), function(platform) {
      x <- units[[platform]]
      lookup <- if(attribute=='Genre') data$mapping$genre_map else data$mapping$mood_map
      cache_field <- if(attribute=='Genre')'genre_unified_tags'else'mood_unified_tags'
      tags <- if(cache_field%in%names(x))x[[cache_field]]else lapply(x[[field]],function(raw) unique(unname(lookup[raw])[!is.na(unname(lookup[raw]))]))
      valid <- lengths(tags)>0L; denominator <- sum(valid)
      source_field <- if(platform == 'Douyin') if(attribute == 'Genre') 'genre_raw' else 'mood_raw' else if(attribute == 'Genre') 'genre_category' else 'mood_category'
      coverage[[length(coverage) + 1L]] <<- dplyr::tibble(platform, attribute, observed_units = nrow(x), classified_units = denominator,
        raw_classified_units=sum(lengths(x[[field]])>0L),unmapped_only_units=sum(lengths(x[[field]])>0L & !valid),
        units_with_unmapped_tags=sum(vapply(x[[field]],function(raw)any(!raw %in% names(lookup)),logical(1))),
        missing_units = sum(is.na(x[[source_field]])), empty_array_units = sum(!is.na(x[[source_field]]) & x[[source_field]] == '[]'))
      counts <- vapply(labels, function(label) sum(vapply(tags, function(values) label %in% values, logical(1))), integer(1))
      percentages <- if(denominator > 0L) 100*counts/denominator else rep(NA_real_, length(counts))
      dplyr::tibble(platform, attribute, label = labels, count = unname(counts), denominator,
        percentage = unname(percentages))
    }))
  }
  genre <- attribute_table('Genre', data$genres); mood <- attribute_table('Mood', data$moods)
  duration <- dplyr::bind_rows(lapply(names(units), function(platform) {
    x <- units[[platform]]
    raw <- if(platform == 'Douyin') x$duration_raw else x$duration_ms
    value <- if(platform == 'Douyin') raw else raw/60000
    display_unit <- if(platform == 'Douyin') 'source units (unverified)' else 'min'
    dplyr::tibble(platform, unit_id = x$unit_id, source_date = x$observation_date, source_duration = raw, value,
      display_unit = display_unit,
      valid = !is.na(value) & is.finite(value) & value >= 0)
  }))
  list(genre = genre, mood = mood, coverage = dplyr::bind_rows(coverage), units = units, duration = duration,
    duration_bins = page2_duration_bins(duration), dates = dates)
}

page2_duration_bins <- function(duration) dplyr::bind_rows(lapply(c('Douyin', 'Kugou'), function(platform) {
  x <- duration[duration$platform == platform & duration$valid, ]
  if(!nrow(x)) return(dplyr::tibble(platform = character(), xmin = double(), xmax = double(), midpoint = double(), count = integer(), denominator = integer(), display_unit = character()))
  upper <- if(max(x$value) == 0) 1 else if(max(x$value) > 20) ceiling(max(x$value)/50)*50 else ceiling(max(x$value))
  breaks <- seq(0, upper, length.out = 7L)
  bins <- graphics::hist(x$value, breaks = breaks, right = FALSE, include.lowest = TRUE, plot = FALSE)
  dplyr::tibble(platform, xmin = head(breaks, -1L), xmax = tail(breaks, -1L), midpoint = bins$mids,
    count = bins$counts, denominator = nrow(x), display_unit = x$display_unit[1])
}))

page2_normalize_keywords <- function(x) {
  x <- stringr::str_to_lower(stringr::str_squish(x))
  # Explicit spelling / inflection aliases only; semantically different words stay separate.
  aliases <- c(beats='beat',guitars='guitar',drums='drum',vocals='vocal',riffs='riff',
    memories='memory',melodic='melody',rhythmic='rhythm',energetic='energy',nostalgic='nostalgia',
    'up-beat'='upbeat','hip-hop'='hip hop')
  mapped <- unname(aliases[x]); ifelse(is.na(mapped),x,mapped)
}

page2_keyword_summary <- function(dictionary, genres, moods) {
  weight_field <- if('base_weight' %in% names(dictionary)) 'base_weight' else 'preset_weight'
  dictionary <- dictionary %>% dplyr::filter((attribute == 'Genre' & label %in% genres) | (attribute == 'Mood' & label %in% moods))
  if(!nrow(dictionary)) return(dplyr::tibble(keyword=character(),base_weight_sum=double(),distinct_selected_label_count=integer(),labels=character(),kind=character(),weight=double()))
  dictionary %>%
    dplyr::mutate(keyword = page2_normalize_keywords(keyword), base_weight = .data[[weight_field]]) %>%
    # Aliases inside one label represent one association, with its strongest preset weight.
    dplyr::group_by(attribute,label,keyword) %>% dplyr::summarise(base_weight=max(base_weight),.groups='drop') %>%
    dplyr::group_by(keyword) %>% dplyr::summarise(base_weight_sum=sum(base_weight),
      distinct_selected_label_count=dplyr::n_distinct(paste(attribute,label,sep=': ')),
      labels=paste(sort(unique(paste(attribute,label,sep=': '))),collapse='; '),
      kind=if(dplyr::n_distinct(attribute)>1L) 'Both' else dplyr::first(attribute),.groups='drop') %>%
    dplyr::mutate(weight=base_weight_sum+1.5*(distinct_selected_label_count-1)) %>%
    dplyr::arrange(dplyr::desc(weight),keyword) %>% dplyr::slice_head(n=18L)
}
