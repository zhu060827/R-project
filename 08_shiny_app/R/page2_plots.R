feature_colours <- c(Douyin = '#537F94', Kugou = '#4F8985')
feature_pct <- function(x) ifelse(is.na(x), 'N/A', sprintf('%.1f%%', x))
feature_plot_layout <- function(p, ...) plotly::config(plotly::layout(p,
  font = list(family = 'system-ui, sans-serif', color = '#243746', size = 11),
  paper_bgcolor = 'white', plot_bgcolor = 'white', hoverlabel = list(bgcolor = 'white', font = list(size = 12)), ...),
  displayModeBar = FALSE, responsive = TRUE)

page2_genre_plot <- function(summary, selected, order) {
  tab <- summary$genre
  d <- tab[tab$platform == 'Douyin', ]; d <- d[match(order, d$label), ]
  k <- tab[tab$platform == 'Kugou', ]; k <- k[match(order, k$label), ]
  tooltip <- paste0('Unified Genre: ', order, '<br>Douyin: ', feature_pct(d$percentage), ' (', d$count, ' / ', d$denominator,
    ' classified materials)<br>Kugou: ', feature_pct(k$percentage), ' (', k$count, ' / ', k$denominator, ' classified tracks)')
  p <- plotly::plot_ly()
  for(platform in names(feature_colours)) {
    x <- if(platform == 'Douyin') d else k
    p <- plotly::add_trace(p, x = x$percentage, y = x$label, type = 'bar', orientation = 'h', name = platform,
      marker = list(color = ifelse(x$label %in% selected, feature_colours[[platform]], '#DDE4E8')),
      text = tooltip, textposition = 'none', hoverinfo = 'text', customdata = x$count, showlegend = FALSE)
  }
  feature_plot_layout(p, barmode = 'group', bargap = .25, margin = list(l = 143, r = 18, t = 35, b = 12),
    xaxis = list(title = '', range = c(0, 100), ticksuffix = '%', side = 'top', fixedrange = TRUE, gridcolor = '#EEF2F5', zeroline = FALSE),
    yaxis = list(title = '', categoryorder = 'array', categoryarray = rev(order), fixedrange = TRUE, automargin = FALSE))
}

page2_mood_plot <- function(summary, selected, order) {
  tab <- summary$mood
  z <- matrix(NA_real_, length(order), 2); text <- hover <- matrix('', length(order), 2)
  for(j in 1:2) {
    x <- tab[tab$platform == names(feature_colours)[j], ]; x <- x[match(order, x$label), ]
    z[,j] <- x$percentage; text[,j] <- feature_pct(x$percentage)
    hover[,j] <- paste0('Unified Mood: ', x$label, '<br>Platform: ', x$platform, '<br>Count: ', x$count,
      '<br>Percentage: ', feature_pct(x$percentage), '<br>Classified denominator: ', x$denominator)
  }
  # Selected and unselected layers retain the same values; masks affect colour only.
  active <- z; active[!order %in% selected, ] <- NA_real_
  grey <- z; grey[order %in% selected, ] <- NA_real_
  p <- plotly::plot_ly()
  # Numeric grid coordinates prevent Plotly's categorical matrix sorting from reordering z independently of hover text.
  for(kind in c('active', 'grey')) p <- plotly::add_trace(p, x = 0:1, y = seq_along(order),
    z = if(kind == 'active') active else grey, type = 'heatmap', zmin = 0, zmax = 100,
    colorscale = if(kind == 'active') list(list(0, '#E9F2F2'), list(.3, '#A5C6C7'), list(1, '#4F8985')) else list(list(0, '#E7ECEF'), list(1, '#E7ECEF')),
    text = hover, hoverinfo = 'text', hoverongaps = FALSE, xgap = 4, ygap = 3, showscale = FALSE, showlegend = FALSE)
  # Independent annotations keep real percentages legible on both colour layers, including NA.
  annotations <- unlist(lapply(seq_along(order), function(i) lapply(1:2, function(j)
    list(x = j-1L, y = i, text = text[i,j], showarrow = FALSE,
      font = list(size = 10, color = '#314F5D')))), recursive = FALSE)
  feature_plot_layout(p, margin = list(l = 146, r = 12, t = 32, b = 8), annotations = annotations,
    xaxis = list(title = '', side = 'top', tickvals = 0:1, ticktext = names(feature_colours), range = c(-.5,1.5), fixedrange = TRUE, showgrid = FALSE, zeroline = FALSE),
    yaxis = list(title = '', tickvals = seq_along(order), ticktext = order, range = c(length(order)+.5,.5), fixedrange = TRUE, showgrid = FALSE, zeroline = FALSE))
}

page2_duration_plot <- function(summary, platform) {
  tab <- summary$duration_bins[summary$duration_bins$platform == platform, ]
  axis <- if(platform == 'Douyin') 'Source duration (unit unverified)' else 'Duration (min)'
  if(!nrow(tab)) return(feature_plot_layout(plotly::plot_ly(type = 'scatter', mode = 'markers', x = numeric(), y = numeric()),
    annotations = list(list(x = .5, y = .5, xref = 'paper', yref = 'paper', text = 'No valid durations in this window', showarrow = FALSE)),
    xaxis = list(title = axis, fixedrange = TRUE), yaxis = list(title = 'Frequency', fixedrange = TRUE)))
  tab$tooltip <- paste0(platform, '<br>Interval: ', round(tab$xmin, 2), ' to ', round(tab$xmax, 2), ' ', tab$display_unit,
    '<br>Frequency: ', tab$count, '<br>Valid native units: ', tab$denominator)
  p <- ggplot2::ggplot(tab, ggplot2::aes(x = midpoint, y = count, text = tooltip)) +
    ggplot2::geom_col(width = (tab$xmax[1] - tab$xmin[1])*.82, fill = feature_colours[[platform]]) +
    ggplot2::scale_x_continuous(limits = c(0, max(tab$xmax)), expand = ggplot2::expansion(mult = c(.01, .02))) +
    ggplot2::labs(x = axis, y = 'Frequency') + ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(), panel.grid.major.x = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(size = 9), plot.margin = ggplot2::margin(8, 8, 0, 4))
  feature_plot_layout(plotly::ggplotly(p, tooltip = 'text'), margin = list(l = 40, r = 8, t = 10, b = 40),
    xaxis = list(fixedrange = TRUE), yaxis = list(fixedrange = TRUE, rangemode = 'tozero'))
}

page2_cloud_layout <- function(words) {
  if(!nrow(words)) return(words)
  stopifnot(nrow(words)<=18L,!anyDuplicated(words$keyword))
  words <- words[order(-words$weight,words$keyword,method='radix'),,drop=FALSE]
  n <- nrow(words); major <- max(1L,floor(n*.18)); medium <- min(n-major,max(1L,floor(n*.4)))
  ramp <- function(a,b,n) if(n==0L) numeric() else if(n==1L) a else seq(a,b,length.out=n)
  # Rank-based tiers remain readable even for equal scores; adding labels never shrinks all fonts.
  words$font_size <- c(ramp(48,40,major),ramp(32,24,medium),ramp(20,16,n-major-medium))
  # Reuse the installed systemfonts package to measure the actual Segoe UI glyphs.
  words$width <- as.double(systemfonts::string_width(words$keyword,family='Segoe UI',weight='semibold',
    size=words$font_size,res=72))*1.06+12
  words$height <- words$font_size*1.24+8
  stopifnot(all(words$width<=460))
  # Deterministic first-fit shelves avoid the fragmented empty spaces of greedy spirals.
  # Put the highest-scoring shelf at the centre and surround it with smaller-word shelves.
  rows <- list(); widths <- numeric()
  for(i in seq_len(n)) {
    eligible <- which(widths+words$width[i]+10<=460)
    row <- if(length(eligible)) eligible[1] else length(rows)+1L
    if(row>length(rows)) {rows[[row]]<-integer();widths[row]<-0}
    if(length(rows[[row]]))widths[row]<-widths[row]+10
    rows[[row]]<-c(rows[[row]],i);widths[row]<-widths[row]+words$width[i]
  }
  centres <- function(n) c(rev(seq_len(n)[seq_len(n)%%2L==0L]),1L,seq_len(n)[seq_len(n)>1L & seq_len(n)%%2L==1L])
  row_order <- centres(length(rows)); heights <- vapply(rows,function(ix)max(words$height[ix]),numeric(1))
  # Compact spare line gaps when necessary, preserving every word and every font size.
  row_gap <- if(length(rows)>1L) min(12,max(2,(320-24-sum(heights))/(length(rows)-1L))) else 0
  canvas_height <- max(320,sum(heights)+row_gap*(length(rows)-1L)+24)
  words$x <- words$y <- 0; y <- (canvas_height-sum(heights)-row_gap*(length(rows)-1L))/2
  for(row in row_order) {
    ix <- rows[[row]];ix <- ix[centres(length(ix))];x <- (484-widths[row])/2
    for(i in ix) {words$x[i]<-x+words$width[i]/2;words$y[i]<-y+heights[row]/2;x<-x+words$width[i]+10}
    y<-y+heights[row]+row_gap
  }
  words$canvas_height<-canvas_height
  words
}

page2_cloud_ui <- function(words) {
  if(!nrow(words)) return(shiny::tags$div(class = 'feature-empty', 'Select Genre or Mood labels to explore keywords.'))
  x <- page2_cloud_layout(words)
  shiny::tags$svg(class = 'keyword-svg', viewBox = paste(0, 0, 484, x$canvas_height[1]), role = 'img',
    `aria-label` = 'Editorial keywords associated with selected Genre and Mood labels',
    lapply(seq_len(nrow(x)), function(i) shiny::tags$text(x = x$x[i], y = x$y[i],
      `text-anchor` = 'middle', `dominant-baseline` = 'middle', `font-size` = x$font_size[i],
      fill = c(Genre = '#537F94', Mood = '#4F8985', Both = '#6D7B87')[[x$kind[i]]],
      `data-keyword` = x$keyword[i], `data-weight` = x$weight[i],
      shiny::tags$title(paste0(x$labels[i], '; visual score: ', x$weight[i], '; not lyric frequency')), x$keyword[i])))
}
