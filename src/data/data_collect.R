source('src/features/preprocessing.R')

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

get_data_predict <- function(center, meal) {
  
  # Filter data with center_id and meal_id
  # 
  df_pred_orders <- df_orders_set_up %>%
    # filter(meal_id == as.integer(meal))
    filter((center_id == as.integer(center)) & (meal_id == as.integer(meal)))
  
  # Preprocessed train dataset
  df_pred_orders <- preprocess_dataset(df, "pred_train.csv", save = FALSE)
  
  # Get test dataframe and it's preprocessed
  df_pred_test <- df_test %>%
    filter((center_id == as.integer(center)) & (meal_id == as.integer(meal))) %>%
    preprocess_dataset("pred_test.csv", save = FALSE)
  
  return(list(df_pred_orders, df_pred_test))
}
