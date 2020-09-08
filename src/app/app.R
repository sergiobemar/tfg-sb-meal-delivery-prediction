setwd('../../')

source('./src/data/data_collect.R')
source('./src/shiny/dashboard_functions.R')
source('./src/tools/utils.R')

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
                    box(
                        title = 'FILTROS',
                        width = 12,
                        solidHeader = TRUE, 
                        status = "primary",
                        column(
                            width = 4,
                            box(
                                height = 300,
                                # Date
                                dateRangeInput(
                                    inputId = 'dash_date_filter',
                                    label = 'Fechas pedidos',
                                    start = df_orders$date %>% max() -365,
                                    end = df_orders$date %>% max(),
                                    min = df_orders$date %>% min(),
                                    max = df_orders$date %>% max(),
                                    weekstart = 1,
                                    language = 'es'
                                ),
                                actionButton(
                                    inputId = 'dash_btn_visualize',
                                    label = 'Visualizar'
                                )
                            )
                        ),
                        column(
                            width = 4,
                            box(
                                title = 'Centros',
                                # width = NULL,
                                height = 300,
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
                            )
                        ),
                        column(
                            width = 4,
                            box(
                                title = 'Comidas',
                                # width = NULL,
                                height = 300,
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
                            )
                        )
                    )
                ),
                fluidRow(
                    valueBoxOutput("show_total_orders_value_box"),
                    valueBoxOutput("show_sales_value_box"),
                    valueBoxOutput("show_average_discount_value_box")
                ),
                br(),
                
                # Charts
                fluidRow(
                    plotlyOutput("total_orders_chart", height = '275px'),
                    br(),
                    fluidRow(
                        column(
                            width = 6,
                            plotlyOutput("center_type_pie_chart", height = '275px')
                        ),
                        column(
                            width = 6,
                            plotlyOutput("cuisine_pie_chart", height = '275px')
                        )
                    ),
                    dataTableOutput("orders_table")
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

    # Dashboard visualize button
    dash_orders_data <- eventReactive(input$dash_btn_visualize, {
        # Select the date
        df_orders <- df_orders %>%
            filter((date >= as.Date(input$dash_date_filter[1])) & (date <= as.Date(input$dash_date_filter[2])))
        
        # Select center_type
        if (!is.null(input$dash_center_type)) {
            df_orders <- df_orders %>%
                filter(center_type %in% input$dash_center_type)
        }

        # Select region
        if (!is.null(input$dash_center_region)) {
            df_orders <- df_orders %>%
                filter(region_code %in% input$dash_center_region)
        }

        # Select meal cuisine
        # Select center_type
        if (!is.null(input$dash_meal_cuisine)) {
            df_orders <- df_orders %>%
                filter(cuisine %in% input$dash_meal_cuisine)
        }

        # Select meal category
        if (!is.null(input$category)) {
            df_orders <- df_orders %>%
                filter(category %in% input$category)
        }
        
        df_orders
    })
    
    # Show DT in dashboard
    output$orders_table <- DT::renderDataTable({
        get_orders_table(dash_orders_data())
    })
    
    # Show Plotly chart with total orders
    output$total_orders_chart <- renderPlotly({
        show_plotly_general_orders(dash_orders_data())
    })
    
    # Show Plotly pie chart of center types
    output$center_type_pie_chart <- renderPlotly({
        show_plotly_center_type_pie(dash_orders_data())
    })
    
    # Show Plotly pie chart of cuisine
    output$cuisine_pie_chart <- renderPlotly({
        show_plotly_cuisine_pie(dash_orders_data())
    })
    
    # Show total orders value box
    output$show_total_orders_value_box <- renderValueBox({
        value <- dash_orders_data() %>% summarise(total_orders = sum(num_orders)) %>% pull()
        
        valueBox(
            value = format(
                value,
                scientific = FALSE, 
                big.mark = ".", 
                decimal.mark = ","
            ),
            'Número pedidos',
            icon = icon('basket', lib = 'glyphicon'), color = 'blue'
        )
    })
    
    # Show sales value box
    output$show_sales_value_box <- renderValueBox({
        value <- dash_orders_data() %>% summarise(total_orders = sum(checkout_price)) %>% pull()
        
        valueBox(
            value = paste(
                format(
                    value,
                    scientific = FALSE, 
                    big.mark = ".", 
                    decimal.mark = ","
                ),
                "€",
                sep = " "
            ),
            'Ventas',
            icon = icon('basket', lib = 'glyphicon'), color = 'orange'
        )
    })
    
    # Show average discount value box
    output$show_average_discount_value_box <- renderValueBox({
        value <- dash_orders_data() %>% 
            summarise(total_orders = ((sum(checkout_price)/sum(base_price)) -1) * 100 ) %>% 
            pull()
        
        valueBox(
            value = paste(
                format(
                    round(value, 2),
                    scientific = FALSE, 
                    big.mark = ".", 
                    decimal.mark = ","
                ),
                "%",
                sep = " "
            ),
            'Porcentaje de descuento medio',
            icon = icon('basket', lib = 'glyphicon'), color = 'teal'
        )
    })
    
    # Prediction button
    observeEvent(
        input$pred_btn_prediction, {
            
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)
