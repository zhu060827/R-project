page2_ui <- function(data) {
  filter_group <- function(attribute, id, labels, defaults) shiny::tags$section(class = 'feature-filter-group',
    shiny::tags$div(class = 'feature-filter-title', shiny::tags$h3(attribute),
      shiny::tags$div(shiny::actionButton(paste0(id, '_all'), 'Select all', class = 'feature-link'),
        shiny::actionButton(paste0(id, '_clear'), 'Clear', class = 'feature-link'))),
    shiny::tags$div(class = 'feature-checkbox-scroll', shiny::checkboxGroupInput(id, NULL, choices = labels, selected = defaults)))
  key <- shiny::tags$div(class = 'feature-platform-key',
    shiny::tags$span(shiny::tags$i(style = paste0('background:',feature_colours[['Douyin']])), 'Douyin materials'),
    shiny::tags$span(shiny::tags$i(style = paste0('background:',feature_colours[['Kugou']])), 'Kugou tracks'))
  shiny::tags$section(id = 'page2_view', class = 'page2-view', hidden = NA,
    shiny::tags$aside(class = 'dashboard-card feature-sidebar', card_header('Feature Filters'),
      shiny::tags$p(class = 'feature-hint', 'Highlight labels; all categories stay visible.'),
      filter_group('Genre', 'feature_genres', data$genre_order, head(data$genre_order, 5)),
      filter_group('Mood', 'feature_moods', data$mood_order, head(data$mood_order, 4))),
    shiny::tags$div(class = 'feature-main',
      shiny::tags$article(class = 'dashboard-card feature-genre', card_header('Music Genre Distribution'), key,
        shiny::tags$div(class = 'feature-denominator', shiny::textOutput('genre_denominator', inline = TRUE)),
        shiny::tags$div(class = 'feature-chart-scroll', plotly::plotlyOutput('feature_genre_plot', height = '100%')),
        shiny::tags$p(class = 'feature-note', '% of classified native units · team mapping; labels may overlap. Kugou coding awaits review.')),
      shiny::tags$article(class = 'dashboard-card feature-mood', card_header('Music Mood Heatmap'),
        shiny::tags$div(class = 'feature-denominator', shiny::textOutput('mood_denominator', inline = TRUE)),
        shiny::tags$div(class = 'feature-chart-scroll', plotly::plotlyOutput('feature_mood_plot', height = '100%')),
        shiny::tags$p(class = 'feature-note', 'Mood only · % of classified native units. Grey = not highlighted; values remain unchanged.')),
      shiny::tags$article(class = 'dashboard-card feature-duration', card_header('Audio Features · Duration'),
        shiny::tags$div(class = 'duration-pair', lapply(c('Douyin', 'Kugou'), function(platform)
          shiny::tags$section(class = 'duration-item',
            shiny::tags$h3(if(platform == 'Douyin') 'Douyin Audio Clip Duration' else 'Kugou Track Duration'),
            shiny::tags$p(class = 'duration-unit', if(platform == 'Douyin') 'Unit unverified · no conversion to minutes' else 'Supplier milliseconds converted to minutes'),
            shiny::tags$div(class = 'duration-plot', plotly::plotlyOutput(paste0('duration_', tolower(platform)), height = '100%'))))),
        shiny::tags$p(class = 'feature-note', shiny::textOutput('duration_denominator', inline = TRUE),
          shiny::tags$br(), 'One latest actual record per native ID in the date window. Frequency counts native units; no outliers removed.')),
      shiny::tags$article(class = 'dashboard-card feature-cloud', card_header('Genre & Mood Keywords'),
        shiny::tags$div(class = 'keyword-region', shiny::uiOutput('feature_keywords')),
        shiny::tags$p(class = 'feature-note', 'Researcher-defined keyword associations, not lyric frequencies. Top 36 · weighted across selected labels.'))))
}

make_page2_server <- function(data) function(input, output, session) {
  summary <- shiny::reactive({ shiny::req(input$date_range); page2_window_summary(data, input$date_range) })
  for(attribute in c('genres', 'moods')) local({
    a <- attribute; id <- paste0('feature_', a)
    shiny::observeEvent(input[[paste0(id, '_all')]], shiny::updateCheckboxGroupInput(session, id, selected = data[[paste0(if(a == 'genres') 'genre' else 'mood', '_order')]]))
    shiny::observeEvent(input[[paste0(id, '_clear')]], shiny::updateCheckboxGroupInput(session, id, selected = character()))
  })
  denominator <- function(attribute) {
    x <- summary()$coverage; x <- x[x$attribute == attribute, ]
    paste0('Classified: Douyin ', format(x$classified_units[x$platform == 'Douyin'], big.mark = ','), ' / Kugou ',
      format(x$classified_units[x$platform == 'Kugou'], big.mark = ','))
  }
  output$genre_denominator <- shiny::renderText(denominator('Genre'))
  output$mood_denominator <- shiny::renderText(denominator('Mood'))
  output$duration_denominator <- shiny::renderText({
    x <- summary()$duration
    paste0('Valid durations: Douyin ', sum(x$platform == 'Douyin' & x$valid), ' materials · Kugou ', sum(x$platform == 'Kugou' & x$valid), ' tracks.')
  })
  output$feature_genre_plot <- plotly::renderPlotly(page2_genre_plot(summary(), input$feature_genres, data$genre_order))
  output$feature_mood_plot <- plotly::renderPlotly(page2_mood_plot(summary(), input$feature_moods, data$mood_order))
  output$duration_douyin <- plotly::renderPlotly(page2_duration_plot(summary(), 'Douyin'))
  output$duration_kugou <- plotly::renderPlotly(page2_duration_plot(summary(), 'Kugou'))
  output$feature_keywords <- shiny::renderUI(page2_cloud_ui(page2_keyword_summary(data$keywords, input$feature_genres, input$feature_moods)))
}
