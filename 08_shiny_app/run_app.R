args <- commandArgs(FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)][1])
app_dir <- normalizePath(dirname(script), winslash = '/')
source(file.path(app_dir, 'R/data_loader.R'))
invisible(configure_musicpulse(app_dir))
# The supplied app was authored with R 4.6.2; this machine has R 4.6.0,
# which is compatible with the app and installed package set.
if (getRversion() < '4.6.0') stop('R 4.6.0 or newer is required.')
options(musicpulse.app_dir = app_dir, shiny.sanitize.errors = FALSE)
port <- as.integer(Sys.getenv('MUSICPULSE_PORT', '8765'))
app <- source(file.path(app_dir, 'app.R'), local = new.env(parent = globalenv()))$value
shiny::runApp(app, host = '127.0.0.1', port = port, launch.browser = FALSE)
