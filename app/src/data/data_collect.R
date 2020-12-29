source('src/features/preprocessing.R')

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
  
  # Get raw data
  ## Meal
  query = "SELECT * FROM raw.meal"
  output_path <- "./data/clickhouse/meal.csv"
  dbGetQuery(con_ch, query) %>% as.data.frame() %>% write.csv2(output_path, quote = F, row.names = F)
  
  ## Center
  query = "SELECT * FROM raw.center"
  output_path <- "./data/clickhouse/center.csv"
  dbGetQuery(con_ch, query) %>% as.data.frame() %>% write.csv2(output_path, quote = F, row.names = F)
  
  ## Train
  query = "SELECT * FROM raw.test"
  output_path <- "./data/clickhouse/test.csv"
  dbGetQuery(con_ch, query) %>% as.data.frame() %>% write.csv2(output_path, quote = F, row.names = F)
  
  ## Train
  query = "SELECT * FROM raw.train"
  output_path <- "./data/clickhouse/train.csv"
  dbGetQuery(con_ch, query) %>% as.data.frame() %>% write.csv2(output_path, quote = F, row.names = F)
  
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
  
  # Train info
  df_train <<- read.csv2(paste0("./data/clickhouse/", "train.csv"), sep = ";") %>% as.data.table()
  df_orders_set_up <<- preprocess_dataset(df_train, "train.csv", FALSE)
  
  # Predict info
  df_test <<- read.csv2(paste0("./data/clickhouse/", "test.csv"), sep = ";") %>% as.data.table()
  
  # Get center and meal data
  df_center <<- read.csv2(paste0("./data/clickhouse/", "fulfilment_center_info.csv"), sep = ";") %>% as.data.table()
  df_meal <<- read.csv2(paste0("./data/clickhouse/", "meal_info.csv"), sep = ";") %>% as.data.table()
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
