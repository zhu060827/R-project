# Installs missing/outdated runtime packages, never data or music.
minimum <- c(bslib='0.9.0',digest='0.6.31',dplyr='1.1.1',ggplot2='3.5.0',htmltools='0.5.7',htmlwidgets='1.6.0',jsonlite='1.8.0',lubridate='1.9.0',plotly='4.10.4',purrr='1.0.0',readr='2.1.0',shiny='1.8.0',stringr='1.5.0',systemfonts='1.1.0',tidyr='1.3.0')
if(getRversion() < '4.3.0')stop('R 4.3+ required; tested with R 4.6.2.')
compatible <- function(p) requireNamespace(p,quietly=TRUE)&&packageVersion(p)>=minimum[[p]]
needed <- names(minimum)[!vapply(names(minimum),compatible,logical(1))]
if(length(needed)){
 lib <- .libPaths()[1]
 if(file.access(lib,2)!=0){lib<-strsplit(Sys.getenv('R_LIBS_USER'),.Platform$path.sep,fixed=TRUE)[[1]][1];dir.create(lib,recursive=TRUE,showWarnings=FALSE);.libPaths(c(lib,.libPaths()))}
 options(timeout=max(300,getOption('timeout')))
 install.packages(needed,lib=lib,repos=Sys.getenv('MUSICPULSE_CRAN','https://cloud.r-project.org'),dependencies=NA)
}
stopifnot(all(vapply(names(minimum),compatible,logical(1))))
message('Runtime dependencies ready. Acceptance versions: DEPENDENCY_VERSIONS.csv.')