# Clear workspace
rm(list = ls())

source('./src/tools/utils.R')

# Load packages
load_packages_shiny()

# Config
config_app()

# Get data from Clickhouse
get_data_clickhouse()

# Get data
# get_shiny_data()
get_shiny_data_ch()

# Define UI for application that draws a histogram
ui <- dashboardPage(
    dashboardHeader(
        title = 'PLATAFORMA PEDIDOS'
    ),
    dashboardSidebar(
        load_css(),
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
                                    start = df_orders_set_up$date %>% max() -365,
                                    end = df_orders_set_up$date %>% max(),
                                    min = df_orders_set_up$date %>% min(),
                                    max = df_orders_set_up$date %>% max(),
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
                    )
                ),
                # Insert busy indicator icon and text
                shinysky::busyIndicator("Calculando..."),
                
                # Show value box outputs
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
                
                fluidRow(
                    box(
                        title = 'Conoce tu previsión de pedidos',
                        solidHeader = TRUE, 
                        status = "primary",
                        selectizeInput(
                            "pred_center_id", 
                            label = h5("Centro"), 
                            choices = df_center$center_id %>% unique() %>% sort(), 
                            selected = df_center$center_id %>% unique() %>% sort() %>% head(1), 
                            multiple = FALSE,
                            options = NULL
                        ),
                        selectizeInput(
                            "pred_meal_id", 
                            label = h5("Comida"), 
                            choices = df_meal$meal_id %>% unique() %>% sort(), 
                            selected = df_meal$meal_id %>% unique() %>% sort() %>% head(1), 
                            multiple = FALSE,
                            options = NULL
                        ),
                        actionButton(
                            inputId = 'pred_btn_prediction',
                            label = 'Previsión'
                        ),
                        actionButton(inputId = 'pred_send_alert', 'Enviar alerta')
                    ),
                    box(
                        title = 'INFO SELECCIÓN',
                        solidHeader = TRUE, 
                        status = "info",
                        box(
                            title = 'Info centro',
                            uiOutput("pred_get_center_info")
                        ),
                        box(
                            title = 'Info comida',
                            uiOutput("pred_get_meal_info")
                        )
                    )
                ),
                # Insert busy indicator icon and text
                shinysky::busyIndicator("Calculando..."),
                
                # Value box
                fluidRow(
                    valueBoxOutput("pred_show_total_orders"),
                    valueBoxOutput("pred_show_turnover"),
                    valueBoxOutput("pred_show_error"),
                    valueBoxOutput("pred_show_progression")
                ),
                
                # Charts
                fluidRow(
                    column(
                        width = 12,
                        plotlyOutput("predicted_orders_line_chart", height = '275px')
                    )
                ),
                
                # BS Modal alert
                bsModal("modal_alert", "Enviar alerta", "pred_send_alert",
                    HTML(paste0("Deseas enviar una alerta a los centros de la siguiente tipología:", textOutput("pred_get_center_type"))),
                    br(),
                    actionButton("pred_btn_yes", "Enviar")
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
        df_orders <- df_orders_set_up %>%
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
        if (!is.null(input$dash_meal_category)) {
            df_orders <- df_orders %>%
                filter(category %in% input$dash_meal_category)
        }
        
        df_orders
    })
    
    # Prediction button
    df_predict <- eventReactive(input$pred_btn_prediction, {
        
        # Get data to predict the number of orders from center_id and meal_id
        df_list <- get_data_predict(input$pred_center_id, input$pred_meal_id) 
        
        # Train the model
        string_train_log <- train_model(input$pred_center_id, input$pred_meal_id)
        
        # Get predictions using the API Post request
        # df_predictions <- get_predictions(df_list[2][[1]])
        df_predictions <- get_predictions_2(input$pred_center_id, input$pred_meal_id)
        
        # Cast columns
        df_predictions$date <- df_predictions$date %>% as.Date()
        df_predictions$num_orders <- df_predictions$num_orders %>% as.integer()
        
        # Joining with pred_test dataframe
        df_result <- df_list[2][[1]] %>% left_join(df_predictions, by = 'date')
        
        return(list(df_list[1][[1]], df_result, string_train_log$rmse))
    })
    
    # PREDICTION: Get input$center_id by reactive method
    get_pred_center_id_info <- reactive({
        df_center %>% 
            filter(center_id == input$pred_center_id)
    })
    
    # PREDICTION: Get input$meal_id by reactive method
    get_pred_meal_id_info <- reactive({
        df_meal %>% 
            filter(meal_id == input$pred_meal_id)
    })
    
    # PREDICTION: Observe events for buttons of Alerts BS Modal
    observeEvent(input$pred_btn_yes, {
        
        toggleModal(session, "modal_alert", toggle = "close")
        
        # Check if the prediction button was selected before
        if (input$pred_btn_prediction == 0) {
            result_reason <- 'error_0'
        } else {
            # Calculate progression
            ## Get the prectied num orders
            predicted_num_orders <- df_predict()[2][[1]] %>% 
                summarise(
                    total_orders = sum(base_price, na.rm = T)
                ) %>% 
                pull()
            
            ## Get the number of orders from the last 10 weeks
            actual_num_orders <- df_predict()[1][[1]] %>% 
                head(df_predict()[2][[1]] %>% nrow()) %>%
                summarise(
                    total_orders = sum(base_price, na.rm = T)
                ) %>% 
                pull()
            
            ## Calculate progression
            predicted_progression <- ((predicted_num_orders / actual_num_orders) - 1) * 100
            
            # Round values
            predicted_num_orders <- predicted_num_orders %>% round(0)
            predicted_progression <- predicted_progression %>% round(2)
            
            # Send alert
            result <- send_alert(input$pred_center_id, predicted_num_orders, predicted_progression)
            
            # If API response was error
            print(result)
            if(http_error(result)) {
                result_reason <- 'error_1'    
            } else {
                result_reason <- 'ok'
            }
        }
        
        # Check if there was any errors
        if (result_reason == 'ok') {
            title <- 'Alerta enviada'
            text <- 'La alerta se envío correctamente al canal de Slack.'
        } else if (result_reason == 'error_0') {
            title <- 'ERROR ENVÍO ALERTA'
            text <- 'No se ha generado ninguna predicción aún.'
        } else {
            title <- 'Error envío alerta'
            text <- 'Hubo un error al enviar la alerta al canal de Slack.'
            
        }

        # Show modal
        showModal(
            modalDialog(
                title = title,
                if (result_reason == 'ok')
                    div(tags$b(text))
                else
                    div(span(text, style = "color: red;")),
                footer = tagList(
                    modalButton("Cancel")
                ),
                easyClose = TRUE
            )
        )
    })
    
    # Show Plotly pie chart of center types
    output$center_type_pie_chart <- renderPlotly({
        show_plotly_center_type_pie(dash_orders_data())
    })
    
    # Show Plotly pie chart of cuisine
    output$cuisine_pie_chart <- renderPlotly({
        show_plotly_cuisine_pie(dash_orders_data())
    })
    
    # Show DT in dashboard
    output$orders_table <- DT::renderDataTable({
        get_orders_table(dash_orders_data())
    })
    
    # PREDICTION: Get info of the center choosen
    output$pred_get_center_info <- renderUI({
        
        # Region
        region <- get_pred_center_id_info() %>%
            select(region_code) %>%
            pull()
        
        # Type
        center_type <- get_pred_center_id_info() %>%
            select(center_type) %>%
            pull()
        
        div(
            style = "text-align:center",
            p(paste0('REGIÓN: ', region)),
            p(paste0('TIPOLOGÍA: ', center_type))
        )
    })
    
    # PREDICTION: Get the type of the center choosen in string format
    output$pred_get_center_type <- renderText({
        # Center type
        center_type <- get_pred_center_id_info() %>%
            select(center_type) %>%
            pull()
        
        center_type
    })
    
    # PREDICTION: Get info of the center choosen
    output$pred_get_meal_info <- renderUI({
        
        # Cuisine
        cuisine <- get_pred_meal_id_info() %>%
            select(cuisine) %>%
            pull()

        # Category
        category <- get_pred_meal_id_info() %>%
            select(category) %>%
            pull()
        
        div(
            style = "text-align:center",
            p(paste0('COCINA: ', cuisine)),
            p(paste0('CATEGORÍA: ', category))
        )
    })
    
    # PREDICTION: When predictions are calculated, it's showed a Plotly chart for predicted orders
    output$predicted_orders_line_chart <- renderPlotly({
        show_plotly_prediction_line_chart(df_predict()[1][[1]], df_predict()[2][[1]])
    })
    
    # PREDICTION: Value box to show RMSE that model predicts
    output$pred_show_error <- renderValueBox({
        value <- df_predict()[3][[1]]
        
        valueBox(
            value = format(
                round(value, 4),
                scientific = FALSE, 
                big.mark = ".", 
                decimal.mark = ","
            ),
            'Error total estimado',
            icon = icon("exclamation-circle"), color = 'purple'
        )
    })
    
    # PREDICTION: Value box to show the progression from the last period
    output$pred_show_progression <- renderValueBox({
        
        # Get the prectied num orders
        predicted_num_orders <- df_predict()[2][[1]] %>% 
            summarise(
                total_orders = sum(base_price, na.rm = T)
            ) %>% 
            pull()
        
        # Get the number of orders from the last 10 weeks
        actual_num_orders <- df_predict()[1][[1]] %>% 
            head(df_predict()[2][[1]] %>% nrow()) %>%
            summarise(
                total_orders = sum(base_price, na.rm = T)
            ) %>% 
            pull()
        
        # Calculate progression
        value <- ((predicted_num_orders / actual_num_orders) - 1) * 100
        
        # Change color 
        if (value > 0) {
            color <- "olive"
        } else {
            color <- "red"
        } 
        
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
            'Progresión estimada frente al mismo periodo',
            icon = icon("chart-line"), color = color
        )
    })
    
    # PREDICTION: Show bsModal when click on send the alert, in order to capture if everything went ok
    # reactive_alert_response <- reactive({
    #     alert_response()
    # })
    # output$pred_show_sent_alert_modal <- renderUI({
    #     if (reactive_alert_response()) {
    #         title <- 'ALERTA ENVIADA'
    #         text <- 'La alerta se envío correctamente al canal de Slack.'
    #     } else {
    #         title <- 'ERROR ENVÍO ALERTA'
    #         text <- 'Hubo un error al enviar la alerta al canal de slack'
    #     }
    #     
    #     bsModal("modal_sent_alert", title, "pred_send_alert", size = "small", text)
    # })
    
    # PREDICTION: Value box to show total orders that model predicts
    output$pred_show_total_orders <- renderValueBox({
        value <- df_predict()[2][[1]] %>% 
            summarise(total_orders = sum(base_price, na.rm = T)) %>% 
            pull()
        
        valueBox(
            value = format(
                round(value, 0),
                scientific = FALSE, 
                big.mark = ".", 
                decimal.mark = ","
            ),
            'Pedidos totales estimados',
            icon = icon("shopping-cart", lib = "glyphicon"), color = 'blue'
        )
    })
    
    # PREDICTION: Value box to show total turnover that model predicts
    output$pred_show_turnover <- renderValueBox({
        value <- df_predict()[2][[1]] %>% 
            summarise(total_orders = sum(num_orders, na.rm = T)) %>% 
            pull()
        
        valueBox(
            value = paste(
                format(
                    round(value, 0),
                    scientific = FALSE, 
                    big.mark = ".", 
                    decimal.mark = ","
                ),
                "€",
                sep = " "
            ),
            'Volumen de ventas estimado',
            icon = icon("credit-card"), color = 'orange'
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
            icon = icon("piggy-bank"), color = 'teal'
        )
    })
    
    # Show sales value box
    output$show_sales_value_box <- renderValueBox({
        value <- dash_orders_data() %>% summarise(total_orders = sum(checkout_price)) %>% pull()
        
        valueBox(
            value = paste(
                format(
                    round(value, 0),
                    scientific = FALSE, 
                    big.mark = ".", 
                    decimal.mark = ","
                ),
                "€",
                sep = " "
            ),
            'Ventas',
            icon = icon("credit-card"), color = 'orange'
        )
    })
    
    # Show Plotly chart with total orders
    output$total_orders_chart <- renderPlotly({
        show_plotly_general_orders(dash_orders_data())
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
            icon = icon("shopping-cart", lib = "glyphicon"), color = 'blue'
        )
    })
    
    output$test_string <- renderText({
        df_predict()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
