config_app <- function() {
  
  # Get configuration vars from JSON file
  config_file <<- jsonlite::fromJSON("./config/config_shiny_app.json")
  
  # Read JSON alerts file
  alerts_file <<- jsonlite::fromJSON("./config/alerts.json")
  
  options(shiny.sanitize.errors = TRUE)
}

load_packages <- function(packages){
  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }
  
  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))
}

load_css <- function() {
  tags$head(
    tags$style(
      HTML("
        .main-header .logo {
          font-family: 'Roboto'
          font-weight: bold;
          font-size: 16px;
        }
      ")
    )
  )
}

load_packages_shiny <- function() {
  
  packages <- c('dplyr', 'data.table', 'plotly', 'kableExtra', 'purrr', 'lubridate', 'jsonlite', 'shiny', 'shinydashboard', 'DT', 'shinyWidgets', 'shinysky', 'httr', 'shinyBS')
  
  load_packages(packages)
  
  source('./src/data/data_collect.R')
  source('./src/shiny/dashboard_functions.R')
  source('./src/deploy/api_calls.R')
}