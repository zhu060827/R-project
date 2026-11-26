cmp_legend<-function(items)shiny::tags$div(class='cmp-legend',lapply(items,function(label)shiny::tags$span(shiny::tags$i(style=paste0('background:',cmp_colours[[label]])),label)))
page4_ui<-function(data){
 plot<-function(id)shiny::tags$div(class='cmp-plot',plotly::plotlyOutput(id,height='100%'))
 shiny::tags$section(id='page4_view',class='page4-view',hidden=NA,
  shiny::tags$aside(class='cmp-sidebar',
   shiny::tags$article(class='dashboard-card cmp-filter-card',card_header('Page Filters'),
    shiny::tags$div(class='cmp-filter-body',
    shiny::selectInput('cmp_dataset','Dataset',choices=c('Compare Both'='Compare both','China','United States')),
    shiny::selectizeInput('cmp_genres','Genre',choices=data$genre_levels,multiple=TRUE,options=list(placeholder='All genres',plugins=list('remove_button'))),
    shiny::selectInput('cmp_first','First-observed Platform',choices=c('All',cmp_directions)),
    shiny::sliderInput('cmp_months','Relative Month Range',min=1,max=data$max_month,value=c(1,data$max_month),step=1,sep='',ticks=FALSE),
    shiny::tags$div(class='cmp-selected-data',
     shiny::tags$h3('Selected Data'),
     shiny::tags$div(class='cmp-window',shiny::tags$strong('Relative observation window'),shiny::uiOutput('cmp_window')),
     shiny::uiOutput('cmp_kpis'),
     shiny::tags$p(class='cmp-sidebar-note','Shared candidates are compared within each market; the China and US recordings are not matched.'))))),
  shiny::tags$div(class='cmp-main',
   shiny::tags$article(id='cmp_card_a',class='dashboard-card cmp-a',card_header('Which Platform Appears First?'),
    shiny::tags$div(class='cmp-subtitle','Share of candidates first observed on each platform.'),plot('cmp_priority'),cmp_legend(cmp_directions),
    shiny::tags$p(class='cmp-note','Same-day observations are included.')),
   shiny::tags$article(id='cmp_card_b',class='dashboard-card cmp-b',card_header('First Observations by Calendar Month'),
    shiny::tags$div(class='cmp-subtitle','Calendar-month pattern of first observations.'),plot('cmp_monthly'),
    cmp_legend(c('Douyin','Kugou','TikTok','Spotify')),shiny::tags$p(class='cmp-note','Years are pooled by calendar month.')),
   shiny::tags$article(id='cmp_card_c',class='dashboard-card cmp-c',card_header('Timing Difference by Genre'),
    shiny::tags$div(class='cmp-subtitle','Difference between streaming-first and short-video-first dates.'),
    shiny::tags$div(class='cmp-plot',shiny::plotOutput('cmp_violin',height='100%')),cmp_legend(cmp_countries),
    shiny::tags$p(class='cmp-note','Positive values mean short-video was observed earlier; negative values mean streaming was earlier.')),
   shiny::tags$article(id='cmp_card_d',class='dashboard-card cmp-d',card_header('Genre Effects on Platform Priority'),
    shiny::tags$div(class='cmp-subtitle','Net first-observation preference by genre and country.'),plot('cmp_diverging'),
    shiny::tags$div(class='cmp-axis-note',shiny::tags$span('Short-video first ←'),shiny::tags$strong('Net Platform Priority (pp)'),shiny::tags$span('→ Streaming first')),
    shiny::tags$p(class='cmp-note','Bar direction shows which platform tends to appear first; hover for sample size.'))),
  shiny::tags$div(class='cmp-page-note',style='display:none;'))
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
 active<-shiny::reactive(if (is.null(input$active_page)) 'overview' else input$active_page)
 selected<-shiny::reactive({shiny::req(input$cmp_dataset,input$cmp_first,input$cmp_months)
  cmp_filter(data,input$cmp_dataset,input$cmp_genres,input$cmp_first,input$cmp_months)})
 summary<-shiny::reactive(cmp_summaries(selected(),cmp_markets(input$cmp_dataset)))
 output$cmp_window<-shiny::renderUI({shiny::req(active()=='compare',input$cmp_months)
  shiny::tagList(lapply(cmp_countries,function(country)shiny::tags$div(shiny::tags$span(country),shiny::tags$small(cmp_date_window(data,country,input$cmp_months)))))})
 output$cmp_kpis<-shiny::renderUI({shiny::req(active()=='compare');cmp_kpi_ui(summary())})
 output$cmp_priority<-plotly::renderPlotly({shiny::req(active()=='compare');cmp_priority_plot(summary())})
 output$cmp_monthly<-plotly::renderPlotly({shiny::req(active()=='compare');cmp_month_plot(summary())})
 output$cmp_violin<-shiny::renderPlot({shiny::req(active()=='compare');cmp_violin_plot(summary())},res=120)
 output$cmp_diverging<-plotly::renderPlotly({shiny::req(active()=='compare');cmp_diverging_plot(summary())})
 # A compact state, sourced from the common reactive, supports reproducible browser checks.
 shiny::observe({s<-summary();session$sendCustomMessage('musicpulse-compare-state',list(
  ids=s$events$candidate_id,n=nrow(s$events),countries=s$countries,genre=s$genre,
  months=input$cmp_months,dataset=input$cmp_dataset,first=input$cmp_first,genres=input$cmp_genres))})
}
