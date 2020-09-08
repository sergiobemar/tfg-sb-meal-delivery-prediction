# Render DT orders table
get_orders_table <- function(data) {
  
  DT::datatable(
    data,
    extensions = c('Buttons','Scroller'),
    rownames = FALSE,
    selection = "none",
    options = list(
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
  
  fig <- fig %>% 
    layout(
      title = "Pedidos por tipología de centros"
    )
  
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
  
  fig <- fig %>% 
    layout(
      title = "Pedidos por tipo de cocina"
    )
  
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
      )
    )
  
  fig
}

