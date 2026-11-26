app_dir <- getOption('musicpulse.app_dir', normalizePath('.', winslash = '/'))
mp_theme <- list(
  ink='#442158', muted='#705F7D', purple='#9475BE', pink='#D99BC9', gold='#F2C987',
  cream='#FAF7FC', border='#EAE3EF', grid='#EFEAF3', selected='#59316F',
  platform=c(Douyin='#9475BE',Kugou='#F2C987',TikTok='#65447E',Spotify='#C56F9B'),
  country=c(China='#8767B2','United States'='#C983A5'),
  direction=c('Short-video first'='#BA8BB5','Streaming first'='#D6AE6F','Same day'='#D7D1DD'),
  coobserved=c(yes='#A18ABB', no='#E8C483'),
  cloud=c('#9475BE','#D18CB8','#C69C61','#AF77B1','#775398','#D7AC72','#B9789C','#8C73AE')
)
mp_theme_css <- function() htmltools::HTML(sprintf(
  ':root { --ink:%s; --muted:%s; --blue:%s; --teal:%s; --neutral:%s; --border:%s; --mp-purple:%s; --mp-pink:%s; --mp-gold:%s; --mp-cream:%s; --mp-selected:%s; --mp-grid:%s; --mp-coobserved:%s; --mp-not-coobserved:%s; --mp-kugou-ink:#89612B; }',
  mp_theme$ink, mp_theme$muted, mp_theme$purple, mp_theme$gold, mp_theme$gold,
  mp_theme$border, mp_theme$purple, mp_theme$pink, mp_theme$gold, mp_theme$cream,
  mp_theme$selected, mp_theme$grid, mp_theme$coobserved[['yes']], mp_theme$coobserved[['no']]
))
assign('mp_theme', mp_theme, envir = .GlobalEnv)
assign('mp_theme_css', mp_theme_css, envir = .GlobalEnv)
source(file.path(app_dir, 'R/data_loader.R'), local = .GlobalEnv)
project <- configure_musicpulse(app_dir)
source(file.path(app_dir, 'R/visual_theme.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/music_preview.R'), local = .GlobalEnv)
suppressPackageStartupMessages({ library(shiny); library(dplyr); library(tidyr) })
source(file.path(app_dir, 'R/page1_logic.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page1_plots.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page2_data.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page2_plots.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page2_module.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page3_data.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page3_plots.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page3_module.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page4_data.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page4_plots.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/page4_module.R'), local = .GlobalEnv)
source(file.path(app_dir, 'R/dashboard_loader.R'), local = .GlobalEnv)
dashboard_data <- load_dashboard_data(project,app_dir)
data <- dashboard_data$data
features <- dashboard_data$features
dynamics <- dashboard_data$dynamics
comparison <- dashboard_data$comparison
previews <- load_music_previews(project,data$candidates$cross_platform_song_id)
if(dir.exists(file.path(project,'data/music_preview_research/audio')))
  shiny::addResourcePath('musicpulse-preview-audio',file.path(project,'data/music_preview_research/audio'))
shiny::addResourcePath('musicpulse-assets', file.path(app_dir, 'www'))
# Keep the theme binding in app.R as well as visual_theme.R.  shinyapps.io
# evaluates app.R in a private environment and later evaluates the UI lazily.
if (!exists('mp_theme', inherits = FALSE)) {
  mp_theme <- list(
    ink='#442158', muted='#705F7D', purple='#9475BE', pink='#D99BC9', gold='#F2C987',
    cream='#FAF7FC', border='#EAE3EF', grid='#EFEAF3', selected='#59316F',
    platform=c(Douyin='#9475BE',Kugou='#F2C987',TikTok='#65447E',Spotify='#C56F9B'),
    country=c(China='#8767B2','United States'='#C983A5'),
    direction=c('Short-video first'='#BA8BB5','Streaming first'='#D6AE6F','Same day'='#D7D1DD'),
    coobserved=c(yes='#A18ABB', no='#E8C483'),
    cloud=c('#9475BE','#D18CB8','#C69C61','#AF77B1','#775398','#D7AC72','#B9789C','#8C73AE')
  )
}
if (!exists('mp_theme_css', inherits = FALSE)) {
  mp_theme_css <- function() htmltools::HTML(sprintf(
    ':root { --ink:%s; --muted:%s; --blue:%s; --teal:%s; --neutral:%s; --border:%s; --mp-purple:%s; --mp-pink:%s; --mp-gold:%s; --mp-cream:%s; --mp-selected:%s; --mp-grid:%s; --mp-coobserved:%s; --mp-not-coobserved:%s; --mp-kugou-ink:#89612B; }',
    mp_theme$ink, mp_theme$muted, mp_theme$purple, mp_theme$gold, mp_theme$gold,
    mp_theme$border, mp_theme$purple, mp_theme$pink, mp_theme$gold, mp_theme$cream,
    mp_theme$selected, mp_theme$grid, mp_theme$coobserved[['yes']], mp_theme$coobserved[['no']]
  ))
}
metric_card <- function(id, label, value, note) {
  role <- switch(id,kpi_candidates='lavender',kpi_shared='blush',kpi_days='champagne')
  icon <- switch(id,kpi_candidates='music',kpi_shared='shared',kpi_days='calendar')
  tags$article(class=paste('kpi-card',paste0('kpi-',role)),
    tags$span(class='kpi-icon',mp_icon(icon)),
    tags$div(class='kpi-copy',tags$div(class='kpi-label',label),tags$div(class='kpi-note',note)),
    tags$div(class='kpi-value',id=id,display_number(value)))
}
card_header <- function(title, right = NULL) tags$div(class = 'card-heading', tags$h2(title), right)
assign('metric_card', metric_card, envir = .GlobalEnv)
assign('card_header', card_header, envir = .GlobalEnv)
# UI: layout, controls and output containers only.
ui <- fluidPage(theme = bslib::bs_theme(version = 5, base_font = 'system-ui', primary = '#9475BE', bg = '#FAF7FC', fg = '#442158'),
  title = 'MusicPulse · Market Overview',
  tags$head(tags$meta(name = 'viewport', content = 'width=device-width, initial-scale=1'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/custom.css'), tags$script(src = 'musicpulse-assets/page1.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page2.css'), tags$script(src = 'musicpulse-assets/navigation.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page3.css'),tags$script(src='musicpulse-assets/page3.js'),
    tags$link(rel = 'stylesheet', href = 'musicpulse-assets/page4.css'),tags$script(src='musicpulse-assets/page4.js'),
    tags$script(src='musicpulse-assets/rounded_bars.js'),
    tags$style(mp_theme_css()), tags$link(rel='stylesheet',href='musicpulse-assets/visual_theme.css?v=grape1'),
    tags$link(rel='stylesheet',href='musicpulse-assets/music_preview.css'),tags$script(src='musicpulse-assets/music_preview.js')),
  tags$main(class = 'app-shell',
    tags$header(class = 'topbar', tags$div(class = 'brand', tags$div(class='brand-line',mp_icon('wave'),tags$span('MusicPulse')), tags$small('CHINA · DOUYIN × KUGOU')),
      tags$nav(class = 'main-nav', `aria-label` = 'Dashboard pages',
        tags$button(id = 'nav_overview', `data-page` = 'overview', class = 'nav-item active', type = 'button', `aria-current` = 'page', onclick = "return window.MusicPulseNavigate && (window.MusicPulseNavigate('overview'), false);", 'Overview'),
        tags$button(id = 'nav_features', `data-page` = 'features', class = 'nav-item', type = 'button', onclick = "return window.MusicPulseNavigate && (window.MusicPulseNavigate('features'), false);", 'Music Features'),
        tags$button(id = 'nav_dynamics', `data-page` = 'dynamics', class = 'nav-item', type = 'button', onclick = "return window.MusicPulseNavigate && (window.MusicPulseNavigate('dynamics'), false);", 'Dynamics'),
        tags$button(id = 'nav_compare', `data-page` = 'compare', class = 'nav-item', type = 'button', onclick = "return window.MusicPulseNavigate && (window.MusicPulseNavigate('compare'), false);", 'China vs US')),
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
# Server: existing per-page factories own all reactive/filter/event logic.
shinyApp(ui = ui, server = function(input, output, session) {
  make_page1_server(data,previews)(input, output, session)
  make_page2_server(features)(input, output, session)
  make_page3_server(dynamics,previews)(input, output, session)
  make_page4_server(comparison)(input, output, session)
})
