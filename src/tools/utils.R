load_packages <- function(packages){
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }
  
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
}

load_packages_shiny <- function() {
  
  packages <- c('dplyr', 'data.table', 'plotly', 'kableExtra', 'purrr', 'lubridate', 'jsonlite', 'shiny', 'shinydashboard', 'DT', 'shinyWidgets')
  
  load_packages(packages)
  
  options(shiny.sanitize.errors = TRUE)
}