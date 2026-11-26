# Portable entry point: all runtime resources live inside this directory.
configure_musicpulse <- function(app_dir) {
  app_dir <- normalizePath(app_dir, winslash='/', mustWork=TRUE)
  optional_lib <- Sys.getenv('MUSICPULSE_R_LIB', '')
  .libPaths(c(file.path(app_dir,'.Rlib'),if(nzchar(optional_lib))strsplit(optional_lib,.Platform$path.sep,fixed=TRUE)[[1]],.libPaths()))
  app_dir
}
