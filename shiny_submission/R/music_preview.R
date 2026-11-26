# Optional, application-level source registry. Historical play_url is never a fallback.
load_music_previews <- function(project,candidate_ids) {
  paths<-file.path(project,'data/music_preview_research',c('page1_audio_previews.csv','page3_kugou_links.csv'))
  if(!all(file.exists(paths)))stop('Independent Page 1 audio and Page 3 KuGou registries are required.')
  read_registry<-function(path)readr::read_csv(path,col_types=readr::cols(.default=readr::col_character()),na=c('','NA'),show_col_types=FALSE)
  audio<-read_registry(paths[1]);links<-read_registry(paths[2])
  stopifnot(!anyDuplicated(audio$candidate_id),!anyDuplicated(links$candidate_id),
    setequal(audio$candidate_id,candidate_ids),setequal(links$candidate_id,candidate_ids))
  # Join only display/link fields. A verified KuGou link never supplies an audio-ready flag.
  x<-dplyr::left_join(audio,links%>%dplyr::select(candidate_id,kugou_song_id,kugou_song_url,kugou_link_status,kugou_page_artist,kugou_page_title),by='candidate_id')
  required<-c('candidate_id','song_title','artist','preview_type','preview_source_verified','usage_permission','permission_evidence_url','preview_url','local_audio_path','local_audio_sha256','embed_permission_verified','kugou_song_url','kugou_link_status','kugou_page_artist','kugou_page_title')
  stopifnot(all(required%in%names(x)),!anyDuplicated(x$candidate_id),setequal(x$candidate_id,candidate_ids))
  attr(x,'project')<-project
  attr(x,'registry_sources')<-paths
  x
}
mp_preview_row <- function(previews,id) {
  if(is.null(previews)||length(id)!=1L)return(NULL)
  x<-previews[previews$candidate_id==id,,drop=FALSE]
  if(nrow(x)!=1L)return(NULL)
  x
}
mp_has_text <- function(x) length(x)==1L&&!is.na(x)&&nzchar(x)
mp_is_true <- function(x) length(x)==1L&&!is.na(x)&&toupper(x)=='TRUE'
mp_https <- function(x) mp_has_text(x)&&grepl('^https://[^/[:space:]]+/',x)
# User's explicit task-level permission is a local record, not an invented web licence.
# This permits this local course preview; public redistribution remains unverified.
mp_preview_permission <- function(previews,x) {
  if(mp_https(x$permission_evidence_url))return(TRUE)
  if(!identical(x$preview_type,'local_audio')||!identical(x$permission_basis_type,'user_statement_for_this_task')||
     !identical(x$permission_scope,'local_course_dashboard_preview_only')||
     !mp_has_text(x$permission_evidence_file)||!mp_has_text(x$permission_evidence_sha256))return(FALSE)
  expected<-'data/music_preview_research/local_video/USER_PERMISSION_RECORD.md'
  if(!identical(x$permission_evidence_file,expected))return(FALSE)
  project<-attr(previews,'project')
  candidates<-unique(c(file.path(project,expected),file.path(getwd(),expected)))
  any(vapply(candidates,function(path)
    file.exists(path)&&identical(digest::digest(file=path,algo='sha256'),x$permission_evidence_sha256),logical(1)))
}
mp_preview_source <- function(previews,id) {
  x<-mp_preview_row(previews,id)
  # A visible URL, an archive membership, or a platform download flag cannot grant permission.
  # Pending clips are accessible only in the explicitly configured local acceptance process.
  if(is.null(x))return(NULL)
  accepted<-identical(x$preview_status,'preview_ready')||
    (identical(Sys.getenv('MUSICPULSE_AUDIO_VALIDATION'),'1')&&identical(x$preview_status,'preview_pending_browser_test'))
  if(!accepted||!mp_is_true(x$preview_source_verified)||
     !x$usage_permission%in%c('authorized_preview','authorized_download')||!mp_preview_permission(previews,x))return(NULL)
  if(x$preview_type=='html5_audio'&&mp_https(x$preview_url))return(list(type='audio',url=x$preview_url))
  if(x$preview_type=='official_embed'&&mp_is_true(x$embed_permission_verified)&&mp_https(x$preview_url))return(list(type='embed',url=x$preview_url))
  if(x$preview_type=='local_audio'&&mp_has_text(x$local_audio_path)&&mp_has_text(x$local_audio_sha256)){
    base<-normalizePath(file.path(attr(previews,'project'),'data/music_preview_research/audio'),winslash='/',mustWork=TRUE)
    path<-file.path(attr(previews,'project'),x$local_audio_path)
    if(!file.exists(path))return(NULL)
    path<-normalizePath(path,winslash='/',mustWork=TRUE)
    if(!startsWith(path,paste0(base,'/'))||dirname(path)!=base||!grepl('^[A-Za-z0-9_.-]+$',basename(path))||
       !identical(tolower(digest::digest(file=path,algo='sha256')),tolower(x$local_audio_sha256)))return(NULL)
    return(list(type='audio',url=paste0('musicpulse-preview-audio/',basename(path))))
  }
  NULL
}
mp_preview_entry <- function(previews,id) {
  available<-!is.null(mp_preview_source(previews,id))
  shiny::tags$span(class='mp-preview-entry',
    if(available)shiny::actionButton('preview_audio','Preview Audio',class='mp-preview-button')
    else shiny::tagList(
      shiny::tags$button(type='button',disabled=NA,class='mp-preview-status','Preview unavailable'),
      shiny::actionButton('preview_audio_info',shiny::tags$span('i',`aria-hidden`='true'),class='mp-preview-info',
        title='Audio preview availability',`aria-label`='Audio preview availability')))
}
mp_kugou_link <- function(previews,id,compact=TRUE) {
  x<-mp_preview_row(previews,id)
  if(is.null(x)||!identical(x$kugou_link_status,'verified_native_hash_and_album')||
     !mp_https(x$kugou_song_url)||!grepl('^https://www\\.kugou\\.com/mixsong/[A-Za-z0-9]+\\.html$',x$kugou_song_url))return(NULL)
  shiny::tags$a(class=paste('mp-kugou-link',if(compact)'mp-kugou-compact'),href=x$kugou_song_url,target='_blank',rel='noopener noreferrer',
    title=paste0('Open on KuGou · ',x$kugou_page_title,' · ',x$kugou_page_artist),`aria-label`=paste('Open on KuGou',x$kugou_page_title,x$kugou_page_artist),
    `data-mp-kugou-id`=x$kugou_song_id,`data-mp-candidate`=id,
    shiny::HTML('<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><path d="M11 3h6v6M17 3l-8 8M8 4H4a1 1 0 0 0-1 1v11a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1v-4"/></svg>'),
    if(!compact)'Open on KuGou')
}
mp_preview_dialog <- function(previews,id) {
  x<-mp_preview_row(previews,id);if(is.null(x))return(NULL)
  source<-mp_preview_source(previews,id)
  media<-if(is.null(source))shiny::tags$div(class='mp-preview-empty',shiny::tags$strong('Preview unavailable'),
    shiny::tags$p('A verified, authorized Douyin excerpt is not available for this candidate.'))
  else if(source$type=='audio')shiny::tags$audio(id='mp_preview_audio',controls=NA,preload='none',
    src=if(!identical(x$preview_type,'local_audio'))source$url else NULL,
    `data-local-preview-src`=if(identical(x$preview_type,'local_audio'))source$url else NULL,
    `aria-label`=paste('Audio preview',x$song_title),'Your browser does not support audio playback.')
  else shiny::tags$iframe(id='mp_preview_embed',src=source$url,title=paste('Official audio preview',x$song_title),
    allow='autoplay',referrerpolicy='strict-origin-when-cross-origin',sandbox='allow-scripts allow-same-origin allow-popups')
  dialog<-shiny::modalDialog(title=shiny::tagList(shiny::tags$span('MusicPulse Audio Preview'),
      shiny::tags$button(type='button',class='mp-preview-x',`data-dismiss`='modal',`data-bs-dismiss`='modal',`aria-label`='Close audio preview','×')),
    shiny::tags$div(class='mp-preview-body',`data-preview-candidate`=id,
      shiny::tags$div(class='mp-preview-record',`aria-hidden`='true',shiny::tags$span()),
      shiny::tags$h3(x$song_title),shiny::tags$p(class='mp-preview-artist',x$artist),
      shiny::tags$p(class='mp-preview-kind',if(is.null(source))'Douyin excerpt · not yet verified'
        else if(identical(x$preview_type,'local_audio'))paste0('User-provided video audio · first ',round(as.numeric(x$actual_excerpt_seconds),2),' s')
        else 'Douyin popular excerpt'),media,
      shiny::tags$small(class='mp-preview-provenance',id)),
    size='m',easyClose=TRUE,footer=shiny::modalButton('Close'))
  htmltools::tagAppendAttributes(dialog,class='mp-preview-modal')
}
mp_register_preview <- function(previews,selected_id,input,session) {
  opened<-shiny::reactiveVal(NULL)
  show<-function(){
    id<-selected_id();dialog<-mp_preview_dialog(previews,id)
    if(is.null(dialog))return()
    session$sendCustomMessage('mpStopPreview',list())
    opened(id);shiny::showModal(dialog,session=session)
  }
  shiny::observeEvent(input$preview_audio,show(),ignoreInit=TRUE)
  shiny::observeEvent(input$preview_audio_info,show(),ignoreInit=TRUE)
  shiny::observeEvent(input$mp_preview_closed,opened(NULL),ignoreInit=TRUE)
  # Selection changes discard the previous modal; reopening always reads the current candidate.
  shiny::observeEvent(selected_id(),{
    if(!is.null(opened())){session$sendCustomMessage('mpStopPreview',list());shiny::removeModal(session);opened(NULL)}
  },ignoreInit=TRUE)
}
