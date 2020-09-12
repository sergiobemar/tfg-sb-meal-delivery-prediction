get_predictions <- function(df) {
  
  # Convert df to JSON
  request_body_content <- df %>% 
    toJSON(auto_unbox = TRUE)
  
  # Calling the API
  result <- POST(
    paste0(config_file$URI, "/predict"),
    body = request_body_content,
    add_headers(.headers = c("Content-Type"="application/json"))
  )
  
  # Get result
  output <- content(result, as = 'text') %>% fromJSON() %>% as.data.table()
  
  return(output)
}

get_predictions_2 <- function(center_id, meal_id) {
  
  # Build the content with center_id and meal_id
  request_body_content <- list("center_id" = center_id, "meal_id" = meal_id) %>% 
    toJSON(auto_unbox = TRUE, pretty = TRUE)
  
  print(request_body_content)
  
  # Calling the API
  result <- POST(
    paste0(config_file$URI, "/predict2"),
    body = request_body_content,
    add_headers(.headers = c("Content-Type"="application/json"))
  )
  
  # Get result
  output <- content(result, as = 'text') %>% fromJSON() %>% as.data.table()
  
  return(output)
}

send_alert <- function(center, value_orders, value_progression) {
  
  # Get the channel URI by type of the center
  center_type <- df_center %>% 
    filter(center_id == center) %>% select(center_type) %>% pull()
  
  uri <- alerts_file %>% filter(name == center_type) %>% select(uri) %>% pull()
  
  # Build the content with the total orders predicted
  text <- paste0(
    "Las próximas 10 semanas hay ",
    value_orders,
    " pedidos previstos para el centro ",
    center,
    ", lo que supone una progresión del ",
    value_progression,
    "%"
  )
  
  # Set values for the message
  if (value_progression > 0) {
    title <- 'AVISO: Aumento de los pedidos'
    color <- '#30ff6b'
    footer <- 'Aumento de los pedidos'
  } else {
    title <- 'ALERTA: Descenso de las ventas'
    color <- '#FF3030'
    footer <- 'Descenso de las ventas'
  }
  
  ts <- Sys.Date() %>% as.POSIXct() %>% as.integer()
  
  attachments = list(
    "fallback" = title,
    "title" = title,
    "color" = color,
    "text" = text,
    "footer" = footer,
    "ts" = ts
  )
  
  request_body_content <- list(
    "attachments" = list(attachments)
    ) %>% 
    toJSON(auto_unbox = TRUE, pretty = TRUE)
  
  print(request_body_content)
  
  # Calling the API
  result <- POST(
    uri,
    body = request_body_content,
    add_headers(.headers = c("Content-Type"="application/json"))
  )
  
  return(result)
}

train_model <- function(center_id, meal_id) {
  
  # Build the content with center_id and meal_id
  request_body_content <- list("center_id" = center_id, "meal_id" = meal_id) %>% 
    toJSON(auto_unbox = TRUE, pretty = TRUE)
  
  # Calling the API
  result <- POST(
    paste0(config_file$URI, "/train"),
    body = request_body_content,
    add_headers(.headers = c("Content-Type"="application/json"))
  )
  
  # Get result
  output <- content(result)
  
  return(output)
}
