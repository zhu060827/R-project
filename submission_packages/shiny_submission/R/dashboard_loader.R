# Shared read-only data: the six supplied CSVs are loaded once per process.
load_dashboard_data <- function(project, app_dir) {
  source(file.path(app_dir,'R/direct_data.R'),local=TRUE)
  load_direct_dashboard_data(project,app_dir)
}
