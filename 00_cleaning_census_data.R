## [Title]:  Cleaning Census Data
## [Author]: Kevin Neal
## [Date]:   May 28, 2021

library(stringr)

########################################
## 1. Importing csv lists
## CSVs are stored in folders for easier iteration in loops
commuting.files <- list.files("E:/Research/Thesis/Data/csv/commuting/" , full.names = T)
commuting.list  <- sapply(commuting.files  , read.csv , simplify = F)

demographics.files <- list.files("E:/Research/Thesis/Data/csv/demographics/" , full.names = T)
demographics.list <- sapply(demographics.files , read.csv , simplify = F)

education.files <- list.files("E:/Research/Thesis/Data/csv/education/" , full.names = T)
education.list  <- sapply(education.files , read.csv , simplify = F)

housing.files <- list.files("E:/Research/Thesis/Data/csv/housing/" , full.names = T)
housing.list  <- sapply(housing.files , read.csv , simplify = F)

income.files <- list.files("E:/Research/Thesis/Data/csv/income/" , full.names = T)
income.list  <- sapply(income.files , read.csv , simplify = F)

########################################
## 2. Combining each county into one csv
# Columns to keep from the Census metadata
commuting.cols <- c("NAME" , "S0801_C01_001E" , "S0801_C01_004E" , "S0801_C01_003E" , "S0801_C01_046E"            )
demo.cols      <- c("NAME" , "DP05_0001E"     , "DP05_0017E"                                                      )
education.cols <- c("NAME" , "B07009_003E"    , "B07009_004E"    , "B07009_005E"    , "B07009_006E"               )  # totalPop column for percent conversion
housing.cols   <- c("NAME" , "DP04_0026E"     , "DP04_0044E"     , "DP04_0003E"     , "DP04_0045E"  , "DP04_0046E")  # totalHouses column for occupied/vacant -- occupied column owned/rented for percent conversion
income.cols    <- c("NAME" , "S1901_C01_012E"                                                                     )

column.names <- c("Tract" ,
                  "population_16over" , "percent_carpool" , "percent_driveAlone" , "travelTime_work_minutes"     ,    # Commuting data
                  "totalPop"          , "medianAge"                                                              ,    # Demographic data
                  "ged"               , "associates"         , "bachelors"       , "graduate"                    ,    # Education data
                  "totalHouses"       , "occupied"           , "vacant"          , "owned"    , "rented"         ,    # Housing data
                  "medIncome")                                                                                        # Income data

csv.names <- c("Canadian" , "Cleveland" , "Oklahoma")

counties.list <- list(data.frame() , data.frame() , data.frame())

names(counties.list) <- csv.names

for(i in 1 : length(counties.list)){
  temp.commuting <- commuting.list[[i]]                                                            # Collects the i-th data.frame of the list
  temp.demo      <- demographics.list[[i]]
  temp.education <- education.list[[i]]
  temp.housing   <- housing.list[[i]]
  temp.income    <- income.list[[i]]
  
  temp.commuting <- temp.commuting[order(temp.commuting$NAME) ,]                                   # Orders census data by census tract                     
  temp.demo      <- temp.demo[order(temp.demo$NAME)           ,]
  temp.education <- temp.education[order(temp.education$NAME) ,]
  temp.housing   <- temp.housing[order(temp.housing$NAME)     ,]
  temp.income    <- temp.income[order(temp.income$NAME)       ,]
  
  temp.commuting <- temp.commuting[, names(temp.commuting) %in% commuting.cols]                    # Removes columns not specified in the 'keep columns vectors' (section 2)
  temp.demo      <- temp.demo[,      names(temp.demo)      %in% demo.cols]
  temp.education <- temp.education[, names(temp.education) %in% education.cols]
  temp.housing   <- temp.housing[,   names(temp.housing)   %in% housing.cols]
  temp.income    <- temp.income[,    names(temp.income)    %in% income.cols]
  
  temp.commuting <- temp.commuting[, commuting.cols]
  temp.demo      <- temp.demo[,      demo.cols]
  temp.education <- temp.education[, education.cols]
  temp.housing   <- temp.housing[,   housing.cols]
  temp.income    <- temp.income[,    income.cols]
  
  counties.list[[i]] <- cbind(temp.commuting , temp.demo[, -1] , temp.education[, -1] , temp.housing[, -1] , temp.income[, -1])
  
  names(counties.list[[i]]) <- column.names                                                        # Changes column names to make it easier to understand what each column represents
}

all.counties <- rbind(counties.list$Oklahoma , counties.list$Cleveland , counties.list$Canadian)   # Combining datasets into one dataframe. Ordered by tract numbers


all.counties <- all.counties[all.counties$Tract != "Geographic Area Name" ,]                       # Removes row containing "Geographic Area Name", information row

all.counties$Tract2 <- NA

# Changing specific columns to numeric. 
# [NAs are introduced for]:
#    - Row tract 107101 where no census data reported
#    - Column travelTime_work_minutes where "N" is reported instead of minutes

string.cols <- c("Tract" , "Tract2")

for(i in 1 : ncol(all.counties)){
  column <- names(all.counties)[i]
  
  if(!is.element(column , string.cols)){
    all.counties[, names(all.counties) == column] <- as.numeric(all.counties[, names(all.counties) == column])
  }
}

## Changing percent carpool and percent drive alone to population values
all.counties$carpool    <- rep(0 , nrow(all.counties))
all.counties$driveAlone <- rep(0 , nrow(all.counties))

for(i in 1 : nrow(all.counties)){
  driving.pop <- all.counties$population_16over[i]
  
  all.counties$driveAlone[i] <- (all.counties$percent_driveAlone[i] * driving.pop) / 100
  all.counties$carpool[i]    <- (all.counties$percent_carpool[i]    * driving.pop) / 100
  
}

new.cols <- c("Tract"      , "Tract2"    , "population_16over" , "carpool"    , "driveAlone" , "travelTime_work_minutes" , 
              "totalPop"   , "medianAge" , "ged"               , "associates" , "bachelors"  , "graduate"                , "totalHouses" ,
               "occupied"  , "vacant"    , "owned"             , "rented"     , "medIncome")

all.counties <- all.counties[, new.cols]                                                            # Reorder columns

## Changing tracts to a uniform numerical system of 6 digits and no periods
for(i in 1 : nrow(all.counties)){
  tract <- all.counties$Tract[i]                                                                    # Collecting i-th tract value
  tract <- strsplit(tract , " ")[[1]][3]                                                            # Collecting the third split of the string, numbers only
  tract <- gsub("," , "" , tract)                                                                   # Removing comma
  
  ## Tract containing a period
  if(grepl("[.]" , tract)){ 
    tract <- gsub("[.]" , "" , tract)                                                               # Removing period
  }
  
  ## Tract that is not split up into smaller tracts
  if(nchar(tract) == 4){
    tract <- str_pad(tract , 6 , side = "right" , pad = "0")                                       # Adds zeros at the end of tract numbers. Limits to 6 digits
  }
  
  all.counties$Tract2[i] <- tract                                                                  # Replaces old tract with modified new tract number into i-th place
}

all.counties <- all.counties[all.counties$Tract2 != "107101" ,]

########################################
## 5. Saving CSVs
write.csv(all.counties ,                                                                               # Saving updated census data combined into one csv
          "E:/Research/Thesis/Data/csv/00_censusData_Oklahoma_Cleveland_Canadian.csv" ,
          row.names = F)









