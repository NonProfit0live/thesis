## [Title]:  Adding Tract Information to Parcel Shapefile
## [Author]: Kevin Neal
## [Date]:   April 17, 2021

library(rgdal)

##################
## Data
shape.tracts        <- readOGR("E:/Research/Thesis/Data/shapefiles/tri_county" , "sa_01_tracts2014")
shape.parcelPercent <- readOGR("E:/Research/Thesis/Data/shapefiles/tri_county" , "sa_01_parcels2014")

df.tracts        <- shape.tracts@data
df.parcelPercent <- shape.parcelPercent@data

###########################
## 3. Joining tract data to blocks (parcel weighted)
non.conversion.cols <- c("medianAge" , "workTravel" , "medIncome")

census.cols <- c("totalPop" , "medianAge"  , "driveAlone" , "carpool"  , "workTravel" ,
                 "ged"      , "associates" , "bachelors"  , "graduate" , "owned"      ,
                 "rented"   , "occupied"   , "vacant"     , "medIncome")

commute.conversion   <- c("driveAlone" , "carpool")
education.conversion <- c("ged"        , "associates" , "bachelors"  , "graduate")
housing1.conversion  <- c("owned"      , "rented")
housing2.conversion  <- c("occupied"   , "vacant")

## Parcel weighted dissaggregation
for(i in 1 : nrow(df.tracts)){
  tract <- as.numeric(df.tracts$TRACTCE[i])
  
  parcel.rows <- which(df.parcelPercent$TRACTCE == tract)
  
  if(length(parcel.rows) != 0){
    temp.info <- df.tracts[i ,]
    
    parcels <- as.numeric(df.tracts$parcels[i])
    
    weight <- 1 / parcels

    for(j in 1 : length(census.cols)){
      column <- census.cols[j]                                                 # Collecting j-th column
      
      if(column == "totalPop"){
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- round(as.numeric(temp.info[, names(temp.info) == column] * weight))
      }
        
      if(column %in% commute.conversion){
        weighted.col <- temp.info[, names(temp.info) == column] * weight
        
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- round((weighted.col / temp.info$pop16) * 100 , digits = 4)
      }
        
      if(column %in% education.conversion){
        weighted.col <- temp.info[, names(temp.info) == column] * weight
        
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- round((weighted.col / temp.info$totalPop) * 100 , digits = 4)
      }
        
      if(column %in% housing1.conversion){
        weighted.col <- temp.info[, names(temp.info) == column] * weight
        
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- round((weighted.col / temp.info$occupied) * 100 , digits = 4)
      }
        
      if(column %in% housing2.conversion){
        weighted.col <- temp.info[, names(temp.info) == column] * weight
        
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- round((weighted.col / temp.info$totHouses) * 100 , digits = 4)
      }
      
      if(column %in% non.conversion.cols){
        df.parcelPercent[parcel.rows , names(df.parcelPercent) == column] <- as.numeric(temp.info[, names(temp.info) == column])
      }
    }
  }
}

shape.parcelPercent@data <- df.parcelPercent

##################
## Saving New Shapefile
writeOGR(shape.parcelPercent ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_01_parcels2014"       ,
         driver = "ESRI Shapefile" ,
         overwrite_layer = T)










