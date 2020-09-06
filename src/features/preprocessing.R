preprocess_dataset <- function(df, filename) {
  
  # Get center and meal data
  df_center <- read.csv2(paste0("./data/raw/", files_info$file$name[1]), sep = ",") %>% as.data.table()
  df_meal <- read.csv2(paste0("./data/raw/", files_info$file$name[2]), sep = ",") %>% as.data.table()
  
  # Join with input dataframe
  df_tmp <- df %>% 
    inner_join(df_center, by = "center_id")
  
  df_result <- df_tmp %>% 
    inner_join(df_meal, by = "meal_id")
  
  # Add date to dataframe
  df_result <- df_result %>% 
    mutate(
      date = as.Date("2017-01-01") + weeks(week)
    ) 
  
  # Cast columns to numerics
  df_result$checkout_price <- df_result$checkout_price %>% as.numeric()
  df_result$base_price <- df_result$base_price %>% as.numeric()
  df_result$op_area <- df_result$op_area %>% as.numeric()
  
  # Select numeric cols
  numeric_cols <- unlist(lapply(df_result, is.numeric))
  
  df_result %>% 
    write.csv2(paste0("./data/processed/", filename), sep = ";", row.names = FALSE)
  
  return(df_result)
}