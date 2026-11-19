# Six existing CSV tables under exactly two existing source roots; no persistent derived data.
direct_read<-function(path,spec){
 x<-readr::read_csv(path,col_types=spec,na=c('','NA','\\N'),trim_ws=FALSE,locale=readr::locale(tz='Asia/Shanghai'),show_col_types=FALSE)
 if(nrow(readr::problems(x)))stop('Direct source parse problem: ',path)
 x
}
direct_unique_panel<-function(panel){
 metrics<-c('douyin_rank','kugou_rank')
 out<-panel%>%dplyr::group_by(cross_platform_song_id,observation_date)%>%dplyr::summarise(
  douyin_observed=as.integer(any(douyin_observed==1L)),kugou_observed=as.integer(any(kugou_observed==1L)),
  dplyr::across(dplyr::all_of(metrics),function(v){u<-unique(v[!is.na(v)]);if(length(u)>1L)stop('Conflicting candidate-date position; direct migration stopped.');if(length(u))u[1]else NA_real_}),.groups='drop')
 out%>%dplyr::select(cross_platform_song_id,observation_date,douyin_observed,kugou_observed,douyin_rank,kugou_rank)
}
direct_memberships<-function(coding){
 all<-dplyr::bind_rows(lapply(c('douyin','kugou'),function(platform){
  field<-paste0(platform,'_record_ids')
  coding%>%dplyr::select(cross_platform_song_id,native_record_id=dplyr::all_of(field))%>%dplyr::filter(!is.na(native_record_id))%>%
   dplyr::mutate(native_record_id=lapply(native_record_id,function(z)trimws(strsplit(z,'|',fixed=TRUE)[[1]])))%>%tidyr::unnest_longer(native_record_id)%>%
   dplyr::mutate(platform=platform,platform_native_id=sub('^(DO_|KU_)','',native_record_id))
 }))%>%dplyr::distinct()
 stopifnot(all(grepl('^(DO_|KU_)[0-9]+$',all$native_record_id)))
 all%>%dplyr::group_by(platform,native_record_id)%>%dplyr::mutate(candidate_id_count=dplyr::n_distinct(cross_platform_song_id))%>%dplyr::ungroup()
}
load_direct_dashboard_data<-function(project,app_dir){
 # The submission package reuses the processed-data package one level above it.
 # This keeps large analytical CSVs out of the Shiny source package while
 # preserving the same six-table application interface.
 data_root <- normalizePath(file.path(app_dir, '..', 'data_submission', 'data', 'processed'), winslash='/', mustWork=TRUE)
 cn<-data_root;us<-file.path(data_root,'us')
 coding<-direct_read(file.path(cn,'platform_song_coding.csv'),readr::cols(.default=readr::col_character(),genre_platform_conflict=readr::col_logical()))
 panel<-direct_read(file.path(cn,'platform_song_daily_panel.csv'),readr::cols_only(cross_platform_song_id=readr::col_character(),observation_date=readr::col_date(),douyin_observed=readr::col_integer(),kugou_observed=readr::col_integer(),douyin_rank=readr::col_double(),kugou_rank=readr::col_double()))
 dn<-direct_read(file.path(cn,'douyin_master_dataset.csv'),readr::cols_only(douyin_music_id=readr::col_character(),observation_date=readr::col_date(),response_time=readr::col_datetime(),title_raw=readr::col_character(),genre_raw=readr::col_character(),mood_raw=readr::col_character(),duration_raw=readr::col_double(),duration_unit=readr::col_character(),is_recovered_snapshot=readr::col_logical(),archive_date=readr::col_date(),source_status_code=readr::col_character(),usable_for_snapshot_description=readr::col_logical(),original_calendar_selected_files=readr::col_integer()))
 k<-direct_read(file.path(cn,'kugou_analysis_dataset.csv'),readr::cols_only(kugou_song_id=readr::col_character(),chart_date=readr::col_date(),track_name=readr::col_character(),genre_category=readr::col_character(),mood_category=readr::col_character(),duration_ms=readr::col_double(),coding_method=readr::col_character(),taxonomy_source=readr::col_character(),taxonomy_method=readr::col_character(),taxonomy_review_required=readr::col_character()))
 uc<-direct_read(file.path(us,'coding_clean.csv'),readr::cols_only(track_id=readr::col_character(),group_id=readr::col_character(),pop=readr::col_integer(),rock=readr::col_integer(),rnb_soul=readr::col_integer(),hiphop_rap_trap=readr::col_integer(),dance=readr::col_integer(),Other=readr::col_integer()))
 ud<-direct_read(file.path(us,'daily_clean.csv'),readr::cols_only(group_id=readr::col_character(),date=readr::col_date(),tiktok_best_rank=readr::col_double(),spotify_best_rank=readr::col_double(),tiktok_source_available=readr::col_logical(),spotify_source_available=readr::col_logical()))
 stopifnot(!anyDuplicated(coding$cross_platform_song_id),!anyDuplicated(dn[c('douyin_music_id','observation_date')]),!anyDuplicated(k[c('kugou_song_id','chart_date')]),
  all(panel$douyin_observed%in%0:1),all(panel$kugou_observed%in%0:1),all(dn$duration_unit=='unverified_source_unit'))
 daily<-direct_unique_panel(panel)
 dc<-stringr::str_detect(coding$platforms,stringr::fixed('douyin'));kc<-stringr::str_detect(coding$platforms,stringr::fixed('kugou'))
 candidates<-coding%>%dplyr::filter(dc&kc)%>%dplyr::select(cross_platform_song_id,song_title)%>%dplyr::mutate(song_title=trimws(song_title))%>%dplyr::arrange(cross_platform_song_id)
 core_names<-c('cross_platform_song_id','song_title_key','song_title','platforms','platform_count','record_count','first_observed_date','last_observed_date','both_platforms','douyin_record_ids','kugou_record_ids','match_method','match_status','manual_review_required')
 coverage<-c(douyin_only=sum(dc&!kc),kugou_only=sum(kc&!dc),shared=sum(dc&kc));bounds<-range(daily$observation_date)
 core_coding<-coding%>%dplyr::select(dplyr::all_of(core_names))%>%dplyr::mutate(song_title=trimws(song_title))
 overview<-list(coding=core_coding,daily=daily,candidates=candidates,coverage=coverage,bounds=bounds,
  kpis=c(song_candidates=nrow(coding),shared_candidates=nrow(candidates),calendar_days=as.integer(diff(bounds))+1L),douyin_position_label='Douyin Provided Position (unverified)',douyin_axis_label='Douyin Average Provided Position (unverified)')
 stopifnot(nrow(daily)==69350L,nrow(candidates)==95L,identical(as.integer(coverage),c(400L,2073L,95L)))
 # Original calendar version: recovered observations stay in Page2; they do not backfill Page3's old denominator.
 calendars<-dplyr::bind_rows(dn%>%dplyr::filter(source_status_code=='0',usable_for_snapshot_description,original_calendar_selected_files>0L,!is_recovered_snapshot)%>%dplyr::transmute(platform='Douyin',date=archive_date),
  dplyr::tibble(platform='Kugou',date=sort(unique(k$chart_date))))%>%dplyr::distinct()%>%dplyr::arrange(platform,date)
 d<-dn%>%dplyr::select(douyin_music_id,observation_date,response_time,title_raw,genre_raw,mood_raw,duration_raw,duration_unit,is_recovered_snapshot)%>%
  dplyr::mutate(unit_id=douyin_music_id,genre_tags=decode_feature_tags(genre_raw),mood_tags=decode_feature_tags(mood_raw))
 k<-k%>%dplyr::mutate(unit_id=kugou_song_id,observation_date=chart_date,genre_tags=lapply(genre_category,function(z)if(is.na(z))character()else z),mood_tags=lapply(mood_category,function(z)if(is.na(z))character()else z))
 category_env<-new.env(parent=environment());sys.source(file.path(app_dir,'R/page2_category_mapping.R'),envir=category_env)
 mapping<-category_env$page2_team_mapping()
 cache<-function(x){for(a in c('genre','mood')){lookup<-mapping[[paste0(a,'_map')]];x[[paste0(a,'_unified_tags')]]<-lapply(x[[paste0(a,'_tags')]],function(z)unique(unname(lookup[z])[!is.na(unname(lookup[z]))]))};x}
 inventory<-dplyr::bind_rows(dplyr::tibble(platform='Douyin',attribute='Genre',source_label=sort(unique(unlist(d$genre_tags)))),dplyr::tibble(platform='Douyin',attribute='Mood',source_label=sort(unique(unlist(d$mood_tags)))),dplyr::tibble(platform='Kugou',attribute='Genre',source_label=sort(unique(unlist(k$genre_tags)))),dplyr::tibble(platform='Kugou',attribute='Mood',source_label=sort(unique(unlist(k$mood_tags)))))
 features<-list(douyin=cache(d),kugou=cache(k),inventory=inventory,mapping=mapping,genres=mapping$genre_order,moods=mapping$mood_order,genre_order=mapping$genre_order,mood_order=mapping$mood_order)
 features$unmapped<-inventory%>%dplyr::filter((attribute=='Genre'&!source_label%in%names(mapping$genre_map))|(attribute=='Mood'&!source_label%in%names(mapping$mood_map)))
 features$keywords<-category_env$page2_team_keywords()
 memberships<-direct_memberships(coding)%>%dplyr::filter(cross_platform_song_id%in%candidates$cross_platform_song_id)
 links<-memberships%>%dplyr::filter(candidate_id_count==1L)%>%dplyr::transmute(platform=ifelse(platform=='douyin','Douyin','Kugou'),unit_id=platform_native_id,cross_platform_song_id)%>%dplyr::distinct()
 stopifnot(!anyDuplicated(links[c('platform','unit_id')]),all(daily$observation_date[daily$douyin_observed==1L]%in%calendars$date[calendars$platform=='Douyin']))
 dynamics<-list(daily=daily%>%dplyr::select(cross_platform_song_id,observation_date,douyin_observed,kugou_observed),candidates=candidates,calendars=calendars,links=links,features=features,
  genre_order=c('Pop','Rock','R&B / Soul','Hip Hop / Rap','Dance / Electronic','Other'),mood_order=features$mood_order,raw_rows=nrow(panel),excluded_ambiguous_links=memberships%>%dplyr::filter(candidate_id_count>1L))
 comparison<-load_page4_data(project,tables=list(china_coding=coding,china_panel=panel,us_coding=uc,us_daily=ud))
 result<-list(data=overview,features=features,dynamics=dynamics,comparison=comparison)
 attr(result,'source_info')<-list(mode='direct',roots=c(cn,us),files=c(file.path(cn,c('platform_song_coding.csv','platform_song_daily_panel.csv','douyin_master_dataset.csv','kugou_analysis_dataset.csv')),file.path(us,c('coding_clean.csv','daily_clean.csv'))))
 message('MusicPulse data mode: direct; six existing CSV tables in two source roots loaded once; no RDS input.')
 result
}
