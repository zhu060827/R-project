cmp_colours<-c('Short-video first'='#4F8985','Streaming first'='#537F94','Same day'='#B7C1C9',China='#537F94','United States'='#4F8985',Douyin='#537F94',Kugou='#4F8985',TikTok='#8D78A6',Spotify='#B18E68')
cmp_pct<-function(x)ifelse(is.na(x),'—',sprintf('%.1f%%',100*x))
cmp_genre_ticks<-c('Pop','Rock','R&B / Soul','Hip Hop / Rap','Dance /<br>Electronic','Other')
cmp_layout<-function(p,...){
 plotly::config(plotly::layout(p,font=list(family='system-ui, sans-serif',size=10,color='#243746'),
  paper_bgcolor='white',plot_bgcolor='white',showlegend=FALSE,hoverlabel=list(bgcolor='white',font=list(family='system-ui, sans-serif',size=11)),...),displayModeBar=FALSE,responsive=TRUE)
}
cmp_empty<-function(text='No data for the current filters'){
 cmp_layout(plotly::plot_ly(x=numeric(),y=numeric(),type='scatter',mode='markers',hoverinfo='skip'),
   xaxis=list(visible=FALSE),yaxis=list(visible=FALSE),annotations=list(list(x=.5,y=.5,xref='paper',yref='paper',text=text,showarrow=FALSE,font=list(color='#81909A',size=12))),margin=list(l=15,r=15,t=10,b=15))
}
cmp_priority_plot<-function(s){
 if(!nrow(s$events))return(cmp_empty())
 markets<-s$markets;p<-plotly::plot_ly()
 for(direction in cmp_directions){
  z<-s$priority[s$priority$direction==direction,];z<-z[match(markets,z$country),]
  z<-z[z$n>0L,]
  p<-plotly::add_trace(p,type='bar',orientation='h',x=z$share,y=match(z$country,markets),width=.43,
   marker=list(color=cmp_colours[[direction]],line=list(width=0)),name=direction,
   text=ifelse(!is.na(z$share)&z$share>=.08,cmp_pct(z$share),''),textposition='inside',insidetextanchor='middle',
   insidetextfont=list(color=if(direction=='Same day')'#354957'else'white',size=12),
   hovertext=paste0(z$country,'<br>',direction,'<br>Count: ',z$count,' / ',z$n,'<br>Share: ',cmp_pct(z$share)),hoverinfo='text',showlegend=FALSE)
 }
 ns<-s$countries$n[match(markets,s$countries$country)]
 notes<-lapply(which(ns==0L),function(i)list(x=.5,y=i,xref='x',yref='y',text='No data',showarrow=FALSE,font=list(color='#81909A',size=11)))
 cmp_layout(p,barmode='stack',bargap=.35,margin=list(l=103,r=14,t=12,b=38),
  annotations=notes,
  xaxis=list(title=list(text='Share of current filtered candidates',font=list(size=10)),range=c(0,1),tickformat='.0%',dtick=.25,fixedrange=TRUE,gridcolor='#EDF2F5',zeroline=FALSE),
  yaxis=list(title='',tickvals=seq_along(markets),ticktext=paste0(markets,'<br>n = ',ns),range=c(length(markets)+.6,.4),fixedrange=TRUE,showgrid=FALSE,zeroline=FALSE))
}
cmp_month_plot<-function(s){
 if(!any(s$trend$denominator>0))return(cmp_empty('No non–Same day candidates in the current filters'))
 p<-plotly::plot_ly();markets<-s$markets;two<-length(markets)==2L;annotations<-list()
 ymax<-max(.05,s$trend$share,na.rm=TRUE)*1.18
 layouts<-list()
 for(i in seq_along(markets)){
  country<-markets[i];suffix<-if(i==1L)''else as.character(i)
  xa<-paste0('x',suffix);ya<-paste0('y',suffix);domain<-if(!two)c(0,1)else if(i==1L)c(.61,1)else c(0,.39)
  z<-s$trend[s$trend$country==country,];denom<-unique(z$denominator)
  for(platform in unique(z$platform)){
   a<-z[z$platform==platform,]
   if(!any(a$denominator>0L))next
   p<-plotly::add_trace(p,x=a$calendar_month,y=a$share,type='scatter',mode='lines+markers',xaxis=xa,yaxis=ya,
    line=list(color=cmp_colours[[platform]],width=2),marker=list(color=cmp_colours[[platform]],size=5),
    text=paste0('Country: ',country,'<br>Platform: ',platform,'<br>Calendar month: ',month.name[a$calendar_month],
      '<br>Count: ',a$count,'<br>Country non–Same day n: ',a$denominator,'<br>Share: ',cmp_pct(a$share)),hoverinfo='text',name=platform,showlegend=FALSE)
  }
  layouts[[paste0('xaxis',suffix)]]<-list(domain=c(0,1),anchor=ya,range=c(.7,12.3),tickvals=1:12,ticktext=month.abb,
    tickfont=list(size=9),fixedrange=TRUE,showgrid=FALSE,zeroline=FALSE)
  layouts[[paste0('yaxis',suffix)]]<-list(domain=domain,anchor=xa,range=c(0,ymax),tickformat='.0%',nticks=3,fixedrange=TRUE,gridcolor='#EDF2F5',zeroline=FALSE)
  annotations[[length(annotations)+1L]]<-list(x=0,y=domain[2],xref='paper',yref='paper',xanchor='left',yanchor='bottom',
    text=paste0('<b>',country,'</b> · n = ',denom),showarrow=FALSE,font=list(size=10,color='#677B88'))
  if(!denom)annotations[[length(annotations)+1L]]<-list(x=.5,y=mean(domain),xref='paper',yref='paper',text='No data',showarrow=FALSE,font=list(color='#81909A'))
 }
 do.call(cmp_layout,c(list(p=p,margin=list(l=41,r=13,t=22,b=23),annotations=annotations),layouts))
}
cmp_violin_dodge<-function(){
 position<-ggplot2::position_dodge(width=.78)
 # Keep two country slots even when the other country is drawn as small-sample points.
 # Normal dodge would recenter a single violin. This is the same two-group dodge geometry,
 # reserving empty slots without adding fake observations or estimating a small-sample KDE.
 position$compute_panel<-function(data,params,scales){
  slot<-match(as.character(data$fill),cmp_countries)
  stopifnot(!anyNA(slot))
  width<-data$xmax-data$xmin
  data$x<-as.numeric(data$x)+params$width*((slot-.5)/2-.5)
  data$xmin<-data$x-width/4;data$xmax<-data$x+width/4
  data
 }
 position
}
cmp_violin_ggplot<-function(s){
 colours<-cmp_colours[cmp_countries]
 if(!nrow(s$genre_long))return(ggplot2::ggplot()+ggplot2::annotate('text',x=0,y=0,label='No classified candidates for the current filters',family='Segoe UI',size=3,color='#81909A')+ggplot2::theme_void()+ggplot2::theme(plot.background=ggplot2::element_rect(fill='white',colour=NA)))
 values<-s$genre_long%>%dplyr::left_join(s$genre%>%dplyr::select(country,genre,n,median,minimum,maximum),by=c('country','genre'),relationship='many-to-one')%>%
  dplyr::mutate(genre=factor(genre,levels=cmp_genres),country=factor(country,levels=cmp_countries),genre_x=as.integer(genre),
   country_x=genre_x+ifelse(country=='China',-.195,.195),
   hover=paste0('Country: ',country,'<br>Genre: ',genre,'<br>Valid sample n: ',n,'<br>Median gap: ',median,' days<br>Range: ',minimum,' to ',maximum,' days'))
 dense<-values%>%dplyr::filter(n>=5L)
 small<-values%>%dplyr::filter(n<5L)%>%dplyr::arrange(country,genre,candidate_id)%>%dplyr::group_by(country,genre)%>%
  dplyr::mutate(point_x=country_x+if(dplyr::n()>1L)seq(-.045,.045,length.out=dplyr::n())else 0)%>%dplyr::ungroup()
 # Same kernel, bandwidth, trim and area scaling as the teammate's geom_violin expression.
 g<-ggplot2::ggplot(values,ggplot2::aes(x=genre_x,y=lead_days,fill=country,colour=country,group=interaction(country,genre),text=hover))+
  ggplot2::geom_hline(yintercept=0,colour='#A6B5BE',linetype='dotted',linewidth=.35)+
  ggplot2::geom_violin(data=dense,position=cmp_violin_dodge(),alpha=.62,trim=FALSE,width=.72,scale='area',bw='nrd0',adjust=1,linewidth=.3)+
  ggplot2::geom_point(data=small,ggplot2::aes(x=point_x),size=1.5,alpha=.85)+
  ggplot2::scale_fill_manual(values=colours,drop=FALSE)+ggplot2::scale_colour_manual(values=colours,drop=FALSE)+
  ggplot2::scale_x_continuous(breaks=1:6,labels=gsub('<br>','\n',cmp_genre_ticks,fixed=TRUE),limits=c(.5,6.5),expand=ggplot2::expansion(mult=0))+
  ggplot2::scale_y_continuous(expand=ggplot2::expansion(mult=.06))+
  ggplot2::labs(x=NULL,y='First-observed gap (days)')+
  ggplot2::theme_minimal(base_size=8,base_family='Segoe UI')+
  ggplot2::theme(legend.position='none',panel.grid.major.x=ggplot2::element_blank(),panel.grid.minor=ggplot2::element_blank(),
   panel.grid.major.y=ggplot2::element_line(colour='#EDF2F5',linewidth=.3),plot.background=ggplot2::element_rect(fill='white',colour=NA),
   axis.text=ggplot2::element_text(size=7,colour='#243746'),axis.title.y=ggplot2::element_text(size=8,margin=ggplot2::margin(r=5)),
   plot.margin=ggplot2::margin(t=5,r=8,b=4,l=5))
 g
}
cmp_violin_plot<-function(s){
 # Native ggplot rendering preserves the dodged widths; this Plotly version widens them.
 cmp_violin_ggplot(s)
}
cmp_genre_hover<-function(a){
 paste0('Country: ',a$country,'<br>Genre: ',a$genre,'<br>Valid sample n: ',a$n,
  ifelse(a$n>0,paste0('<br>Short-video first: ',a$short,' (',cmp_pct(a$short_share),')',
    '<br>Streaming first: ',a$stream,' (',cmp_pct(a$stream_share),')','<br>Same day: ',a$same,' (',cmp_pct(a$same_share),')',
    '<br>Net Priority: ',sprintf('%+.1f pp',a$net_priority)),'<br>No data'),
  ifelse(a$small_sample,'<br>Small sample — interpret cautiously',''))
}
cmp_diverging_plot<-function(s){
 p<-plotly::plot_ly();axes<-list();annotations<-list();shapes<-list()
 if(!any(s$genre$n>0L))p<-plotly::add_trace(p,type='scatter',mode='markers',x=numeric(),y=numeric(),hoverinfo='skip',showlegend=FALSE)
 for(i in 1:2){
  country<-cmp_countries[i];a<-s$genre[s$genre$country==country,];a<-a[match(cmp_genres,a$genre),]
  suffix<-if(i==1L)''else'2';xa<-paste0('x',suffix);ya<-paste0('y',suffix);domain<-if(i==1L)c(0,.43)else c(.57,1)
  valid<-a$n>0L;hover<-cmp_genre_hover(a);net<-a$net_priority
  if(any(valid)){
   p<-plotly::add_trace(p,type='bar',orientation='h',x=net[valid],y=which(valid),base=0,width=.48,xaxis=xa,yaxis=ya,
    marker=list(color=ifelse(net[valid]>=0,cmp_colours[['Short-video first']],cmp_colours[['Streaming first']]),
     opacity=ifelse(a$small_sample[valid],.38,.9),line=list(width=0)),text=hover[valid],textposition='none',hoverinfo='text',showlegend=FALSE)
   zero<-which(valid&net==0)
   if(length(zero))p<-plotly::add_trace(p,type='scatter',mode='markers',x=rep(0,length(zero)),y=zero,xaxis=xa,yaxis=ya,
      marker=list(symbol='diamond',size=6,color='#677B88'),text=hover[zero],hoverinfo='text',showlegend=FALSE)
   # A transparent full-row target exposes summaries even for a zero or a short bar.
   p<-plotly::add_trace(p,type='scatter',mode='markers',x=rep(0,sum(valid)),y=which(valid),xaxis=xa,yaxis=ya,
     marker=list(size=14,color='rgba(0,0,0,0)'),text=hover[valid],hoverinfo='text',showlegend=FALSE)
  }
  for(j in 1:6){
   label<-if(!valid[j])'No data'else sprintf('%+.0f pp',abs(net[j]))
   # Put text beyond short bars; for long bars place it inside the fixed ±100 pp frame.
   v<-if(!valid[j])0 else if(abs(net[j])>63)net[j]-sign(net[j])*5 else net[j]+if(net[j]<0)-5 else 5
   anchor<-if(!valid[j])'center'else if(abs(net[j])>63)if(net[j]<0)'left'else'right'else if(net[j]<0)'right'else'left'
   annotations[[length(annotations)+1L]]<-list(x=v,y=j-.08,xref=xa,yref=ya,text=label,showarrow=FALSE,xanchor=anchor,
    font=list(size=10,color=if(valid[j]&&abs(net[j])>63&&!a$small_sample[j])'white'else'#354957'))
   if(valid[j])annotations[[length(annotations)+1L]]<-list(x=0,y=j+.31,xref=xa,yref=ya,text=paste0('n=',a$n[j],if(a$small_sample[j])' · small'else''),showarrow=FALSE,font=list(size=8,color='#81909A'))
  }
  annotations[[length(annotations)+1L]]<-list(x=mean(domain),y=1.1,xref='paper',yref='paper',text=paste0('<b>',country,'</b>'),showarrow=FALSE,font=list(size=11))
  axes[[paste0('xaxis',suffix)]]<-list(domain=domain,anchor=ya,range=c(-100,100),tickvals=c(-100,-50,0,50,100),ticktext=c('−100','−50','0 pp','+50','+100'),tickfont=list(size=9),fixedrange=TRUE,gridcolor='#EDF2F5',zeroline=FALSE)
  axes[[paste0('yaxis',suffix)]]<-list(domain=c(0,1),anchor=xa,range=c(6.6,.4),tickvals=1:6,ticktext=if(i==1L)cmp_genre_ticks else rep('',6),fixedrange=TRUE,showgrid=FALSE,zeroline=FALSE)
  shapes[[i]]<-list(type='line',x0=0,x1=0,y0=.5,y1=6.5,xref=xa,yref=ya,line=list(color='#A6B5BE',width=1))
 }
 do.call(cmp_layout,c(list(p=p,margin=list(l=102,r=16,t=31,b=25),annotations=annotations,shapes=shapes,barmode='overlay'),axes))
}
