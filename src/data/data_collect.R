source('src/features/preprocessing.R')

get_shiny_data <- function() {
  
  df_train <<- read.csv2(paste0("./data/raw/", "train.csv"), sep = ",") %>% as.data.table()
  df_orders <<- preprocess_dataset(df_train, "train.csv", FALSE)
  
  # Get center and meal data
  df_center <<- read.csv2(paste0("./data/raw/", "fulfilment_center_info.csv"), sep = ",") %>% as.data.table()
  df_meal <<- read.csv2(paste0("./data/raw/", "meal_info.csv"), sep = ",") %>% as.data.table()
}