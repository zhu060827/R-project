if (!exists('mp_theme', inherits = TRUE)) mp_theme <- list(ink='#442158', muted='#705F7D', purple='#9475BE', grid='#EFEAF3', border='#EAE3EF', selected='#59316F', coobserved=c(yes='#A18ABB', no='#E8C483'))
venn_diagram <- function(coverage) {
  htmltools::HTML(sprintf('<svg class="venn-svg" viewBox="0 0 480 230" role="img" aria-labelledby="venn-title venn-desc">
  <title id="venn-title">Platform coverage, full dataset</title><desc id="venn-desc">Douyin only %s; shared %s; Kugou only %s. Conceptual areas are not proportional.</desc>
  <defs><clipPath id="douyin-clip"><circle cx="180" cy="122" r="104"/></clipPath></defs>
  <circle cx="180" cy="122" r="104" fill="#D9D1ED" fill-opacity=".48" stroke="#F5E9FF" stroke-width="1.6"/>
  <circle cx="300" cy="122" r="104" fill="#F2C987" fill-opacity=".42" stroke="#FAE9CD" stroke-width="1.6"/>
  <circle cx="300" cy="122" r="104" clip-path="url(#douyin-clip)" fill="#FFF4E2" fill-opacity=".24"><title>%s shared title-matched candidates</title></circle>
  <g text-anchor="middle" fill="#243746" font-family="Segoe UI, Microsoft YaHei, sans-serif">
    <text x="135" y="88" class="venn-platform" fill="#FFFFFF">Douyin</text><text x="345" y="88" class="venn-platform" fill="#FFFFFF">Kugou</text>
    <text x="135" y="136" class="venn-count" id="venn_douyin_only">%s</text><text x="345" y="136" class="venn-count" id="venn_kugou_only">%s</text>
    <text x="135" y="159" class="venn-label">only</text><text x="345" y="159" class="venn-label">only</text>
    <text x="240" y="103" class="venn-label venn-shared-label">Shared</text><text x="240" y="138" class="venn-count" id="venn_shared">%s</text>
  </g></svg>', coverage[['douyin_only']], coverage[['shared']], coverage[['kugou_only']], coverage[['shared']],
    display_number(coverage[['douyin_only']]), display_number(coverage[['kugou_only']]), display_number(coverage[['shared']])))
}

tooltip_title <- function(title) {
  starts <- seq.int(1L, max(1L, nchar(title)), by = 26L)
  paste(htmltools::htmlEscape(substring(title, starts, starts + 25L)), collapse = '<br>')
}

build_performance_plot <- function(stats, selected_id, data) {
  d <- stats %>% dplyr::filter(plottable) %>% dplyr::arrange(dplyr::desc(union_days), cross_platform_song_id)
  # One marker per candidate. Size values are union counts; Plotly maps AREA, with a clickability floor.
  if(nrow(d)) {
    text <- purrr::map_chr(seq_len(nrow(d)), function(i) {
      r <- d[i, ]
      paste0('<b>', tooltip_title(r$song_title), '</b><br>', r$cross_platform_song_id,
        '<br>Douyin avg. provided position (unverified): ', display_number(r$mean_douyin, 2),
        '<br>Kugou avg. recorded rank: ', display_number(r$mean_kugou, 2),
        '<br>Douyin observed days: ', r$douyin_days, '<br>Kugou observed days: ', r$kugou_days,
        '<br>Same-day co-observed days: ', r$same_day_days, '<br>Union observed days: ', r$union_days)
    })
    plot <- plotly::plot_ly(type = 'scatter', mode = 'markers', x = d$mean_douyin, y = d$mean_kugou,
      key = d$cross_platform_song_id, customdata = d$cross_platform_song_id, text = text, hoverinfo = 'text',
      marker = list(size = d$union_days, sizemode = 'area', sizeref = 2*max(d$union_days)/(42^2), sizemin = 5,
        color = ifelse(d$coobserved, mp_theme$coobserved[['yes']], mp_theme$coobserved[['no']]), opacity = ifelse(d$cross_platform_song_id == selected_id, 1, .72),
        line = list(color = ifelse(d$cross_platform_song_id == selected_id, mp_theme$selected, '#FFFFFF'),
          width = ifelse(d$cross_platform_song_id == selected_id, 3, .8))),
      showlegend = FALSE, source = 'performance')
    x_max <- max(5, ceiling(max(d$mean_douyin)/5)*5 + 1)
    y_max <- max(10, ceiling(max(d$mean_kugou)/10)*10 + 1)
    annotations <- list()
  } else {
    plot <- plotly::plot_ly(type = 'scatter', mode = 'markers', x = numeric(), y = numeric(), showlegend = FALSE, source = 'performance')
    x_max <- 60; y_max <- 101
    annotations <- list(list(x = .5, y = .5, xref = 'paper', yref = 'paper', showarrow = FALSE,
      text = 'No candidates have valid positions on both platforms<br>in this window. All 95 remain in Song Explorer.',
      font = list(size = 14, color = '#667780')))
  }
  plot <- plotly::layout(plot, autosize = TRUE, paper_bgcolor = 'white', plot_bgcolor = 'white',
    margin = list(l = 66, r = 20, t = 10, b = 48, pad = 0),
    font = list(family = 'Segoe UI, Microsoft YaHei, sans-serif', size = 12, color = mp_theme$ink),
    xaxis = list(title = list(text = data$douyin_axis_label, font = list(size = 12), standoff = 8),
      range = c(.5, x_max), zeroline = FALSE, gridcolor = mp_theme$grid, fixedrange = TRUE, tickformat = '.0f'),
    yaxis = list(title = list(text = 'Kugou Average Recorded Rank', font = list(size = 12), standoff = 8),
      range = c(y_max, .5), zeroline = FALSE, gridcolor = mp_theme$grid, fixedrange = TRUE, tickformat = '.0f'),
    hoverlabel = list(bgcolor = 'white', bordercolor = mp_theme$border, font = list(size = 12, color = mp_theme$ink), align = 'left', namelength = -1),
    hovermode = 'closest', clickmode = 'event', uirevision = 'page1', annotations = annotations)
  plot <- plotly::config(plot, displayModeBar = FALSE, displaylogo = FALSE, responsive = TRUE, scrollZoom = FALSE)
  htmlwidgets::onRender(plot, "function(el) { el.on('plotly_click', function(e) { if(e.points && e.points.length) { var p=e.points[0]; var id=p.customdata || p.key; if(id) Shiny.setInputValue('bubble_select', id, {priority:'event'}); } }); }")
}
if (!exists('mp_theme', inherits = TRUE)) mp_theme <- list(ink='#442158', muted='#705F7D', purple='#9475BE', grid='#EFEAF3', border='#EAE3EF', selected='#59316F', coobserved=c(yes='#A18ABB', no='#E8C483'))
