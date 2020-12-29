preprocess_dataset <- function(df, filename, save = T) {
  
  # Add date to dataframe
  df_result <- df %>% 
    mutate(
      date = as.Date("2017-01-01") + weeks(week - 1)
    ) 
  
  # Get center if not exists their columns 
  if (!("center_type" %in% colnames(df_result)) | !("region_code" %in% colnames(df_result))) {
    # df_center <- read.csv2("./data/raw/fulfilment_center_info.csv", sep = ",") %>% as.data.table()
    
    # Join with input dataframe
    df_result <- df_result %>% 
      inner_join(df_center, by = "center_id")
  }
  
  # Get meal if not exists their columns
  if (!("category" %in% colnames(df_result)) | !("cuisine" %in% colnames(df_result))) {
    # df_meal <- read.csv2("./data/raw/meal_info.csv", sep = ",") %>% as.data.table()
  
    # Join with input dataframe
    df_result <- df_result %>% 
      inner_join(df_meal, by = "meal_id")
  }
  
  # Cast columns to numerics
  if (!is.numeric(df_result$checkout_price)) {
    df_result$checkout_price <- df_result$checkout_price %>% as.numeric()  
  }
  
  if (!is.numeric(df_result$base_price)) {
    df_result$base_price <- df_result$base_price %>% as.numeric()
  }

  if (!is.numeric(df_result$op_area)) {
    df_result$op_area <- df_result$op_area %>% as.numeric()
  }
  
  # Add some specific date vars
  df_result$day <- df_result$date %>% wday()
  df_result$month <- df_result$date %>% month()
  df_result$year <- df_result$date %>% year()
  df_result$quarter <- df_result$date %>% quarter()
  
  # Select numeric cols
  numeric_cols <- unlist(lapply(df_result, is.numeric))
  
  if(save) {
    df_result %>% 
      write.csv2(paste0("./data/processed/", filename), sep = ";", row.names = FALSE)  
  }
  return(df_result)
}
