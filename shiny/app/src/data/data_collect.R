source('src/features/preprocessing.R')

write_csv_from_table_clickhouse <- function(conn, table_name, output_filename) {
  
  # Create query
  query = paste0("SELECT * FROM raw.", table_name)
  
  # Send query and write received dataframe into csv
  dbGetQuery(conn, query) %>% as.data.frame() %>% write.csv2(output_filename, quote = F, row.names = F)
  
  print(paste0("OK Write csv ", output_filename, " from raw.", table_name))
}

get_data_clickhouse <- function() {
  
  # Create connection to Clickhouse
  con_ch <- dbConnect(
    clickhouse::clickhouse(), 
    host = credentials_ch$host, 
    port = credentials_ch$port, 
    user = credentials_ch$user, 
    password = credentials_ch$password,
    database = credentials_ch$database
  )
  
  # Check if clickhouse folder doesn't exist, if not, it's created
  path <- './data/clickhouse/'
  if (!dir.exists(path)) {
    dir.create(path)
  }
  
  # Get raw data
  ## Meal
  table_name <- "meal"
  output_path <- paste0(path, table_name, ".csv")
  write_csv_from_table_clickhouse(conn = con_ch, table_name = table_name, output_path)
  
  ## Center
  table_name <- "center"
  output_path <- paste0(path, table_name, ".csv")
  write_csv_from_table_clickhouse(conn = con_ch, table_name = table_name, output_path)
  
  ## Test
  table_name <- "test"
  output_path <- paste0(path, table_name, ".csv")
  write_csv_from_table_clickhouse(conn = con_ch, table_name = table_name, output_path)
  
  ## Train
  table_name <- "train"
  output_path <- paste0(path, table_name, ".csv")
  write_csv_from_table_clickhouse(conn = con_ch, table_name = table_name, output_path)
  
  # Disconnect
  dbDisconnect(con_ch)
  
}

get_shiny_data <- function() {
  
  # Train info
  df_train <<- read.csv2(paste0("./data/raw/", "train.csv"), sep = ",") %>% as.data.table()
  df_orders_set_up <<- preprocess_dataset(df_train, "train.csv", FALSE)
  
  # Predict info
  df_test <<- read.csv2(paste0("./data/raw/", "test.csv"), sep = ",") %>% as.data.table()
  
  # Get center and meal data
  df_center <<- read.csv2(paste0("./data/raw/", "fulfilment_center_info.csv"), sep = ",") %>% as.data.table()
  df_meal <<- read.csv2(paste0("./data/raw/", "meal_info.csv"), sep = ",") %>% as.data.table()
}

get_shiny_data_ch <- function() {
  
  # Get center and meal data
  df_center <<- read.csv2(paste0("./data/clickhouse/", "center.csv"), sep = ";") %>% as.data.table()
  df_meal <<- read.csv2(paste0("./data/clickhouse/", "meal.csv"), sep = ";") %>% as.data.table()
  
  # Train info
  df_train <<- read.csv2(paste0("./data/clickhouse/", "train.csv"), sep = ";") %>% as.data.table()
  df_orders_set_up <<- preprocess_dataset(df_train, "train.csv", FALSE)
  
  # Predict info
  df_test <<- read.csv2(paste0("./data/clickhouse/", "test.csv"), sep = ";") %>% as.data.table()
  
}

get_data_predict <- function(center, meal) {
  
  # Filter data with center_id and meal_id
  # 
  df_pred_orders <- df_orders_set_up %>%
    # filter(meal_id == as.integer(meal))
    filter((center_id == as.integer(center)) & (meal_id == as.integer(meal)))
  
  # Preprocessed train dataset
  df_pred_orders <- preprocess_dataset(df_pred_orders, "pred_train.csv", save = FALSE)
  
  # Get test dataframe and it's preprocessed
  df_pred_test <- df_test %>%
    filter((center_id == as.integer(center)) & (meal_id == as.integer(meal))) %>%
    preprocess_dataset("pred_test.csv", save = FALSE)
  
  return(list(df_pred_orders, df_pred_test))
}
