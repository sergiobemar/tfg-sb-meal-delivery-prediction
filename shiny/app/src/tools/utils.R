config_app <- function() {
  
  options(shiny.sanitize.errors = TRUE)
  
  # Get configuration vars from JSON file
  config_file <<- jsonlite::fromJSON(readLines("config/config_shiny_app.json"))
  
  # Read JSON alerts file
  alerts_file <<- jsonlite::fromJSON(readLines("config/alerts.json"))
  
  # Read Clickhouse credentials
  credentials_ch <<- jsonlite::fromJSON(readLines("config/credentials_clickhouse.json"))
  
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
  
  packages <- c('dplyr', 'data.table', 'plotly', 'purrr', 'lubridate', 'jsonlite', 'shiny', 'shinydashboard', 'DT', 'shinyWidgets', 'httr', 'shinyBS', 'remotes', 'DBI')
  
  load_packages(packages)

  # https://community.rstudio.com/t/shinysky-package-is-not-available-for-r-version-3-5-2/27497/2
  if (!('shinysky' %in% rownames(installed.packages()))) {
    install_github("AnalytixWare/ShinySky")
    library(shinysky)
  } else {
    library(shinysky)
  }

  # Install Clickhouse-r if it's not installed
  # https://github.com/hannesmuehleisen/clickhouse-r
  package <- "clickhouse"
  if (!(package %in% rownames(installed.packages()))) {
    install_github("hannesmuehleisen/clickhouse-r")
  }
  
#  if (!('kableExtra' %in% rownames(installed.packages()))) {
#    install.packages("kableExtra", dependencies = TRUE)
#    library(kableExtra)
#  } else {
#    library(kableExtra)
#  }

  
  source('./src/data/data_collect.R')
  source('./src/shiny/dashboard_functions.R')
  source('./src/deploy/api_calls.R')
}
