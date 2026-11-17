# Application-level read-only data. Current default reads the two supplied source roots directly.
# Legacy and the previous RDS trial remain explicit recovery modes only.
load_dashboard_data<-function(project,app_dir,mode=Sys.getenv('MUSICPULSE_DATA_MODE','direct')){
 if(!mode%in%c('legacy','rds','direct'))stop('MUSICPULSE_DATA_MODE must be direct, legacy or rds.')
 if(mode=='direct'){
  source(file.path(app_dir,'R/direct_data.R'),local=TRUE)
  return(load_direct_dashboard_data(project,app_dir))
 }
 if(mode=='legacy'){
  overview<-load_page1_data(project);features<-load_page2_data(project,app_dir)
  result<-list(data=overview,features=features,dynamics=load_page3_data(project,overview,features),comparison=load_page4_data(project))
  attr(result,'source_info')<-list(mode='legacy');message('MusicPulse data mode: legacy');return(result)
 }
 source(file.path(project,'scripts/dashboard_paths.R'),local=TRUE);paths<-dashboard_paths(project)
 if(!file.exists(paths$pointer))stop('RDS release is missing. Run scripts/build_dashboard_data.R, or set MUSICPULSE_DATA_MODE=legacy.')
 manifest<-readRDS(paths$pointer)
 if(!identical(manifest$schema,'MusicPulseDashboard/1')||!identical(names(manifest$modules),c('douyin','kugou','cross_platform','us_platform_clean')))stop('Unsupported dashboard manifest; legacy files were not changed.')
 modules<-lapply(manifest$modules,function(m){
  path<-file.path(project,m$path)
  if(!file.exists(path)||!identical(digest::digest(file=path,algo='sha256'),m$sha256))stop('Missing or damaged dashboard module: ',m$path)
  x<-readRDS(path);if(!identical(x$schema,manifest$schema))stop('Module schema mismatch: ',m$path);x
 })
 d<-modules$douyin;k<-modules$kugou;cn<-modules$cross_platform;us<-modules$us_platform_clean
 features<-c(list(douyin=d$features,kugou=k$features),cn$feature_config)
 dynamics<-append(cn$dynamics,list(features=features),after=4L)
 a<-cn$comparison;b<-us$comparison;audit<-c(a$audit,b$audit);audit<-audit[a$audit_order]
 comparison<-list(events=dplyr::bind_rows(a$events,b$events),all_dates=dplyr::bind_rows(a$all_dates,b$all_dates),periods=dplyr::bind_rows(a$periods,b$periods),genre_levels=a$genre_levels,max_month=a$max_month,audit=audit)
 stopifnot(nrow(cn$overview$daily)==69350L,!anyDuplicated(cn$overview$daily[c('cross_platform_song_id','observation_date')]),nrow(comparison$events)==163L,
  identical(as.integer(table(factor(comparison$events$country,levels=c('China','United States')))),c(95L,68L)),
  inherits(d$observations$observation_date,'Date'),inherits(k$observations$chart_date,'Date'),is.character(d$observations$douyin_music_id),is.character(k$observations$kugou_song_id),is.character(us$coding$track_id))
 result<-list(data=cn$overview,features=features,dynamics=dynamics,comparison=comparison)
 attr(result,'source_info')<-list(mode='rds',release=manifest$release,modules=manifest$modules)
 message('MusicPulse data mode: rds; release ',manifest$release,'; four modules loaded once.')
 result
}
