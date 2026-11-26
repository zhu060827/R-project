# Terminal: Rscript run_app.R; RStudio: source("run_app.R").
args <- commandArgs(FALSE)
arg <- sub('^--file=', '', args[grepl('^--file=', args)])
entry <- if(length(arg)) arg[1] else tryCatch(sys.frame(1)$ofile,error=function(e)NULL)
app_dir <- if(length(entry)) normalizePath(dirname(entry),winslash='/',mustWork=TRUE) else normalizePath('.',winslash='/')
if(!file.exists(file.path(app_dir,'app.R')))stop('Run from the MusicPulse-Final folder.')
if(getRversion() < '4.3.0')stop('Use R 4.3+; tested with R 4.6.2.')
source(file.path(app_dir,'R/data_loader.R'))
invisible(configure_musicpulse(app_dir))
if(!requireNamespace('shiny',quietly=TRUE))stop('Install dependencies: source("requirements.R")')
options(musicpulse.app_dir=app_dir,shiny.sanitize.errors=FALSE)
port <- suppressWarnings(as.integer(Sys.getenv('MUSICPULSE_PORT','8765')))
if(length(port)!=1L||is.na(port)||port<1L||port>65535L)stop('Invalid MUSICPULSE_PORT.')
# Explicit source order preserves the existing theme/module initialization.
app <- source(file.path(app_dir,'app.R'),local=new.env(parent=globalenv()))$value
shiny::runApp(app,host='127.0.0.1',port=port,launch.browser=interactive())