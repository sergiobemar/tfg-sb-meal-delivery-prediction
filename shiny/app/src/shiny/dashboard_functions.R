# Render DT orders table
get_orders_table <- function(data) {
  
  DT::datatable(
    data,
    extensions = c('Buttons','Scroller'),
    rownames = FALSE,
    selection = "none",
    options = list(
      language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json'),		
      columnDefs = list(
        list(
          className = 'dt-center'
        )
      ),
      dom = 'Bfrtip',
      buttons = 
        list(
          c('copy','excel', 'csv')
        ),
      deferRender = TRUE,
      scrollY = 400,
      scrollX = TRUE,
      scroller = TRUE
      )
  )
}

# Show plotly of center types using a pie chart
show_plotly_center_type_pie <- function(data) {

  # Summarise dataframe
  df_plot <- data %>% 
    group_by(center_type) %>%
    summarise(
      total_orders = sum(num_orders)
    ) %>% 
    ungroup()
  
  fig <- df_plot %>%
    plot_ly(
    labels = ~center_type,
    values = ~total_orders,
    name = 'Tipo', 
    type = 'pie',
    marker = list(
      colors = c(
        "#fbb4ae",
        "#b3cde3",
        "#ccebc5"
      )
    )
  )
  
  m <- list(
    l = 20,
    r = 20,
    b = 20,
    t = 50,
    pad = 5
  )
  
  fig <- fig %>% 
    layout(
      title = "Pedidos por tipología de centros", margin = m
    ) %>% plotly::config(locale = "es")
  
  fig
}

show_plotly_cuisine_pie <- function(data) {
  # Summarise dataframe
  df_plot <- data %>% 
    group_by(cuisine) %>%
    summarise(
      total_orders = sum(num_orders)
    ) %>% 
    ungroup()
  
  fig <- df_plot %>%
    plot_ly(
      labels = ~cuisine,
      values = ~total_orders,
      name = 'Tipo', 
      type = 'pie',
      marker = list(
        colors = c(
          '#7fc97f', 
          '#beaed4', 
          '#fdc086', 
          '#ffff99'
        )
      )
    )
  
  m <- list(
    l = 20,
    r = 20,
    b = 20,
    t = 50,
    pad = 5
  )
  
  fig <- fig %>% 
    layout(
      title = "Pedidos por tipo de cocina", margin = m
    ) %>% plotly::config(locale = "es")
  
  fig
}

# Show plotly chart of total orders
show_plotly_general_orders <- function(data) {
  
  # Summarise dataframe
  df_plot <- data %>% 
    group_by(date) %>%
    summarise(
      total_orders = sum(num_orders)
    ) %>% 
    ungroup()
  
  fig <- df_plot %>% plot_ly(
    x = ~date,
    y = ~total_orders,
    name = 'Total de pedidos', 
    type = 'scatter', 
    mode = 'lines'
  )
  
  m <- list(
    l = 20,
    r = 20,
    b = 20,
    t = 50,
    pad = 5
  )
  
  fig <- fig %>% 
    layout(
      title = "Evolución temporal de los pedidos",
      separators = ',.',
      xaxis = list(
        title = "Fecha"
      ),
      yaxis = list (
        title = "Nb pedidos",
        tickformat = ",.0f"
      ),
      margin = m
    ) %>% plotly::config(locale = "es")
  
  fig
}

# Show predictions Plotly chart
show_plotly_prediction_line_chart <- function(data_train, data_test, rmse) {
  
  # Summarise train dataframe
  df_plot_train <- data_train %>% 
    group_by(date) %>%
    summarise(
      total_orders = sum(num_orders)
    ) %>% 
    ungroup() %>% 
    as.data.frame()
  
  fig <- df_plot_train %>% plot_ly(
    x = ~date,
    y = ~total_orders,
    name = 'Histórico', 
    type = 'scatter', 
    mode = 'lines'
  )
  
  # Summarise test dataframe
  df_plot_test <- data_test %>% 
    group_by(date) %>%
    summarise(
      total_orders = sum(num_orders)
    ) %>% 
    ungroup() %>% 
    as.data.frame()
  
  # Calculate confidence interval
  df_plot_prediction <- bind_rows(
    df_plot_test,
    df_plot_train %>% filter(date == max(date))
  ) %>% 
    arrange(date) %>%
    mutate(
      total_orders_min = ifelse(date == min(date), total_orders - 0, total_orders - rmse),
      total_orders_max = ifelse(date == min(date), total_orders - 0, total_orders + rmse)
    ) %>% 
    mutate(
      total_orders_min = if_else(total_orders_min < 0, 0, total_orders_min),
      total_orders_max = if_else(total_orders_max < 0, 0, total_orders_max)
    )
  
  # Add high confidence interval
  fig <- fig %>% add_trace(
    data = df_plot_prediction,
    x = ~date,
    y = ~total_orders_max,
    name = 'Predicción',
    type = 'scatter',
    mode = 'lines',
    line = list(color = 'transparent'),
    showlegend = FALSE,
    name = 'Pedidos máximos'
  )
  
  # Add low confidence interval
  fig <- fig %>% add_trace(
    data = df_plot_prediction,
    x = ~date,
    y = ~total_orders_min,
    name = 'Predicción',
    type = 'scatter',
    mode = 'lines',
    fill = 'tonexty',
    fillcolor='rgba(0,100,80,0.2)',
    line = list(color = 'transparent'),
    showlegend = FALSE,
    name = 'Pedidos mínimos'
  )
  
  # Add prediction line
  fig <- fig %>% add_trace(
    data = df_plot_prediction,
    x = ~date,
    y = ~total_orders,
    name = 'Predicción', 
    type = 'scatter', 
    mode = 'lines'
  )
  
  # Layout
  m <- list(
    l = 20,
    r = 20,
    b = 50,
    t = 50,
    pad = 5
  )
  
  fig <- fig %>% 
    layout(
      title = "Previsión de pedidos",
      separators = ',.',
      showlegend = FALSE,
      xaxis = list(
        title = "Fecha"
      ),
      yaxis = list (
        title = "Nb pedidos",
        tickformat = ",.0f"
      ),
      margin = m
    ) %>% plotly::config(locale = "es")
  
  fig
}
