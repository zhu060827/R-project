page3_ui<-function(data){
  legend<-shiny::tags$div(class='dyn-legend',shiny::tags$span(shiny::tags$i(style='background:#537F94'),'Douyin'),shiny::tags$span(shiny::tags$i(style='background:#4F8985'),'Kugou'))
  plot<-function(id)shiny::tags$div(class='dyn-plot',plotly::plotlyOutput(id,height='100%'))
  shiny::tags$section(id='page3_view',class='page3-view',hidden=NA,
    shiny::tags$article(class='dashboard-card dyn-a',card_header('A · Sound Appearance Timeline',shiny::tags$span(class='scope-badge',shiny::textOutput('dyn_top_count',inline=TRUE))),
      shiny::tags$div(class='dyn-controls',shiny::selectInput('dyn_category','Category',c('All Songs','Genre','Mood')),
        shiny::uiOutput('dyn_label_ui'),shiny::selectInput('dyn_sort','Sort By',c('Total Unique Observed Days'='union','Same-day Overlap Days'='overlap','First-observed Gap'='gap','Douyin Observed Days'='douyin','Kugou Observed Days'='kugou'),selected='union')),
      plot('dyn_timeline'),legend,shiny::tags$p(class='dyn-note','Actual observed runs; gaps remain visible. Click a song or segment to inspect.')),
    shiny::tags$article(class='dashboard-card dyn-b',card_header('B · Lead–Lag Distribution',
        shiny::radioButtons('dyn_b_attribute',NULL,c('Mood','Genre'),selected='Mood',inline=TRUE)),
      shiny::tags$div(class='dyn-subtitle',shiny::textOutput('dyn_b_count',inline=TRUE)),plot('dyn_scatter'),
      shiny::tags$p(class='dyn-note','← Kugou earlier · Same day at 0 · Douyin earlier →',shiny::tags$br(),'Dark ticks = category medians · all eligible candidates, not only Top 10.')),
    shiny::tags$article(class='dashboard-card dyn-c',card_header('C · Monthly Visibility Matrix',shiny::tags$span(class='scope-badge','Same Top 10 as A')),
      shiny::tags$div(id='dyn_matrix_scroll',class='dyn-matrix-scroll',shiny::uiOutput('dyn_matrix')),
      shiny::tags$div(class='dyn-legend',shiny::tags$span(shiny::tags$i(style='background:#537F94'),'D · left cell'),
        shiny::tags$span(shiny::tags$i(style='background:#4F8985'),'K · right cell'),shiny::tags$span('Bold D / K / = · first-observed month')),
      shiny::tags$p(class='dyn-note','Intensity = observed / valid archive days · neutral = 0 · scroll → for all months.')),
    shiny::tags$article(class='dashboard-card dyn-d',shiny::uiOutput('dyn_insights')),
    shiny::tags$div(class='dyn-page-note','First observed within selected window · 95 title-matched shared-song candidates, not verified recordings · Observed order does not establish diffusion.'))
}

dyn_metric<-function(label,value)shiny::tags$div(class='dyn-metric',shiny::tags$span(label),shiny::tags$strong(value))
dyn_overview_ui<-function(top,filter_label){
  x<-top[!top$placeholder,];valid<-sum(!is.na(x$lead_lag_days));counts<-c(sum(x$lead_lag_days>0,na.rm=TRUE),sum(x$lead_lag_days<0,na.rm=TRUE),sum(x$lead_lag_days==0,na.rm=TRUE))
  median_gap<-if(valid)paste0(format(stats::median(x$absolute_gap,na.rm=TRUE),trim=TRUE),'d') else 'N/A'
  shiny::tagList(card_header('Top 10 Cross-platform Insights',shiny::tags$span(class='scope-badge','Overview')),
    shiny::tags$div(class='dyn-d-body',
      shiny::tags$div(class='dyn-direction-counts',dyn_metric('Douyin earlier',counts[1]),dyn_metric('Kugou earlier',counts[2]),dyn_metric('Same day',counts[3])),
      shiny::tags$div(class='dyn-overview-gap',dyn_metric('Median absolute first-observed gap',median_gap),shiny::tags$span(paste(valid,'valid dual-platform candidates'))),
      shiny::tags$div(class='dyn-composition',if(valid)lapply(1:3,function(i)shiny::tags$div(style=paste0('width:',100*counts[i]/valid,'%;background:',c('#537F94','#4F8985','#A4ADB4')[i]),title=paste(c('Douyin earlier','Kugou earlier','Same day')[i],counts[i]))) else shiny::tags$div(style='width:100%;background:#E8EDF0')),
      shiny::tags$p(class='dyn-composition-note',paste0('Direction composition among ',valid,' candidates with both first dates.')),
      shiny::tags$div(class='dyn-overview-context',shiny::tags$strong(filter_label),shiny::tags$span(paste(nrow(x),'eligible candidates; grey placeholders excluded.')),
        shiny::tags$span(paste('Insufficient dual-platform data:',nrow(x)-valid))),
      shiny::tags$p(class='dyn-detail-note','Click A, B or C to inspect one candidate. Within-window first dates are affected by the selected boundary; they are not release or original diffusion dates.')))
}

dyn_detail_ui<-function(x,in_top,origin,selected_month,monthly){
  shiny::tagList(card_header('Selected Song Dynamics',shiny::tags$span(class='scope-badge',if(in_top)'Current Top 10' else 'Outside current Top 10')),
    shiny::tags$div(class='dyn-d-body dyn-selected-body',
      shiny::tags$div(class='dyn-selected-title',shiny::tags$h3(title=x$song_title,x$song_title),shiny::tags$small(paste(x$cross_platform_song_id,'· Selected from',origin))),
      shiny::tags$div(class='dyn-selected-direction',dyn_lead_text(x)),
      shiny::tags$div(class='dyn-date-pair',dyn_metric('Douyin first observed',dyn_date(x$douyin_first)),dyn_metric('Kugou first observed',dyn_date(x$kugou_first))),
      shiny::tags$div(class='dyn-selected-counts',dyn_metric('Douyin days',x$douyin_days),dyn_metric('Kugou days',x$kugou_days),dyn_metric('Same-day overlap',x$same_day_days)),
      shiny::tags$div(class='dyn-lead-value',shiny::tags$span('Lead days'),shiny::tags$strong(if(is.na(x$lead_lag_days))'N/A' else abs(x$lead_lag_days))),
      if(!is.null(selected_month)&&nrow(monthly))shiny::tags$div(class='dyn-selected-month',shiny::tags$strong(paste('Selected month:',selected_month)),
        shiny::tags$span(paste(vapply(1:nrow(monthly),function(i)paste0(monthly$platform[i],': ',monthly$observed_days[i],' / ',monthly$valid_archive_days[i],' days (',if(is.na(monthly$intensity[i]))'N/A' else sprintf('%.1f%%',100*monthly$intensity[i]),')'),character(1)),collapse=' · '))),
      shiny::actionButton('dyn_back','Back to Top 10 Overview',class='dyn-back')))
}

make_page3_server<-function(data)function(input,output,session){
  window<-shiny::reactive({shiny::req(input$date_range);dyn_window(data,input$date_range)})
  choices<-shiny::reactive(if(identical(input$dyn_category,'Mood'))data$mood_order else data$genre_order)
  output$dyn_label_ui<-shiny::renderUI({
    if(is.null(input$dyn_category)||input$dyn_category=='All Songs')shiny::tags$div(class='dyn-label-placeholder',shiny::tags$label('Label'),shiny::tags$span('All labels'))
    else shiny::selectInput('dyn_label','Label',choices=choices(),selected=choices()[1])
  })
  label<-shiny::reactive(if(identical(input$dyn_category,'All Songs'))NULL else if(!is.null(input$dyn_label)&&input$dyn_label%in%choices())input$dyn_label else choices()[1])
  top<-shiny::reactive({shiny::req(input$dyn_category,input$dyn_sort);dyn_top10(window(),input$dyn_category,label(),input$dyn_sort)})
  matrix<-shiny::reactive(dyn_matrix(window(),top()))
  selected_song_id<-shiny::reactiveVal(NULL);selected_month<-shiny::reactiveVal(NULL);selected_origin<-shiny::reactiveVal(NULL)
  clear<-function(){selected_song_id(NULL);selected_month(NULL);selected_origin(NULL)}
  shiny::observeEvent(input$dyn_select,{
    e<-input$dyn_select;if(!is.character(e$id)||length(e$id)!=1L||!e$id%in%data$candidates$cross_platform_song_id)return()
    if(e$origin%in%c('A','C')&&!e$id%in%top()$cross_platform_song_id)return()
    selected_song_id(e$id);selected_origin(e$origin)
    month<-e$month;if(!is.null(month)&&month%in%format(window()$months,'%Y-%m'))selected_month(month) else selected_month(NULL)
  },ignoreInit=TRUE)
  shiny::observeEvent(input$dyn_back,clear(),ignoreInit=TRUE)
  shiny::observeEvent(list(input$date_range,input$dyn_category,input$dyn_label,input$dyn_sort),{
    id<-selected_song_id();if(!is.null(id)&&!identical(selected_origin(),'B')&&!id%in%top()$cross_platform_song_id)clear()
    m<-selected_month();if(!is.null(m)&&!m%in%format(window()$months,'%Y-%m'))selected_month(NULL)
  },ignoreInit=TRUE,priority=-1)
  output$dyn_top_count<-shiny::renderText(paste(sum(!top()$placeholder),'/ 10 candidates'))
  output$dyn_b_count<-shiny::renderText({a<-if(is.null(input$dyn_b_attribute))'Mood' else input$dyn_b_attribute;x<-dyn_scatter_data(window(),a,if(a=='Mood')data$mood_order else data$genre_order)
    paste(dplyr::n_distinct(x$cross_platform_song_id),'classified candidates ·',nrow(x),'label memberships')})
  output$dyn_timeline<-plotly::renderPlotly(dyn_timeline_plot(window(),top(),selected_song_id()))
  output$dyn_scatter<-plotly::renderPlotly({shiny::req(input$dyn_b_attribute);dyn_scatter_plot(window(),input$dyn_b_attribute,if(input$dyn_b_attribute=='Mood')data$mood_order else data$genre_order,selected_song_id())})
  output$dyn_matrix<-shiny::renderUI(dyn_matrix_ui(window(),top(),matrix(),selected_song_id()))
  output$dyn_insights<-shiny::renderUI({
    id<-selected_song_id()
    if(is.null(id)){
      sortnames<-c(union='Total Unique Observed Days',overlap='Same-day Overlap Days',gap='First-observed Gap',douyin='Douyin Observed Days',kugou='Kugou Observed Days')
      filter_label<-paste0(input$dyn_category,if(!is.null(label()))paste0(' · ',label())else'', ' · Sorted by ',sortnames[[input$dyn_sort]])
      dyn_overview_ui(top(),filter_label)
    }else{
      x<-window()$stats%>%dplyr::filter(cross_platform_song_id==id);m<-selected_month()
      monthly<-if(is.null(m))matrix()[0,]else matrix()%>%dplyr::filter(cross_platform_song_id==id,format(month,'%Y-%m')==m)
      dyn_detail_ui(x,id%in%top()$cross_platform_song_id,selected_origin(),m,monthly)
    }
  })
}
