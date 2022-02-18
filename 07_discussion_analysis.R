library(rgdal)

##################
## Data
shape.parcel  <- readOGR("C:/Users/nealk/OneDrive - University of Oklahoma/Research/Thesis/Data/shapefiles/tri_county" , "sa_02_parcels2014")

shape.parcel$perTrees <- ((sin(shape.parcel$perTrees)) ^ 2) * 100

independent <- c("medianAge" , "driveAlone" , "carpool" , "workTravel" , "ged"    , "associates" , "bachelors" , 
                 "graduate"  , "owned"      , "rented"  , "occupied"   , "vacant" , "houseAge"   , "medIncome" , 
                 "redline"   , "ecoregion"  , "areaFT"  , "perGrass"   , "meanNDVI")

for(i in 1 : ncol(shape.parcel)){
  column <- names(shape.parcel)[i]
  
  if(column %in% independent){
    if(!is.element(column , c("areaFT" , "medianAge" , "workTravel" , "houseAge" , "medIncome" , "redline" , "ecoregion" , "meanNDVI"))){
      un.transform <- ((sin(shape.parcel@data[, names(shape.parcel) == column])) ^ 2) * 100
      
      shape.parcel@data[, names(shape.parcel) == column] <- ((sin(shape.parcel@data[, names(shape.parcel) == column])) ^ 2) * 100
    }
  }
  
  if(column %in% c( "perGrass")){ # "perTrees" ,
    shape.parcel@data[, names(shape.parcel) == column] <- ((sin(shape.parcel@data[, names(shape.parcel) == column])) ^ 2) * 100
  }
}

high.high <- shape.parcel[shape.parcel$lisaTest == 4 ,]
high.high <- high.high[high.high$meanNDVI > 0.11467 & high.high$perTrees > 12.92 ,]

redline.A <- shape.parcel[shape.parcel$redline == "A" ,]
redline.B <- shape.parcel[shape.parcel$redline == "B" ,]
redline.C <- shape.parcel[shape.parcel$redline == "C" ,]
redline.D <- shape.parcel[shape.parcel$redline == "D" ,]

writeOGR(shape.parcel ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_02_parcels2014_untransformed" ,
         driver = "ESRI Shapefile" ,
         overwrite_layer = T)

plot(shape.parcel$medIncome , shape.parcel$meanNDVI)
abline(lm(shape.parcel$meanNDVI ~ shape.parcel$medIncome))
