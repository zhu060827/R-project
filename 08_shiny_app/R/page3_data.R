# Popularity Dynamics: unique candidate-day flags; independently available archive days.
load_page3_data <- function(project,overview,features) {
  raw <- readr::read_csv(file.path(project,'platform_song_daily_panel.csv'),
    col_types=readr::cols_only(cross_platform_song_id=readr::col_character(),observation_date=readr::col_date(),
      douyin_observed=readr::col_integer(),kugou_observed=readr::col_integer()),show_col_types=FALSE)
  flags <- raw %>% dplyr::group_by(cross_platform_song_id,observation_date) %>%
    dplyr::summarise(douyin_observed=as.integer(any(douyin_observed==1L,na.rm=TRUE)),
      kugou_observed=as.integer(any(kugou_observed==1L,na.rm=TRUE)),.groups='drop')
  idx<-match(paste(overview$daily$cross_platform_song_id,overview$daily$observation_date),paste(flags$cross_platform_song_id,flags$observation_date))
  stopifnot(nrow(flags)==69350L,!anyNA(idx),identical(flags$douyin_observed[idx],overview$daily$douyin_observed),
    identical(flags$kugou_observed[idx],overview$daily$kugou_observed))
  # Use the original calendar version of the panel; its recovered 12-11 snapshot is NOT in this panel.
  snap <- readr::read_csv(file.path(project,'outputs/musicpulse_eda/data/douyin_snapshots.csv'),
    col_types=readr::cols_only(archive_date=readr::col_date(),source_status_code=readr::col_character(),
      usable_for_snapshot_description=readr::col_logical()),show_col_types=FALSE)
  calendars<-dplyr::bind_rows(
    snap %>% dplyr::filter(source_status_code=='0',usable_for_snapshot_description) %>% dplyr::transmute(platform='Douyin',date=archive_date),
    dplyr::tibble(platform='Kugou',date=sort(unique(features$kugou$observation_date)))) %>% dplyr::distinct()
  stopifnot(all(flags$observation_date[flags$douyin_observed==1L]%in%calendars$date[calendars$platform=='Douyin']),
    all(flags$observation_date[flags$kugou_observed==1L]%in%calendars$date[calendars$platform=='Kugou']))
  mapping<-readr::read_csv(file.path(project,'outputs/musicpulse_team_handoff/data/cross_platform/native_candidate_mapping.csv'),
    col_types=readr::cols(.default=readr::col_character(),candidate_id_count=readr::col_integer()),show_col_types=FALSE) %>%
    dplyr::filter(cross_platform_song_id%in%overview$candidates$cross_platform_song_id)
  links<-mapping %>% dplyr::filter(candidate_id_count==1L) %>%
    dplyr::transmute(platform=ifelse(platform=='douyin','Douyin','Kugou'),unit_id=platform_native_id,cross_platform_song_id) %>% dplyr::distinct()
  stopifnot(!anyDuplicated(links[c('platform','unit_id')]))
  list(daily=flags,candidates=overview$candidates,calendars=calendars,links=links,features=features,
    genre_order=c('Pop','Rock','R&B / Soul','Hip Hop / Rap','Dance / Electronic','Other'),mood_order=features$mood_order,
    raw_rows=nrow(raw),excluded_ambiguous_links=mapping%>%dplyr::filter(candidate_id_count>1L))
}

dyn_first <- function(x) if(length(x)) min(x) else as.Date(NA_character_)
dyn_direction <- function(gap) dplyr::case_when(is.na(gap)~'Insufficient dual-platform data',gap>0~'Douyin earlier',gap<0~'Kugou earlier',TRUE~'Same day')
dyn_window <- function(data,dates) {
  dates<-as.Date(dates);stopifnot(length(dates)==2L,!anyNA(dates),dates[1]<=dates[2])
  daily<-data$daily %>% dplyr::filter(observation_date>=dates[1],observation_date<=dates[2])
  counts<-daily %>% dplyr::group_by(cross_platform_song_id) %>% dplyr::summarise(
    douyin_days=sum(douyin_observed==1L),kugou_days=sum(kugou_observed==1L),
    union_days=sum(douyin_observed==1L|kugou_observed==1L),same_day_days=sum(douyin_observed==1L&kugou_observed==1L),
    douyin_first=dyn_first(observation_date[douyin_observed==1L]),kugou_first=dyn_first(observation_date[kugou_observed==1L]),.groups='drop')
  stats<-data$candidates %>% dplyr::left_join(counts,by='cross_platform_song_id',relationship='one-to-one') %>%
    dplyr::mutate(dplyr::across(c(douyin_days,kugou_days,union_days,same_day_days),~tidyr::replace_na(.x,0L)),
      lead_lag_days=as.integer(kugou_first-douyin_first),absolute_gap=abs(lead_lag_days),lead_direction=dyn_direction(lead_lag_days))
  calendars<-data$calendars %>% dplyr::filter(date>=dates[1],date<=dates[2])
  labels<-dplyr::bind_rows(lapply(c('Douyin','Kugou'),function(p){
    x<-data$features[[tolower(p)]] %>% dplyr::filter(observation_date%in%calendars$date[calendars$platform==p])
    x<-page2_latest_units(x,dates) %>% dplyr::mutate(platform=p) %>%
      dplyr::inner_join(data$links,by=c('platform','unit_id'),relationship='one-to-one')
    if(!nrow(x))return(dplyr::tibble(cross_platform_song_id=character(),attribute=character(),label=character()))
    dplyr::bind_rows(lapply(c('Genre','Mood'),function(a){
      lookup<-if(a=='Genre')data$features$mapping$genre_map else data$features$mapping$mood_map
      dplyr::tibble(cross_platform_song_id=x$cross_platform_song_id,source_platform=p,attribute=a,
        label=if(paste0(tolower(a),'_unified_tags')%in%names(x))x[[paste0(tolower(a),'_unified_tags')]]else lapply(x[[paste0(tolower(a),'_tags')]],function(tags)unique(stats::na.omit(unname(lookup[tags]))))) %>% tidyr::unnest_longer(label,ptype=character())
    }))
  })) %>% dplyr::distinct(cross_platform_song_id,attribute,label)
  # Actual visible runs: absent or missing dates break the segment; never bridge gaps.
  positives<-daily %>% tidyr::pivot_longer(c(douyin_observed,kugou_observed),names_to='platform',values_to='observed') %>%
    dplyr::filter(observed==1L) %>% dplyr::mutate(platform=ifelse(platform=='douyin_observed','Douyin','Kugou')) %>%
    dplyr::arrange(cross_platform_song_id,platform,observation_date)
  runs<-positives %>% dplyr::group_by(cross_platform_song_id,platform) %>%
    dplyr::mutate(run=cumsum(is.na(dplyr::lag(observation_date))|observation_date!=dplyr::lag(observation_date)+1L)) %>%
    dplyr::group_by(cross_platform_song_id,platform,run) %>%
    dplyr::summarise(start=min(observation_date),end=max(observation_date),observed_days=dplyr::n(),.groups='drop')
  list(dates=dates,daily=daily,stats=stats,labels=labels,positives=positives,runs=runs,calendars=calendars,
    months=seq(lubridate::floor_date(dates[1],'month'),lubridate::floor_date(dates[2],'month'),by='month'))
}

dyn_top10 <- function(window,category='All Songs',label=NULL,sort_by='union') {
  eligible<-window$stats %>% dplyr::filter(union_days>0L)
  if(category!='All Songs') eligible<-eligible %>% dplyr::semi_join(window$labels %>% dplyr::filter(attribute==category,.data$label%in%.env$label),by='cross_platform_song_id')
  metric<-switch(sort_by,union='union_days',overlap='same_day_days',gap='absolute_gap',douyin='douyin_days',kugou='kugou_days',stop('Unknown sort'))
  if(sort_by=='gap')eligible<-eligible%>%dplyr::filter(!is.na(absolute_gap))
  eligible<-eligible%>%dplyr::arrange(dplyr::desc(.data[[metric]]),dplyr::desc(union_days),cross_platform_song_id)%>%dplyr::slice_head(n=10L)
  dplyr::tibble(slot=1:10)%>%dplyr::left_join(eligible%>%dplyr::mutate(slot=dplyr::row_number()),by='slot')%>%dplyr::mutate(placeholder=is.na(cross_platform_song_id))
}

dyn_matrix <- function(window,top) {
  denom<-window$calendars %>% dplyr::mutate(month=lubridate::floor_date(date,'month')) %>%
    dplyr::count(platform,month,name='valid_archive_days')
  observed<-window$positives%>%dplyr::mutate(month=lubridate::floor_date(observation_date,'month'))%>%
    dplyr::count(cross_platform_song_id,platform,month,name='observed_days')
  tidyr::expand_grid(slot=top$slot,platform=c('Douyin','Kugou'),month=window$months)%>%
    dplyr::left_join(top,by='slot',relationship='many-to-one')%>%
    dplyr::left_join(denom,by=c('platform','month'),relationship='many-to-one')%>%
    dplyr::left_join(observed,by=c('cross_platform_song_id','platform','month'),relationship='one-to-one')%>%
    dplyr::mutate(valid_archive_days=tidyr::replace_na(valid_archive_days,0L),
      observed_days=ifelse(placeholder,NA_integer_,tidyr::replace_na(observed_days,0L)),
      intensity=ifelse(placeholder|valid_archive_days==0L,NA_real_,observed_days/pmax(valid_archive_days,1L)),
      first_marker=dplyr::case_when(placeholder|is.na(lead_lag_days)~'',
        lead_lag_days>0 & platform=='Douyin' & month==lubridate::floor_date(douyin_first,'month')~'D',
        lead_lag_days<0 & platform=='Kugou' & month==lubridate::floor_date(kugou_first,'month')~'K',
        lead_lag_days==0 & ((platform=='Douyin' & month==lubridate::floor_date(douyin_first,'month'))|
          (platform=='Kugou' & month==lubridate::floor_date(kugou_first,'month')))~'=',TRUE~''))
}

dyn_scatter_data <- function(window,attribute,order) {
  window$labels %>% dplyr::filter(.data$attribute==.env$attribute) %>% dplyr::inner_join(window$stats,by='cross_platform_song_id',relationship='many-to-one') %>%
    dplyr::filter(!is.na(lead_lag_days)) %>% dplyr::arrange(label,cross_platform_song_id) %>% dplyr::group_by(label) %>%
    dplyr::mutate(y=match(label,order)+(dplyr::row_number()%%7L-3L)*.045) %>% dplyr::ungroup()
}
