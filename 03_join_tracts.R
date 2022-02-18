## [Title]:  Join Census Survey Data to Tract Shapefiles
## [Author]: Kevin Neal
## [Date]:   May 31, 2021

library(rgdal)
library(stringr)

##############################
## Data
all.counties        <- read.csv("E:/Research/Thesis/Data/csv/00_censusData_Oklahoma_Cleveland_Canadian.csv" , stringsAsFactors = F)
shape.tracts.full   <- readOGR( "E:/Research/Thesis/Data/shapefiles/tri_county" , "okc_00_tracts2014")
shape.tracts.clip   <- readOGR( "E:/Research/Thesis/Data/shapefiles/tri_county" ,  "sa_00_tracts2014")
percent.tracts.clip <- readOGR( "E:/Research/Thesis/Data/shapefiles/tri_county" ,  "sa_00_tracts2014")

df.tracts <- shape.tracts.clip@data
df.full   <- shape.tracts.full@data

tract.cols <- c("TRACTCE" , "parcels")                                                      # Columns to keep
df.tracts <- df.tracts[, names(df.tracts) %in% tract.cols]                                  # Removing columns 
df.tracts <- df.tracts[, tract.cols]                                                        # Reordering columns

##############################
## Adding Columns
remove.cols <- c("Tract" , "Tract2")

csv.cols <- names(all.counties)
csv.cols <- csv.cols[!is.element(csv.cols , remove.cols)]

## A loop to add columns to the end of the shapefile attribute table
for(i in 1 : length(csv.cols) - length(remove.cols)){
  temp.col <- rep(0 , nrow(df.tracts))                                          # Creates NA vector of the same length of the shapefile
  
  df.tracts <- cbind(df.tracts , temp.col)                                      # Adds temp column to the end of the attribute table
}

names(df.tracts)[which(names(df.tracts) == "temp.col")] <- csv.cols             # Changes temp column names to something useful

##############################
## Joining data to shapefile (tracts dataset)
for(i in 1 : nrow(all.counties)){
  tract <- all.counties$Tract2[i]                                               # Collects i-th tract
  
  index <- which(df.tracts$TRACTCE == tract)                                    # Finds the index that the tract is in
  
  ## Some tracts in the dataset may not be present in the shapefile. If the
  ## length of the index is null or zero, this condition is not met and the
  ## loop continues to the iteration.
  if(length(index) != 0){
    temp.info <- as.numeric(all.counties[i , names(all.counties) %in% csv.cols])     # Creates a temp data.frame to collect the information stored in the tract
    
    df.tracts[index , names(df.tracts) %in% csv.cols] <- temp.info                   # Stores tract surveys in the respective tract in the attribute table
  }
}

##############################
## Apply parcel weights to clipped sections
conversion.cols <- c("population_16over" , "totalPop"   , "driveAlone" , "carpool"  ,  
                     "ged"               , "associates" , "bachelors"  , "graduate" , 
                     "totalHouses"       , "owned"      , "rented"     , "occupied" , "vacant")

for(i in 1 : nrow(df.tracts)){
  tract <- df.tracts$TRACTCE[i]                                                       # Collecting i-th tract
  
  index.full <- which(df.full$TRACTCE == tract)                                       # Finding the associated index in tracts full shapefile
  
  if(length(index.full) != 0){
    parcel.sa   <- as.numeric(df.tracts$parcels[i])                                   # Associated total number of parcels for tract
    parcel.full <- as.numeric(df.full$parcels[index.full])                            # Associated total number of parcels for tract full shapefile
    
    temp.info <- df.tracts[i , names(df.tracts) %in% csv.cols]                        # Census survey data associated with the tract

    if(parcel.sa != parcel.full){
      weight <- parcel.sa / parcel.full                                               # Weight to multiply census data by
      
      if(is.infinite(weight)){
        df.tracts[i , names(df.tracts) %in% names(temp.info)] <- temp.info * 0
      }
      
      if(weight == 0){
        df.tracts[i , names(df.tracts) %in% names(temp.info)] <- temp.info * 0
      }
      
      if(weight != 0){
        for(j in 1 : length(conversion.cols)){
          column <- conversion.cols[j]                                                 # Collecting j-th column

          tract.index <- which(names(df.tracts) == column)                             # Finding column index associated with j-th column in tract clipped shapefile
          info.index  <- which(names(temp.info) == column)                             # Finding column index associated with j-th column in temporary data.frame
          
          temp.info[, names(temp.info) == column] <- as.numeric(temp.info[, info.index] * weight)
          
        }
        
        df.tracts[i , names(df.tracts) %in% names(temp.info)] <- temp.info
      }
    }
  }
}

names(df.tracts)[names(df.tracts) == "travelTime_work_minutes"] <- "workTravel"            # Changing column name to something ArcMap can use
names(df.tracts)[names(df.tracts) == "population_16over"]       <- "pop16"
names(df.tracts)[names(df.tracts) == "totalHouses"]             <- "totHouses"

##############################
## Conversion to percentages
df.percents <- df.tracts

df.percents$pop16 <- round(df.percents$pop16)                                              # Rounds population over 16 column to prevent a fraction of a person belonging to a tract
df.percents$totalPop <- round(df.percents$totalPop)                                        # Rounds population column to prevent a fraction of a person belonging to a tract
df.percents$totHouses <- round(df.percents$totHouses)                                      # Rounds total houses column to prevent a fraction of a house belonging to a tract

for(i in 1 : nrow(df.percents)){
  population16    <- df.percents$pop16[i]
  population      <- df.percents$totalPop[i]
  total.houses    <- df.percents$totHouses[i]
  occupied.houses <- df.percents$occupied[i]
  
  df.percents$carpool[i]    <- round(df.percents$carpool[i]    / population16 * 100 , digits = 2)
  df.percents$driveAlone[i] <- round(df.percents$driveAlone[i] / population16 * 100 , digits = 2)
  
  df.percents$ged[i]        <- round(df.percents$ged[i]        / population * 100 , digits = 2)
  df.percents$associates[i] <- round(df.percents$associates[i] / population * 100 , digits = 2)
  df.percents$bachelors[i]  <- round(df.percents$bachelors[i]  / population * 100 , digits = 2)
  df.percents$graduate[i]   <- round(df.percents$graduate[i]   / population * 100 , digits = 2)

  df.percents$occupied[i] <- round(df.percents$occupied[i] / total.houses * 100 , digits = 2)
  df.percents$vacant[i]   <- round(df.percents$vacant[i]   / total.houses * 100 , digits = 2)

  df.percents$owned[i]  <- round(df.percents$owned[i]  / occupied.houses * 100 , digits = 2)
  df.percents$rented[i] <- round(df.percents$rented[i] / occupied.houses * 100 , digits = 2)

}

df.percents[is.na(df.percents)] <- 0

##############################
## Saving new shapefile
shape.tracts.clip@data   <- df.tracts                                                      # Replacing old data with new area weighted information
percent.tracts.clip@data <- df.percents                                                    # Replacing old data with new area weighted information and rounded

writeOGR(shape.tracts.clip ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_01_tracts2014"  ,
         overwrite_layer = T ,
         driver = "ESRI Shapefile")

writeOGR(percent.tracts.clip ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_01_tracts2014_percent"  ,
         overwrite_layer = T ,
         driver = "ESRI Shapefile")














