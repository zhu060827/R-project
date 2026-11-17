# Adapted from shiny4_handoff/app.R: paired full-archive first dates and later-first cohort months.
cmp_genres<-c('Pop','Rock','R&B / Soul','Hip Hop / Rap','Dance / Electronic','Other')
cmp_countries<-c('China','United States')
cmp_directions<-c('Short-video first','Streaming first','Same day')
cmp_first<-function(x)if(!length(x)||all(is.na(x)))as.Date(NA_character_)else min(x,na.rm=TRUE)
cmp_read<-function(p,spec){
 if(!file.exists(p))stop('Missing Page 4 input: ',p)
 x<-readr::read_csv(p,col_types=spec,na=c('','NA','\\N'),trim_ws=FALSE,show_col_types=FALSE)
 if(nrow(readr::problems(x)))stop('Page 4 CSV parsing problem: ',p)
 x
}
load_page4_data<-function(project,tables=NULL){
 if(!is.null(tables)){
  cncode<-tables$china_coding;cn<-tables$china_panel;uscode<-tables$us_coding;us<-tables$us_daily
 }else{
 root<-file.path(project,'outputs/shiny4_handoff/shiny4_handoff')
 cncode<-cmp_read(file.path(root,'data/processed/platform_song_coding.csv'),readr::cols_only(cross_platform_song_id=readr::col_character(),genre_harmonized=readr::col_character(),genre_platform_conflict=readr::col_logical()))
 cn<-cmp_read(file.path(root,'data/processed/platform_song_daily_panel.csv'),readr::cols_only(cross_platform_song_id=readr::col_character(),observation_date=readr::col_date(),douyin_observed=readr::col_integer(),kugou_observed=readr::col_integer()))
 uscode<-cmp_read(file.path(root,'data/reference/us_platform_clean/data_clean/coding_clean.csv'),readr::cols_only(track_id=readr::col_character(),group_id=readr::col_character(),pop=readr::col_integer(),rock=readr::col_integer(),rnb_soul=readr::col_integer(),hiphop_rap_trap=readr::col_integer(),dance=readr::col_integer(),Other=readr::col_integer()))
 us<-cmp_read(file.path(root,'data/reference/us_platform_clean/data_clean/daily_clean.csv'),readr::cols_only(group_id=readr::col_character(),date=readr::col_date(),tiktok_best_rank=readr::col_double(),spotify_best_rank=readr::col_double(),tiktok_source_available=readr::col_logical(),spotify_source_available=readr::col_logical()))
 }
 stopifnot(!anyDuplicated(cncode$cross_platform_song_id),!anyDuplicated(us[c('group_id','date')]),
  all(cn$douyin_observed%in%c(0L,1L)),all(cn$kugou_observed%in%c(0L,1L)),
  !any(!is.na(us$tiktok_best_rank)&!us$tiktok_source_available),!any(!is.na(us$spotify_best_rank)&!us$spotify_source_available))
 cn_dates<-cn%>%dplyr::group_by(cross_platform_song_id)%>%dplyr::summarise(short_date=cmp_first(observation_date[douyin_observed==1L]),stream_date=cmp_first(observation_date[kugou_observed==1L]),.groups='drop')%>%
  dplyr::left_join(cncode,by='cross_platform_song_id',relationship='one-to-one')%>%
  dplyr::transmute(country='China',source_candidate_id=cross_platform_song_id,genre_raw=genre_harmonized,short_date,stream_date,
    short_video='Douyin',streaming='Kugou',genre_conflict=genre_platform_conflict,genre_rule='supplied_china_harmonized_multi_label')
 # Keep the teammate's explicit indicator priority and first source-row representative.
 # A completely unencoded record is NA, not an invented Other. The two such source rows are outside the paired US sample.
 us_rows<-uscode%>%dplyr::mutate(source_row=dplyr::row_number(),flag_count=rowSums(as.matrix(dplyr::pick(pop,rock,rnb_soul,hiphop_rap_trap,dance,Other))==1L,na.rm=TRUE),
  genre=dplyr::case_when(pop==1L~'Pop',rock==1L~'Rock',rnb_soul==1L~'R&B / Soul',hiphop_rap_trap==1L~'Hip Hop / Rap',dance==1L~'Dance / Electronic',Other==1L~'Other',TRUE~NA_character_))
 us_genre<-us_rows%>%dplyr::group_by(group_id)%>%dplyr::summarise(genre_raw=dplyr::first(genre),representative_source_row=dplyr::first(source_row),
   representative_track_id=dplyr::first(track_id),genre_variants=dplyr::n_distinct(genre,na.rm=TRUE),multihot_source_rows=sum(flag_count>1L),.groups='drop')
 us_dates<-us%>%dplyr::group_by(group_id)%>%dplyr::summarise(short_date=cmp_first(date[!is.na(tiktok_best_rank)]),stream_date=cmp_first(date[!is.na(spotify_best_rank)]),.groups='drop')%>%
  dplyr::left_join(us_genre,by='group_id',relationship='one-to-one')%>%
  dplyr::transmute(country='United States',source_candidate_id=group_id,genre_raw,short_date,stream_date,short_video='TikTok',streaming='Spotify',
   genre_conflict=genre_variants>1L,genre_rule='supplied_flag_priority_then_first_source_row')
 periods<-dplyr::tibble(country=cmp_countries,start_date=as.Date(c('2024-11-14','2020-06-01')),end_date=as.Date(c('2026-11-13','2022-05-31')))
 stopifnot(identical(range(cn$observation_date),as.Date(c('2024-11-14','2026-11-13'))),
  identical(range(us$date),as.Date(c('2020-06-01','2022-05-31'))))
 all_dates<-dplyr::bind_rows(cn_dates,us_dates)
 events<-all_dates%>%dplyr::filter(!is.na(short_date),!is.na(stream_date))%>%
  dplyr::left_join(periods,by='country',relationship='many-to-one')%>%
  dplyr::mutate(candidate_id=paste0(ifelse(country=='China','CN::','US::'),source_candidate_id),
    lead_days=as.integer(stream_date-short_date),first_direction=dplyr::case_when(lead_days>0~cmp_directions[1],lead_days<0~cmp_directions[2],TRUE~cmp_directions[3]),
    first_platform=dplyr::case_when(lead_days>0~short_video,lead_days<0~streaming,TRUE~'Same day'),
    short_month=as.integer(lubridate::interval(start_date,short_date)%/%lubridate::period(1,units='month')+1L),
    stream_month=as.integer(lubridate::interval(start_date,stream_date)%/%lubridate::period(1,units='month')+1L),cohort_month=pmax(short_month,stream_month),
    genre_labels=lapply(genre_raw,function(z)if(is.na(z))character()else unique(trimws(strsplit(z,';',fixed=TRUE)[[1]]))))
 tokens<-unique(unlist(events$genre_labels));unmapped<-setdiff(tokens,cmp_genres)
 if(length(unmapped))stop('Unmapped supplied Page 4 Genre labels: ',paste(unmapped,collapse=', '))
 stopifnot(!anyDuplicated(events$candidate_id),all(events$cohort_month%in%1:24),all(events$short_date>=events$start_date&events$stream_date>=events$start_date))
 list(events=events,all_dates=all_dates,periods=periods,genre_levels=cmp_genres,max_month=24L,
  audit=list(china_coding_rows=nrow(cncode),china_coding_missing_genre=sum(is.na(cncode$genre_harmonized)),china_panel_rows=nrow(cn),china_unique_group_days=nrow(dplyr::distinct(cn,cross_platform_song_id,observation_date)),
    us_coding_rows=nrow(uscode),us_daily_rows=nrow(us),us_unknown_flag_rows=us_rows%>%dplyr::filter(flag_count==0L),
    us_genre_group_audit=us_genre,us_multihot_rows=sum(us_rows$flag_count>1L),
    us_paired_coding_rows=sum(us_rows$group_id%in%events$source_candidate_id[events$country=='United States']),
    us_paired_multihot_rows=sum(us_rows$flag_count>1L&us_rows$group_id%in%events$source_candidate_id[events$country=='United States']),unmapped_genres=unmapped))
}
cmp_markets<-function(country)if(country=='Compare both')cmp_countries else country
cmp_date_window<-function(data,country,months){
 p<-data$periods[data$periods$country==country,]
 a<-lubridate::add_with_rollback(p$start_date,lubridate::period(months[1]-1L,units='month'))
 b<-min(p$end_date,lubridate::add_with_rollback(p$start_date,lubridate::period(months[2],units='month'))-lubridate::days(1))
 paste(format(a,'%Y-%m-%d'),'–',format(b,'%Y-%m-%d'))
}
cmp_filter<-function(data,country='Compare both',genres=character(),first='All',months=c(1L,24L)){
 stopifnot(length(months)==2L,!anyNA(months),months[1]>=1,months[2]<=24,months[1]<=months[2])
 x<-data$events%>%dplyr::filter(cohort_month>=months[1],cohort_month<=months[2],.data$country%in%cmp_markets(.env$country))
 if(length(genres))x<-x%>%dplyr::filter(vapply(genre_labels,function(z)any(z%in%genres),logical(1)))
 if(first!='All')x<-x%>%dplyr::filter(first_direction==first)
 x
}
cmp_summaries<-function(x,markets=cmp_countries){
 country_counts<-x%>%dplyr::group_by(country)%>%dplyr::summarise(n=dplyr::n(),short=sum(lead_days>0),stream=sum(lead_days<0),same=sum(lead_days==0),unclassified=sum(lengths(genre_labels)==0L),.groups='drop')
 country_counts<-dplyr::tibble(country=cmp_countries)%>%dplyr::left_join(country_counts,by='country')%>%
  dplyr::mutate(dplyr::across(c(n,short,stream,same,unclassified),~tidyr::replace_na(.x,0L)),
   short_share=ifelse(n>0,short/pmax(n,1L),NA_real_),stream_share=ifelse(n>0,stream/pmax(n,1L),NA_real_),same_share=ifelse(n>0,same/pmax(n,1L),NA_real_))
 priority<-tidyr::expand_grid(country=markets,direction=cmp_directions)%>%
  dplyr::left_join(x%>%dplyr::count(country,direction=first_direction,name='count'),by=c('country','direction'))%>%
  dplyr::left_join(country_counts%>%dplyr::select(country,n),by='country')%>%dplyr::mutate(count=tidyr::replace_na(count,0L),share=ifelse(n>0,count/pmax(n,1L),NA_real_))
 trend_source<-x%>%dplyr::filter(first_direction!='Same day')%>%dplyr::mutate(calendar_month=lubridate::month(pmin(short_date,stream_date)))
 trend_denom<-trend_source%>%dplyr::count(country,name='denominator')
 trend_counts<-trend_source%>%dplyr::count(country,platform=first_platform,calendar_month,name='count')
 platform_pairs<-dplyr::tibble(country=rep(cmp_countries,each=2),platform=c('Douyin','Kugou','TikTok','Spotify'))%>%dplyr::filter(country%in%markets)
 trend<-tidyr::crossing(platform_pairs,calendar_month=1:12)%>%dplyr::left_join(trend_counts,by=c('country','platform','calendar_month'))%>%
  dplyr::left_join(trend_denom,by='country')%>%dplyr::mutate(count=tidyr::replace_na(count,0L),denominator=tidyr::replace_na(denominator,0L),share=ifelse(denominator>0,count/pmax(denominator,1L),NA_real_))
 long<-if(!nrow(x))dplyr::tibble(candidate_id=character(),country=character(),lead_days=integer(),genre=character())else
  x%>%dplyr::select(candidate_id,country,lead_days,genre=genre_labels)%>%tidyr::unnest_longer(genre,ptype=character())%>%dplyr::distinct(candidate_id,country,genre,.keep_all=TRUE)
 genre_summary<-if(!nrow(long))dplyr::tibble(country=character(),genre=character(),n=integer(),short=integer(),stream=integer(),same=integer(),median=double(),q1=double(),q3=double(),minimum=double(),maximum=double(),distinct_gaps=integer())else
  long%>%dplyr::group_by(country,genre)%>%dplyr::summarise(n=dplyr::n(),short=sum(lead_days>0),stream=sum(lead_days<0),same=sum(lead_days==0),
   median=stats::median(lead_days),q1=as.double(stats::quantile(lead_days,.25)),q3=as.double(stats::quantile(lead_days,.75)),minimum=min(lead_days),maximum=max(lead_days),distinct_gaps=dplyr::n_distinct(lead_days),.groups='drop')
 genre_summary<-tidyr::expand_grid(country=cmp_countries,genre=cmp_genres)%>%dplyr::left_join(genre_summary,by=c('country','genre'))%>%
  dplyr::mutate(dplyr::across(c(n,short,stream,same,distinct_gaps),~tidyr::replace_na(.x,0L)),
   short_share=ifelse(n>0,short/pmax(n,1L),NA_real_),stream_share=ifelse(n>0,stream/pmax(n,1L),NA_real_),same_share=ifelse(n>0,same/pmax(n,1L),NA_real_),
   net_priority=100*(short_share-stream_share),small_sample=n>0&n<5)
 list(events=x,countries=country_counts,priority=priority,trend=trend,genre_long=long,genre=genre_summary,markets=markets)
}
