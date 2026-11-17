app_dir <- getOption('musicpulse.app_dir', normalizePath('.', winslash = '/'))
source(file.path(app_dir, 'R/data_loader.R'), local = TRUE)
project <- configure_musicpulse(app_dir)
suppressPackageStartupMessages({ library(shiny); library(dplyr); library(tidyr) })
source(file.path(app_dir, 'R/page1_logic.R'), local = TRUE)
source(file.path(app_dir, 'R/page1_plots.R'), local = TRUE)
source(file.path(app_dir, 'R/page2_data.R'), local = TRUE)
source(file.path(app_dir, 'R/page2_plots.R'), local = TRUE)
source(file.path(app_dir, 'R/page2_module.R'), local = TRUE)
source(file.path(app_dir, 'R/page3_data.R'), local = TRUE)
source(file.path(app_dir, 'R/page3_plots.R'), local = TRUE)
source(file.path(app_dir, 'R/page3_module.R'), local = TRUE)
source(file.path(app_dir, 'R/page4_data.R'), local = TRUE)
source(file.path(app_dir, 'R/page4_plots.R'), local = TRUE)
source(file.path(app_dir, 'R/page4_module.R'), local = TRUE)
source(file.path(app_dir, 'R/dashboard_loader.R'), local = TRUE)
dashboard_data <- load_dashboard_data(project,app_dir)
data <- dashboard_data$data
features <- dashboard_data$features
dynamics <- dashboard_data$dynamics
comparison <- dashboard_data$comparison
shiny::addResourcePath('musicpulse-assets', file.path(app_dir, 'www'))
metric_card <- function(id, label, value, note) tags$article(class = 'kpi-card', tags$div(class = 'kpi-label', label),
  tags$div(class = 'kpi-value', id = id, display_number(value)), tags$div(class = 'kpi-note', note))
card_header <- function(title, right = NULL) tags$div(class = 'card-heading', tags$h2(title), right)
ui <- fluidPage(theme = bslib::bs_theme(version = 5, base_font = 'system-ui', primary = '#537F94', bg = '#F5F7FA', fg = '#243746'),
  title = 'MusicPulse · Market Overview',
  tags$head(tags$meta(name = 'viewport', content = 'width=device-width, initial-scale=1'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/custom.css'), tags$script(src = 'musicpulse-assets/page1.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page2.css'), tags$script(src = 'musicpulse-assets/navigation.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page3.css'),tags$script(src='musicpulse-assets/page3.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page4.css'),tags$script(src='musicpulse-assets/page4.js')),
  tags$main(class = 'app-shell',
    tags$header(class = 'topbar', tags$div(class = 'brand', tags$span('MusicPulse'), tags$small('CHINA · DOUYIN × KUGOU')),
      tags$nav(class = 'main-nav', `aria-label` = 'Dashboard pages',
        tags$button(id = 'nav_overview', `data-page` = 'overview', class = 'nav-item active', type = 'button', `aria-current` = 'page', 'Overview'),
        tags$button(id = 'nav_features', `data-page` = 'features', class = 'nav-item', type = 'button', 'Music Features'),
        tags$button(id = 'nav_dynamics', `data-page` = 'dynamics', class = 'nav-item', type = 'button', 'Dynamics'),
        tags$button(id = 'nav_compare', `data-page` = 'compare', class = 'nav-item', type = 'button', 'China vs US')),
      tags$div(class = 'global-filter', dateRangeInput('date_range', 'Global date filter',
        start = data$bounds[1], end = data$bounds[2], min = data$bounds[1], max = data$bounds[2], format = 'yyyy-mm-dd', separator = 'to', autoclose = TRUE),
        actionButton('reset_window', 'Full window', class = 'reset-window')),
      tags$div(class='compare-header-note',tags$strong('Relative observation window'),'China & US · different historical periods')),
    tags$div(id = 'page1_view', class = 'page1-view',
    tags$section(class = 'kpi-grid', `aria-label` = 'Market snapshot, full dataset',
      metric_card('kpi_candidates', 'Song candidates', data$kpis[['song_candidates']], 'Full dataset · normalized-title groups'),
      metric_card('kpi_shared', 'Shared candidates', data$kpis[['shared_candidates']], 'Full dataset · title-matched candidates'),
      metric_card('kpi_days', 'Calendar days', data$kpis[['calendar_days']], 'Full observation window · KPIs stay fixed')),
    tags$section(class = 'comparison-grid',
      tags$article(class = 'dashboard-card coverage-card', card_header('Platform Coverage', tags$span(class = 'scope-badge', 'Full dataset')),
        tags$div(class = 'venn-region', venn_diagram(data$coverage)),
        tags$div(class = 'card-footnote', tags$strong('Conceptual Venn — areas not proportional'), tags$span('Normalized-title candidate groups; recording identity is unverified.'))),
      tags$article(class = 'dashboard-card performance-card',
        card_header('Platform Performance Comparison', tags$span(class = 'scope-badge', textOutput('plotted_count', inline = TRUE))),
        tags$div(class = 'card-subtitle', 'Douyin Provided Position (unverified) vs. Kugou Recorded Rank'),
        tags$div(class = 'plot-region', plotly::plotlyOutput('performance', width = '100%', height = '100%')),
        tags$div(class = 'plot-key', tags$span(tags$i(class = 'key-dot teal'), 'Same-day co-observed'),
          tags$span(tags$i(class = 'key-dot neutral'), 'No same-day co-observation'), tags$span(class = 'size-key', 'Area = union observed days')),
        tags$p(class = 'chart-note', 'Averages use positive observations in the selected window. Source position systems are not equivalent.'))),
    tags$section(class = 'explorer-grid',
      tags$article(class = 'dashboard-card explorer-card', card_header('Song Explorer', tags$span(class = 'scope-badge', textOutput('explorer_count', inline = TRUE))),
        tags$div(class = 'explorer-controls', textInput('song_search', NULL, placeholder = 'Search title or candidate ID'),
          selectInput('song_sort', NULL, choices = c('Union days ↓' = 'union', 'Douyin days ↓' = 'douyin', 'Kugou days ↓' = 'kugou', 'Song title A–Z' = 'title'), selected = 'union')),
        tags$div(class = 'list-column-head', tags$span('Title / candidate ID'), tags$span('Douyin days'), tags$span('Kugou days'), tags$span('Window status')),
        tags$div(id = 'song_list_scroll', class = 'song-list-scroll', role = 'region', `aria-label` = 'Scrollable candidate list', uiOutput('explorer_rows')),
        tags$div(class = 'explorer-footer', textOutput('window_label', inline = TRUE), tags$span('95 shared candidates · archived sample'))),
      tags$article(class = 'dashboard-card details-card', card_header('Selected Song Details', tags$span(class = 'scope-badge', 'Selected window')),
        uiOutput('selected_details')))),
    page2_ui(features),page3_ui(dynamics),page4_ui(comparison))
)
shinyApp(ui = ui, server = function(input, output, session) {
  make_page1_server(data)(input, output, session)
  make_page2_server(features)(input, output, session)
  make_page3_server(dynamics)(input, output, session)
  make_page4_server(comparison)(input, output, session)
})
