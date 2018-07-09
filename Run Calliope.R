run_calliope <- function(launch_browser = TRUE) {
  app_path <- system.file(package = "Calliope-View")
  return(shiny::runApp(appDir = app_path, launch.browser = launch_browser))
}