if (!exists('mp_theme', inherits = TRUE)) mp_theme <- list(ink='#442158', muted='#705F7D', purple='#9475BE', grid='#EFEAF3', border='#EAE3EF', selected='#59316F', platform=c(Douyin='#9475BE',Kugou='#F2C987'), coobserved=c(yes='#A18ABB', no='#E8C483'))
dyn_colours<-c(Douyin='#9475BE', Kugou='#F2C987')
dyn_date<-function(x)ifelse(is.na(x),'N/A',format(as.Date(x),'%Y-%m-%d'))
dyn_lead_text<-function(x)ifelse(is.na(x$lead_lag_days),'One-platform observation',ifelse(x$lead_lag_days==0L,'Same day',paste0(x$lead_direction,' · ',abs(x$lead_lag_days),'d')))
dyn_row_labels<-function(top)paste0(top$slot,'. ',ifelse(top$placeholder,'No eligible song',stringr::str_trunc(top$song_title,14)))
dyn_hover<-function(x)paste0('Song title: ',htmltools::htmlEscape(x$song_title),'<br>Candidate ID: ',x$cross_platform_song_id,
 '<br>Douyin first observed: ',dyn_date(x$douyin_first),'<br>Kugou first observed: ',dyn_date(x$kugou_first),
 '<br>Lead platform: ',x$lead_direction,'<br>Lead days: ',ifelse(is.na(x$lead_lag_days),'N/A',abs(x$lead_lag_days)))
dyn_layout<-function(p,...)plotly::config(plotly::layout(p,font=list(family='system-ui, sans-serif',size=10,color=mp_theme$ink),
 paper_bgcolor='white',plot_bgcolor='white',hoverlabel=list(bgcolor='white',font=list(size=11)),...),displayModeBar=FALSE,responsive=TRUE)
dyn_clicks<-function(p,origin,ids=NULL,months=NULL){
 js<-sprintf("function(el,x,data){el._dynRows=(data||{}).ids||[];if(el._dynClickHandler&&el.removeListener)el.removeListener('plotly_click',el._dynClickHandler);el._dynClickHandler=function(e){var v=e.points&&e.points[0]&&e.points[0].customdata;if(!v)return;var a=String(v).split('|');Shiny.setInputValue('dyn_select',{id:a[0],month:a[1]||null,origin:'%s',nonce:performance.now()},{priority:'event'});};el.on('plotly_click',el._dynClickHandler);if(!el._dynRowBound){el._dynRowBound=true;el.addEventListener('click',function(e){var t=e.target.closest('.ytick');if(!t)return;var m=t.textContent.match(/^(\\d+)\\./),id=m&&el._dynRows[+m[1]-1];if(id)Shiny.setInputValue('dyn_select',{id:id,month:null,origin:'%s',nonce:performance.now()},{priority:'event'});});}}",origin,origin)
 htmlwidgets::onRender(p,js,data=list(ids=ids,months=months))
}
dyn_placeholder_shapes<-function(top)lapply(top$slot[top$placeholder],function(s)list(type='rect',xref='paper',x0=0,x1=1,yref='y',y0=s-.45,y1=s+.45,
 fillcolor='#F3F6F8',line=list(width=0),layer='below'))

dyn_timeline_plot<-function(window,top,selected=NULL){
 runs<-window$runs %>% dplyr::inner_join(top%>%dplyr::filter(!placeholder),by='cross_platform_song_id',relationship='many-to-one')
 p<-plotly::plot_ly()
 for(platform in c('Douyin','Kugou')){
  x<-runs[runs$platform==platform,]
  if(!nrow(x))next
  colours<-rep(dyn_colours[[platform]],nrow(x))
  p<-plotly::add_trace(p,type='bar',orientation='h',y=x$slot+if(platform=='Douyin')-.17 else .17,
   x=as.double(x$end-x$start+1)*86400000,base=as.double(x$start)*86400000,width=.30,
   marker=list(color=colours,line=list(color=mp_theme$ink,width=ifelse(x$cross_platform_song_id%in%selected,1.4,0))),customdata=x$cross_platform_song_id,
   text=dyn_hover(x),textposition='none',hoverinfo='text',name=platform,showlegend=FALSE)
 }
 if(!nrow(runs))p<-plotly::plot_ly(x=numeric(),y=numeric(),type='scatter',mode='markers',marker=list(color='#DDE4E8'),hoverinfo='skip',showlegend=FALSE)
 p<-dyn_layout(p,barmode='overlay',margin=list(l=155,r=12,t=5,b=34),shapes=dyn_placeholder_shapes(top),
  xaxis=list(type='date',title='',range=c(as.double(window$dates[1])*86400000,as.double(window$dates[2]+1)*86400000),tickformat="%b '%y",nticks=6,fixedrange=TRUE,gridcolor=mp_theme$grid,zeroline=FALSE),
  yaxis=list(title='',tickvals=1:10,ticktext=dyn_row_labels(top),range=c(10.5,.5),fixedrange=TRUE,gridcolor='#F0F3F5',zeroline=FALSE))
 dyn_clicks(p,'A',top$cross_platform_song_id)
}

dyn_scatter_plot<-function(window,attribute,order,selected=NULL){
 x<-dyn_scatter_data(window,attribute,order)
 colours<-ifelse(x$lead_lag_days>0,dyn_colours[['Douyin']],ifelse(x$lead_lag_days<0,dyn_colours[['Kugou']],'#BFB5C8'))
 if(!nrow(x))colours<-'#BFB5C8'
 maximum<-if(nrow(x))max(1,abs(x$lead_lag_days)) else 1
 p<-plotly::plot_ly(x=x$lead_lag_days,y=x$y,type='scatter',mode='markers',customdata=x$cross_platform_song_id,
  marker=list(size=8,color=colours,opacity=.82,line=list(color=mp_theme$ink,width=if(nrow(x))ifelse(x$cross_platform_song_id%in%selected,2,0)else 0)),
  text=paste0(dyn_hover(x),'<br>Category: ',x$label),hoverinfo='text',showlegend=FALSE)
 medians<-x%>%dplyr::group_by(label)%>%dplyr::summarise(median_gap=stats::median(lead_lag_days),.groups='drop')
 p<-plotly::add_trace(p,x=medians$median_gap,y=match(medians$label,order),type='scatter',mode='markers',inherit=FALSE,
  marker=list(symbol='line-ns',size=16,color=mp_theme$ink,line=list(color=mp_theme$ink,width=2)),
  text=paste0('Category: ',medians$label,'<br>Median first-observed gap: ',medians$median_gap,' days'),hoverinfo='text',showlegend=FALSE)
 p<-dyn_layout(p,margin=list(l=150,r=15,t=8,b=45),
  shapes=list(list(type='line',x0=0,x1=0,y0=.5,y1=6.5,line=list(color='#B8C4CB',dash='dot',width=1))),
  xaxis=list(title=list(text='Kugou first − Douyin first (days)',font=list(size=10)),range=c(-maximum*1.08,maximum*1.08),nticks=5,fixedrange=TRUE,zeroline=FALSE,gridcolor=mp_theme$grid),
  yaxis=list(title='',tickvals=1:6,ticktext=order,range=c(6.5,.5),fixedrange=TRUE,gridcolor=mp_theme$grid,zeroline=FALSE))
 dyn_clicks(p,'B')
}

dyn_cell_colour<-function(rate,platform){
 if(is.na(rate))return('#E8EDF0')
 if(rate==0)return('#F0F3F5')
 colours<-if(platform=='Douyin')c('#E8DCF1',dyn_colours[['Douyin']])else c('#FBEDD5',dyn_colours[['Kugou']])
 rgb<-as.double(grDevices::colorRamp(colours)(rate));grDevices::rgb(rgb[1],rgb[2],rgb[3],maxColorValue=255)
}

dyn_matrix_ui<-function(window,top,matrix,selected=NULL,previews=NULL){
 months<-window$months;m<-length(months)
 shiny::tags$div(class='dyn-matrix-content',`data-row-ids`=as.character(jsonlite::toJSON(top$cross_platform_song_id,na='null')),
  shiny::tags$table(class='dyn-monthly-table',style=paste0('min-width:',160+42*m+130,'px'),
   shiny::tags$colgroup(shiny::tags$col(style='width:160px'),lapply(seq_len(m),function(i)shiny::tags$col(style='width:42px')),shiny::tags$col(style='width:130px')),
   shiny::tags$thead(shiny::tags$tr(shiny::tags$th(class='dyn-song-cell','Song'),lapply(seq_len(m),function(j)
    shiny::tags$th(class='dyn-month-head',shiny::tags$span(format(months[j],'%b')),shiny::tags$small(format(months[j],'%Y')))),
    shiny::tags$th(class='dyn-lead-cell','First observed'))),
   shiny::tags$tbody(lapply(1:10,function(i){
    row<-top[i,];id<-row$cross_platform_song_id
    if(row$placeholder)return(shiny::tags$tr(class='dyn-table-row dyn-placeholder',`data-slot`=i,
      shiny::tags$th(class='dyn-song-cell',shiny::tags$span(paste0(i,'. No eligible song'))),shiny::tags$td(colspan=m,class='dyn-placeholder-band'),shiny::tags$td(class='dyn-lead-cell')))
    shiny::tags$tr(class=paste('dyn-table-row',if(length(selected)&&id%in%selected)'is-selected'else''),`data-candidate-id`=id,`data-slot`=i,
     shiny::tags$th(class='dyn-song-cell',shiny::tags$div(class='dyn-song-with-link',shiny::tags$button(type='button',class='dyn-row-select',`data-dyn-song`=id,title=row$song_title,paste0(i,'. ',row$song_title)),if(!is.null(previews))mp_kugou_link(previews,id))),
     lapply(seq_len(m),function(j){
      pair<-matrix[matrix$slot==i & matrix$month==months[j],]
      count_text<-function(p){x<-pair[pair$platform==p,];if(x$valid_archive_days==0L)'N/A (no valid archive)'else as.character(x$observed_days)}
      shiny::tags$td(class='dyn-month-cell',shiny::tags$div(class='dyn-cell-pair',lapply(c('Douyin','Kugou'),function(p){
       x<-pair[pair$platform==p,];tooltip<-paste0(dyn_hover(row),'<br>Month: ',format(months[j],'%Y-%m'),
        '<br>Douyin observed days: ',count_text('Douyin'),'<br>Kugou observed days: ',count_text('Kugou'),
        '<br>',p,' monthly intensity: ',if(is.na(x$intensity))'N/A'else sprintf('%.1f%%',100*x$intensity),'<br>Valid ',p,' archive days: ',x$valid_archive_days)
       shiny::tags$button(type='button',class=paste('dyn-month-block',if(is.na(x$intensity))'dyn-no-archive'else''),
        `data-dyn-song`=id,`data-dyn-month`=format(months[j],'%Y-%m'),`data-platform`=p,`data-intensity`=if(is.na(x$intensity))'NA'else x$intensity,
        `data-dyn-tooltip`=tooltip,`aria-label`=paste(row$song_title,format(months[j],'%Y-%m'),p),
        style=paste0('background:',dyn_cell_colour(x$intensity,p),';color:','#30193E'),
        if(nzchar(x$first_marker))shiny::tags$span(class='dyn-first-marker',x$first_marker))
      })))
     }),shiny::tags$td(class='dyn-lead-cell',dyn_lead_text(row)))
   }))))
}
if (!exists('mp_theme', inherits = TRUE)) mp_theme <- list(ink='#442158', muted='#705F7D', purple='#9475BE', grid='#EFEAF3', border='#EAE3EF', selected='#59316F', platform=c(Douyin='#9475BE',Kugou='#F2C987'), coobserved=c(yes='#A18ABB', no='#E8C483'))
