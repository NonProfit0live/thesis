## [Title]:  Cleaning Parcel Data
## [Author]: Kevin Neal
## [Date]:   April 23, 2021

library(rgdal)

##################
## Data
shape.parcel.full <- readOGR("E:/Research/Thesis/Data/shapefiles/tri_county" , "okc_00_parcels2014")

df.parcel <- shape.parcel.full@data

##################
## Reducing columns
keep.columns <- c("CLUCat" , "YearBuilt")

df.parcel <- df.parcel[, names(df.parcel) %in% keep.columns]
df.parcel <- df.parcel[, keep.columns]

##################
## Adding columns
new.columns <- c("TRACTCE"    , "uniqueID"   , "totalPop"  , "medianAge" , "driveAlone" , "carpool" , "workTravel" , 
                 "ged"        , "associates" , "bachelors" , "graduate"  , "owned"      , "rented"  , "occupied"   , 
                 "vacant"     , "medIncome"  , "houseAge"  , "redline"   , "ecoregion"  , "areaFT"  , "countOther" ,
                 "countGrass" , "countTrees" , "perGrass"  , "perTrees"  , "meanNDVI")

for(i in 1 : length(new.columns)){
  temp.col <- rep(0 , nrow(df.parcel))
  
  df.parcel <- cbind(df.parcel , temp.col)
}

names(df.parcel)[which(names(df.parcel) == "temp.col")] <- new.columns

df.parcel$uniqueID  <- rep(1 : nrow(df.parcel) , 1)
df.parcel$redline   <- as.character(df.parcel$redline)
df.parcel$ecoregion <- as.character(df.parcel$ecoregion)

##################
## Conversions for year house built to house age
for(i in 1 : nrow(df.parcel)){
  year.built <- df.parcel$YearBuilt[i]
  
  if(year.built == 0){
    df.parcel$houseAge[i] <- 0
  }
  
  if(year.built != 0){
    df.parcel$houseAge[i] <- 2015 - year.built
  }
}

##################
## Reordering columns
ordered.columns <- c("CLUCat"     , "TRACTCE"   , "uniqueID" , "totalPop"   , "medianAge"  , "driveAlone" , "carpool"   , "workTravel" , "ged"       , 
                     "associates" , "bachelors" , "graduate" , "owned"      , "rented"     , "occupied"   , "vacant"    , "houseAge"   , "medIncome" , 
                     "redline"    , "ecoregion" , "areaFT"   , "countOther" , "countGrass" , "countTrees" , "perGrass"  , "perTrees"   , "meanNDVI")

df.parcel <- df.parcel[, names(df.parcel) %in% ordered.columns]
df.parcel <- df.parcel[, ordered.columns]

shape.parcel.full@data <- df.parcel

##################
## Saving New Shapefile
writeOGR(shape.parcel.full ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "okc_01_parcels2014" ,
         overwrite_layer = T  ,
         driver = "ESRI Shapefile")

##################
## [Complete in QGIS]:
##    - Points on Surface geoprocess of okc_01_parcels2014.shp

