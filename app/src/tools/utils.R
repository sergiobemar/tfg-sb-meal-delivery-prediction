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
    install.packages(packages[!installed_packages], repo="http://cran.rstudio.com/")
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
  
  packages <- c('dplyr', 'data.table', 'plotly', 'purrr', 'lubridate', 'jsonlite', 'shiny', 'shinydashboard', 'DT', 'shinyWidgets', 'httr', 'shinyBS')
  
  load_packages(packages)

  # https://community.rstudio.com/t/shinysky-package-is-not-available-for-r-version-3-5-2/27497/2
  if (!('shinysky' %in% rownames(installed.packages()))) {
    devtools::install_github("AnalytixWare/ShinySky")
    library(shinysky)
  } else {
    library(shinysky)
  }

  if (!('kableExtra' %in% rownames(installed.packages()))) {
    install.packages("kableExtra", dependencies = TRUE)
    library(kableExtra)
  } else {
    library(kableExtra)
  }

  
  source('./src/data/data_collect.R')
  source('./src/shiny/dashboard_functions.R')
  source('./src/deploy/api_calls.R')
}
