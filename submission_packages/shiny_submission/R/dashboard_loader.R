# Shared read-only data: the six supplied CSVs are loaded once per process.
load_dashboard_data <- function(project, app_dir) {
  source(file.path(app_dir,'R/direct_data.R'),local=TRUE)
  cache_path <- file.path(app_dir, 'data', 'cache', 'dashboard_data.rds')
  if (file.exists(cache_path)) {
    cached <- readRDS(cache_path)
    attr(cached, 'source_info') <- c(attr(cached, 'source_info'), list(cache = TRUE))
    return(cached)
  }
  result <- load_direct_dashboard_data(project,app_dir)
  dir.create(dirname(cache_path), recursive=TRUE, showWarnings=FALSE)
  saveRDS(result, cache_path, compress='xz')
  result
}
