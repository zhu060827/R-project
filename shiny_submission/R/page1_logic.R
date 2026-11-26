valid_position <- function(x) !is.na(x) & is.finite(x) & x >= 1
mean_or_na <- function(x) { z <- x[valid_position(x)]; if(length(z)) mean(z) else NA_real_ }
first_or_na <- function(x) if(length(x)) min(x) else as.Date(NA_character_)
last_or_na <- function(x) if(length(x)) max(x) else as.Date(NA_character_)

summarise_window <- function(data, date_range) {
  dates <- as.Date(date_range)
  if(length(dates) != 2L || anyNA(dates) || dates[1] > dates[2]) stop('Choose a valid start and end date.')
  x <- data$daily %>% dplyr::filter(observation_date >= dates[1], observation_date <= dates[2])
  counts <- x %>% dplyr::group_by(cross_platform_song_id) %>% dplyr::summarise(
    douyin_days = dplyr::n_distinct(observation_date[douyin_observed == 1L]),
    kugou_days = dplyr::n_distinct(observation_date[kugou_observed == 1L]),
    union_days = dplyr::n_distinct(observation_date[douyin_observed == 1L | kugou_observed == 1L]),
    same_day_days = dplyr::n_distinct(observation_date[douyin_observed == 1L & kugou_observed == 1L]),
    douyin_valid_n = sum(douyin_observed == 1L & valid_position(douyin_rank)),
    kugou_valid_n = sum(kugou_observed == 1L & valid_position(kugou_rank)),
    mean_douyin = mean_or_na(douyin_rank[douyin_observed == 1L]),
    mean_kugou = mean_or_na(kugou_rank[kugou_observed == 1L]),
    douyin_first = first_or_na(observation_date[douyin_observed == 1L]),
    douyin_last = last_or_na(observation_date[douyin_observed == 1L]),
    kugou_first = first_or_na(observation_date[kugou_observed == 1L]),
    kugou_last = last_or_na(observation_date[kugou_observed == 1L]), .groups = 'drop')
  ans <- data$candidates %>% dplyr::left_join(counts, by = 'cross_platform_song_id')
  # Only counts of observation events can be zero; positions/dates remain NA, never zero-imputed.
  count_cols <- c('douyin_days', 'kugou_days', 'union_days', 'same_day_days', 'douyin_valid_n', 'kugou_valid_n')
  ans <- ans %>% dplyr::mutate(dplyr::across(dplyr::all_of(count_cols), ~ tidyr::replace_na(.x, 0L)),
    plottable = is.finite(mean_douyin) & is.finite(mean_kugou),
    coobserved = same_day_days > 0L,
    window_status = dplyr::case_when(douyin_days == 0 & kugou_days == 0 ~ 'No observations',
      douyin_days == 0 ~ 'Kugou only', kugou_days == 0 ~ 'Douyin only',
      !plottable ~ 'Position missing', TRUE ~ 'Both observed'))
  stopifnot(nrow(ans) == 95L, !anyDuplicated(ans$cross_platform_song_id),
    all(ans$union_days == ans$douyin_days + ans$kugou_days - ans$same_day_days),
    !any(is.nan(ans$mean_douyin)), !any(is.infinite(ans$mean_douyin)),
    !any(is.nan(ans$mean_kugou)), !any(is.infinite(ans$mean_kugou)))
  ans
}

filter_explorer <- function(stats, query = '', sort_by = 'union') {
  q <- stringr::str_to_lower(stringr::str_trim(if(is.null(query)) '' else query))
  if(nzchar(q)) stats <- stats %>% dplyr::filter(
    stringr::str_detect(stringr::str_to_lower(song_title), stringr::fixed(q)) |
    stringr::str_detect(stringr::str_to_lower(cross_platform_song_id), stringr::fixed(q)))
  switch(sort_by,
    title = dplyr::arrange(stats, song_title, cross_platform_song_id),
    douyin = dplyr::arrange(stats, dplyr::desc(douyin_days), song_title, cross_platform_song_id),
    kugou = dplyr::arrange(stats, dplyr::desc(kugou_days), song_title, cross_platform_song_id),
    dplyr::arrange(stats, dplyr::desc(union_days), song_title, cross_platform_song_id))
}

display_number <- function(x, digits = 0L) if(length(x) != 1L || is.na(x) || !is.finite(x)) 'N/A' else formatC(x, format = 'f', digits = digits, big.mark = ',')
display_days <- function(x) if(length(x) != 1L || is.na(x) || x == 0L) 'N/A' else display_number(x)
display_date <- function(x) if(length(x) != 1L || is.na(x)) 'N/A' else format(x, '%Y-%m-%d')

make_page1_server <- function(data,previews=NULL) {
  function(input, output, session) {
    selected_id <- shiny::reactiveVal(filter_explorer(summarise_window(data, data$bounds))$cross_platform_song_id[1])
    if(!is.null(previews))mp_register_preview(previews,selected_id,input,session)
    window_stats <- shiny::reactive({
      shiny::req(input$date_range)
      shiny::validate(shiny::need(length(input$date_range) == 2L && !anyNA(input$date_range) && input$date_range[1] <= input$date_range[2], 'Choose a valid date window.'))
      summarise_window(data, input$date_range)
    })
    explorer_rows <- shiny::reactive(filter_explorer(window_stats(), input$song_search, input$song_sort))
    choose_candidate <- function(id, locate = FALSE) {
      if(length(id) != 1L || !id %in% data$candidates$cross_platform_song_id) return(invisible(FALSE))
      selected_id(id)
      if(locate) {
        if(!id %in% explorer_rows()$cross_platform_song_id) shiny::updateTextInput(session, 'song_search', value = '')
        session$onFlushed(function() session$sendCustomMessage('focusCandidate', list(id = id)), once = TRUE)
      }
      invisible(TRUE)
    }
    shiny::observeEvent(input$bubble_select, choose_candidate(as.character(input$bubble_select), locate = TRUE), ignoreInit = TRUE)
    shiny::observeEvent(input$explorer_select, choose_candidate(as.character(input$explorer_select)), ignoreInit = TRUE)
    shiny::observeEvent(input$reset_window, shiny::updateDateRangeInput(session, 'date_range', start = data$bounds[1], end = data$bounds[2]))
    output$performance <- plotly::renderPlotly(build_performance_plot(window_stats(), selected_id(), data))
    output$plotted_count <- shiny::renderText(sprintf('Plotted candidates: %d / %d', sum(window_stats()$plottable), nrow(data$candidates)))
    output$explorer_count <- shiny::renderText(sprintf('%d / %d candidates', nrow(explorer_rows()), nrow(data$candidates)))
    output$window_label <- shiny::renderText(paste(format(as.Date(input$date_range), '%d %b %Y'), collapse = ' – '))
    output$explorer_rows <- shiny::renderUI({
      x <- explorer_rows(); id <- selected_id()
      if(!nrow(x)) return(shiny::tags$div(class = 'empty-list', 'No matching candidates. Try another title or ID.'))
      htmltools::tagList(lapply(seq_len(nrow(x)), function(i) {
        r <- x[i, ]
        shiny::tags$button(type = 'button', class = paste('song-row', if(r$cross_platform_song_id == id) 'is-selected'),
          `data-candidate-id` = r$cross_platform_song_id, `data-douyin-days` = r$douyin_days, `data-kugou-days` = r$kugou_days,
          `data-union-days` = r$union_days, `aria-pressed` = if(r$cross_platform_song_id == id) 'true' else 'false',
          title = paste(r$song_title, r$window_status, sep = ' · '),
          shiny::tags$span(class = 'song-name', shiny::tags$strong(r$song_title), shiny::tags$small(r$cross_platform_song_id)),
          shiny::tags$span(class = 'day-value douyin-text', display_days(r$douyin_days)),
          shiny::tags$span(class = 'day-value kugou-text', display_days(r$kugou_days)),
          shiny::tags$span(class = paste('row-status', if(r$window_status != 'Both observed') 'limited'), r$window_status))
      }))
    })
    output$selected_details <- shiny::renderUI({
      s <- window_stats() %>% dplyr::filter(cross_platform_song_id == selected_id())
      shiny::req(nrow(s) == 1L)
      metric <- function(label, value, class = '') shiny::tags$div(class = paste('detail-metric', class), shiny::tags$span(label), shiny::tags$strong(value))
      htmltools::tagList(shiny::tags$div(class = 'selected-heading',
        shiny::tags$h3(s$song_title), shiny::tags$div(class = 'selected-meta',
          shiny::tags$span(id = 'selected_candidate_id', `data-candidate-id` = s$cross_platform_song_id, s$cross_platform_song_id),
          shiny::tags$span(class = 'status-pill', s$window_status),
          if(!is.null(previews))mp_preview_entry(previews,s$cross_platform_song_id))),
        shiny::tags$div(class = 'detail-counts',
          metric('Douyin observed days', display_days(s$douyin_days), 'douyin-text'),
          metric('Kugou observed days', display_days(s$kugou_days), 'kugou-text'),
          metric('Union observed days', display_days(s$union_days)),
          metric('Same-day co-observed', if(s$union_days > 0) display_number(s$same_day_days) else 'N/A')),
        shiny::tags$div(class = 'detail-positions',
          metric('Douyin avg. provided position (unverified)', display_number(s$mean_douyin, 2)),
          metric('Kugou avg. recorded rank', display_number(s$mean_kugou, 2))),
        shiny::tags$div(class = 'detail-dates',
          metric('Douyin first observed', display_date(s$douyin_first)), metric('Douyin last observed', display_date(s$douyin_last)),
          metric('Kugou first observed', display_date(s$kugou_first)), metric('Kugou last observed', display_date(s$kugou_last))),
        shiny::tags$p(class = 'detail-note', if(!s$plottable) 'Not plotted: both platforms need valid positions in this window. ' else '',
          'Dates describe observations in the archived sample, not releases or official chart entry/exit.'))
    })
    # Client receives IDs only: titles never link components, and hover never changes selection.
    shiny::observe({ session$sendCustomMessage('currentCandidate', list(id = selected_id())) })
  }
}
