#load data
library(readr)

account <-  read_csv("temp/sc_account.csv")
inspection <- read_csv("temp/sc_inspection.csv")
checklist <- read_csv("temp/sc_checklist.csv")

#change data structure

inspection_list <- list()

for ( i in 1:nrow(inspection)){
  inspect <- inspection[i,]
  if(length(inspection_list[inspect$user_id][[1]]) == 0){
    inspection_list[[inspect$user_id]] <- c()
  }
  inspection_list[inspect$user_id] <- 
}

#merge data

#export JSON 