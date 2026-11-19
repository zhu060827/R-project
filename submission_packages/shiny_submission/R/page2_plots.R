feature_colours <- mp_theme$platform[c('Douyin','Kugou')]
feature_pct <- function(x) ifelse(is.na(x), 'N/A', sprintf('%.1f%%', x))
feature_plot_layout <- function(p, ...) plotly::config(plotly::layout(p,
  font = list(family = 'system-ui, sans-serif', color = mp_theme$ink, size = 11),
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
      marker = list(color = ifelse(x$label %in% selected, feature_colours[[platform]], '#E8E1EC')),
      text = tooltip, textposition = 'none', hoverinfo = 'text', customdata = x$count, showlegend = FALSE)
  }
  feature_plot_layout(p, barmode = 'group', bargap = .25, margin = list(l = 143, r = 18, t = 35, b = 12),
    xaxis = list(title = '', range = c(0, 100), ticksuffix = '%', side = 'top', fixedrange = TRUE, gridcolor = mp_theme$grid, zeroline = FALSE),
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
    colorscale = if(kind == 'active') list(list(0, '#FAF6FB'), list(.3, '#D6BEDF'), list(1, mp_theme$purple)) else list(list(0, '#EEEAF1'), list(1, '#EEEAF1')),
    text = hover, hoverinfo = 'text', hoverongaps = FALSE, xgap = 4, ygap = 3, showscale = FALSE, showlegend = FALSE)
  # Independent annotations keep real percentages legible on both colour layers, including NA.
  annotations <- unlist(lapply(seq_along(order), function(i) lapply(1:2, function(j)
    list(x = j-1L, y = i, text = text[i,j], showarrow = FALSE,
      font = list(size = 10, color = mp_theme$ink)))), recursive = FALSE)
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
  stopifnot(nrow(words)<=36L,!anyDuplicated(words$keyword))
  words <- words[order(-words$weight,words$keyword,method='radix'),,drop=FALSE]
  n <- nrow(words); rank <- seq_len(n)
  canvas_width <- 484; canvas_height <- 340
  rank_score <- if(n==1L) 1 else (n-rank)/(n-1)
  words$font_size <- round(8+30*rank_score^1.65)
  rotation_pattern <- c(0,0,90,0,-90,0,0,90,0,-90,0,0)
  words$angle <- rotation_pattern[(rank-1L)%%length(rotation_pattern)+1L]
  words$angle[rank<=2L] <- 0
  words$x <- words$y <- NA_real_

  placed <- data.frame(left=numeric(),right=numeric(),top=numeric(),bottom=numeric())
  measure_box <- function(label,size,angle) {
    # Keep collision boxes close to the visible glyphs so the finished cloud reads
    # as one compact mass instead of a set of widely separated labels.
    text_width <- as.double(systemfonts::string_width(label,family='Segoe UI',weight='semibold',size=size,res=72))*1.01+3
    text_height <- size*.98+3
    if(abs(angle)==90)c(width=text_height,height=text_width)else c(width=text_width,height=text_height)
  }
  overlaps <- function(left,right,top,bottom,gap=.6) {
    if(!nrow(placed))return(FALSE)
    any(left<placed$right+gap & right>placed$left-gap & top<placed$bottom+gap & bottom>placed$top-gap)
  }

  # Largest words start in the centre; smaller words follow a deterministic oval spiral.
  # Axis-aligned boxes are exact for the supported 0/90-degree rotations.
  for(i in rank) {
    found <- FALSE
    for(size in seq(words$font_size[i],7,by=-1)) {
      box <- measure_box(words$keyword[i],size,words$angle[i])
      for(step in 0:6000) {
        radius <- 2.45*sqrt(step)
        theta <- step*.47+i*.71
        cx <- canvas_width/2+cos(theta)*radius*1.12
        cy <- canvas_height/2+sin(theta)*radius*.78
        left <- cx-box[['width']]/2; right <- cx+box[['width']]/2
        top <- cy-box[['height']]/2; bottom <- cy+box[['height']]/2
        inside <- left>=8 && right<=canvas_width-8 && top>=8 && bottom<=canvas_height-8
        if(inside && !overlaps(left,right,top,bottom)) {
          words$x[i] <- cx; words$y[i] <- cy; words$font_size[i] <- size
          placed <- rbind(placed,data.frame(left,right,top,bottom)); found <- TRUE; break
        }
      }
      if(found)break
    }
    if(!found)stop('Unable to place keyword in word cloud: ',words$keyword[i])
  }
  # Enlarge the completed cloud to use the available card area without changing spacing.
  final_boxes <- t(vapply(rank,function(i)measure_box(words$keyword[i],words$font_size[i],words$angle[i]),numeric(2)))
  cloud_left <- min(words$x-final_boxes[,'width']/2); cloud_right <- max(words$x+final_boxes[,'width']/2)
  cloud_top <- min(words$y-final_boxes[,'height']/2); cloud_bottom <- max(words$y+final_boxes[,'height']/2)
  cloud_scale <- min((canvas_width-6)/(cloud_right-cloud_left),(canvas_height-6)/(cloud_bottom-cloud_top),1.34)
  cloud_cx <- (cloud_left+cloud_right)/2; cloud_cy <- (cloud_top+cloud_bottom)/2
  words$x <- (words$x-cloud_cx)*cloud_scale+canvas_width/2
  words$y <- (words$y-cloud_cy)*cloud_scale+canvas_height/2
  words$font_size <- round(words$font_size*cloud_scale,1)

  palette <- mp_theme$cloud
  kind_offset <- match(words$kind,c('Genre','Mood','Both'));kind_offset[is.na(kind_offset)]<-1L
  words$colour <- palette[((rank-1L)*3L+kind_offset-1L)%%length(palette)+1L]
  words$opacity <- pmax(.65,1-(rank-1L)*.012)
  words$canvas_height <- canvas_height
  words
}

page2_cloud_ui <- function(words) {
  if(!nrow(words)) return(shiny::tags$div(class = 'feature-empty', 'Select Genre or Mood labels to explore keywords.'))
  x <- page2_cloud_layout(words)
  shiny::tags$svg(class = 'keyword-svg', viewBox = paste(0, 0, 484, x$canvas_height[1]), role = 'img',
    `aria-label` = 'Editorial keywords associated with selected Genre and Mood labels',
    lapply(seq_len(nrow(x)), function(i) shiny::tags$text(x = x$x[i], y = x$y[i],
      `text-anchor` = 'middle', `dominant-baseline` = 'middle', `font-size` = x$font_size[i],
      transform = paste0('rotate(',x$angle[i],' ',x$x[i],' ',x$y[i],')'),
      fill = x$colour[i], `fill-opacity` = x$opacity[i],
      `font-weight` = if(x$font_size[i]>=34) 650 else if(x$font_size[i]>=21) 600 else 500,
      `data-keyword` = x$keyword[i], `data-weight` = x$weight[i],
      shiny::tags$title(paste0(x$labels[i], '; visual score: ', x$weight[i], '; not lyric frequency')), x$keyword[i])))
}
