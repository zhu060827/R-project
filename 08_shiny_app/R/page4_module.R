cmp_legend<-function(items)shiny::tags$div(class='cmp-legend',lapply(items,function(label)shiny::tags$span(shiny::tags$i(style=paste0('background:',cmp_colours[[label]])),label)))
page4_ui<-function(data){
 plot<-function(id)shiny::tags$div(class='cmp-plot',plotly::plotlyOutput(id,height='100%'))
 shiny::tags$section(id='page4_view',class='page4-view',hidden=NA,
  shiny::tags$aside(class='dashboard-card cmp-sidebar',card_header('Page Filters'),
   shiny::tags$div(class='cmp-filter-body',
    shiny::selectInput('cmp_dataset','Dataset',choices=c('Compare Both'='Compare both','China','United States')),
    shiny::selectizeInput('cmp_genres','Genre',choices=data$genre_levels,multiple=TRUE,options=list(placeholder='All genres',plugins=list('remove_button'))),
    shiny::selectInput('cmp_first','First-observed Platform',choices=c('All',cmp_directions)),
    shiny::sliderInput('cmp_months','Relative Month Range',min=1,max=data$max_month,value=c(1,data$max_month),step=1,sep='',ticks=FALSE),
    shiny::tags$div(class='cmp-window',shiny::tags$strong('Relative observation window'),shiny::uiOutput('cmp_window')),
    shiny::tags$p(class='cmp-filter-hint','Selects the month when both platforms have first been observed. First dates retain the full archive history.'),
    shiny::uiOutput('cmp_kpis'),
    shiny::tags$div(class='cmp-sidebar-note',shiny::tags$strong('Different historical windows'),shiny::tags$span('Shared candidates within each market; not matched recordings across markets.')))),
  shiny::tags$div(class='cmp-charts',
   shiny::tags$article(id='cmp_card_a',class='dashboard-card cmp-a',card_header('A · Which Platform Appears First?'),
    shiny::tags$div(class='cmp-subtitle','Current filtered subset · Same day included in n'),plot('cmp_priority'),cmp_legend(cmp_directions),
    shiny::tags$p(class='cmp-note','Within archived samples; observed order does not establish diffusion.')),
   shiny::tags$article(id='cmp_card_b',class='dashboard-card cmp-b',card_header('B · First Observations by Calendar Month'),
    shiny::tags$div(class='cmp-subtitle','Distribution of first observations · country non–Same day n'),plot('cmp_monthly'),
    cmp_legend(c('Douyin','Kugou','TikTok','Spotify')),shiny::tags$p(class='cmp-note','Years pooled by calendar month. Denominator: all filtered non–Same day candidates in that country.')),
   shiny::tags$article(id='cmp_card_c',class='dashboard-card cmp-c',card_header('C · Timing Difference by Genre'),
    shiny::tags$div(class='cmp-subtitle','Streaming first date − short-video first date'),
    shiny::tags$div(class='cmp-plot',shiny::plotOutput('cmp_violin',height='100%')),cmp_legend(cmp_countries),
    shiny::tags$p(class='cmp-note','Positive = short-video earlier · negative = streaming earlier. n < 5: points only; all observed extremes retained.')),
   shiny::tags$article(id='cmp_card_d',class='dashboard-card cmp-d',card_header('D · Genre Effects on Platform Priority'),
    shiny::tags$div(class='cmp-subtitle','Which platform is observed first across genres in China and the US?'),plot('cmp_diverging'),
    shiny::tags$div(class='cmp-axis-note',shiny::tags$span('Streaming first ←'),shiny::tags$strong('Net Platform Priority (pp)'),shiny::tags$span('→ Short-video first')),
    shiny::tags$p(class='cmp-note','Labels = directional lead magnitude; hover = signed net. Same day in n; faded: n < 5.'))),
  shiny::tags$div(class='cmp-page-note','First observed in the archived sample ≠ release date or causal origin · China: multi-label Genre; US: supplied priority / first-row Genre rule.'))
}
cmp_kpi_ui<-function(s){
 shiny::tags$div(class='cmp-kpis',lapply(c('Short-video platform first','Streaming platform first'),function(label){
  col<-if(grepl('^Short',label))'short'else'stream'
  shiny::tags$article(class=paste('cmp-kpi',col),shiny::tags$div(class='kpi-label',label),
   shiny::tags$div(class='cmp-kpi-pair',lapply(cmp_countries,function(country){
    a<-s$countries[s$countries$country==country,];value<-a[[paste0(col,'_share')]]
    shiny::tags$div(shiny::tags$span(if(country=='China')'China'else'US'),
      shiny::tags$strong(cmp_pct(value)),shiny::tags$small(paste0(a[[col]],' / ',a$n))) })))
 }))
}
make_page4_server<-function(data)function(input,output,session){
 selected<-shiny::reactive({shiny::req(input$cmp_dataset,input$cmp_first,input$cmp_months)
  cmp_filter(data,input$cmp_dataset,input$cmp_genres,input$cmp_first,input$cmp_months)})
 summary<-shiny::reactive(cmp_summaries(selected(),cmp_markets(input$cmp_dataset)))
 output$cmp_window<-shiny::renderUI({shiny::req(input$cmp_months)
  shiny::tagList(lapply(cmp_countries,function(country)shiny::tags$div(shiny::tags$span(country),shiny::tags$small(cmp_date_window(data,country,input$cmp_months)))))})
 output$cmp_kpis<-shiny::renderUI(cmp_kpi_ui(summary()))
 output$cmp_priority<-plotly::renderPlotly(cmp_priority_plot(summary()))
 output$cmp_monthly<-plotly::renderPlotly(cmp_month_plot(summary()))
 output$cmp_violin<-shiny::renderPlot(cmp_violin_plot(summary()),res=96)
 output$cmp_diverging<-plotly::renderPlotly(cmp_diverging_plot(summary()))
 # A compact state, sourced from the common reactive, supports reproducible browser checks.
 shiny::observe({s<-summary();session$sendCustomMessage('musicpulse-compare-state',list(
  ids=s$events$candidate_id,n=nrow(s$events),countries=s$countries,genre=s$genre,
  months=input$cmp_months,dataset=input$cmp_dataset,first=input$cmp_first,genres=input$cmp_genres))})
}
