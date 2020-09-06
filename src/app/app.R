setwd('../../')

source('./src/tools/utils.R')
source('./src/data/data_collect.R')

# Load packages
load_packages_shiny()
get_shiny_data()

# Define UI for application that draws a histogram
ui <- dashboardPage(
    dashboardHeader(
        title = 'Pedidos'
    ),
    dashboardSidebar(
        sidebarMenu(
            menuItem("Dashboard", tabName = "tab_dashboard", icon = icon("dashboard")),
            menuItem("Previsión", tabName = "tab_predict", icon = icon("th"))
        )
    ),
    dashboardBody(
        tabItems(
            # DASHBOARD
            tabItem(
                tabName = "tab_dashboard",
                fluidRow(
                    # title = 'Filtros',
                    # Date
                    dateRangeInput(
                        inputId = 'dash_date_filter',
                        label = 'Fechas pedidos',
                        start = df_orders$date %>% max() -365,
                        end = df_orders$date %>% max(),
                        weekstart = 1,
                        language = 'es'
                    ),
                    # Centers
                    box(
                        title = 'Centros',
                        selectizeInput(
                            "dash_center_type", 
                            label = h5("Tipo"), 
                            choices = df_center$center_type %>% unique() %>% sort(), 
                            selected = NULL, 
                            multiple = TRUE
                        ), 
                        selectizeInput(
                            "dash_center_region", 
                            label = h5("Región"), 
                            choices = df_center$region_code %>% unique() %>% sort(), 
                            selected = NULL, 
                            multiple = TRUE
                        )
                    ),
                    
                    # Meals
                    box(
                        title = 'Comidas',
                        selectizeInput(
                            "dash_meal_cuisine", 
                            label = h5("Cocina"), 
                            choices = df_meal$cuisine %>% unique() %>% sort(), 
                            selected = NULL, 
                            multiple = TRUE
                        ), 
                        selectizeInput(
                            "dash_meal_category", 
                            label = h5("Categoría"), 
                            choices = df_meal$category %>% unique() %>% sort(), 
                            selected = NULL, 
                            multiple = TRUE
                        )
                    )
                )
            ),
            
            # ESTIMACIÓN DE PEDIDOS
            tabItem(
                tabName = "tab_predict",
                h2("Estimación de pedidos"),
                
                # Selectores para escoger el centro y el alimento a pedir
                box(
                    title = 'Conoce tu previsión de pedidos',
                    selectizeInput(
                        "pred_center_id", 
                        label = h5("Centro"), 
                        choices = df_center$center_id %>% unique() %>% sort(), 
                        selected = NULL, 
                        multiple = FALSE
                    ),
                    selectizeInput(
                        "pred_meal_id", 
                        label = h5("Comida"), 
                        choices = df_meal$meal_id %>% unique() %>% sort(), 
                        selected = NULL, 
                        multiple = FALSE
                    ),
                    actionButton(
                        inputId = 'pred_btn_prediction',
                        label = 'Previsión'
                    )
                )
            )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

    # Prediction button
    observeEvent(
        input$pred_btn_prediction, {
            
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
