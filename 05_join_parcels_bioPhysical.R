## [Title]:  Adding Bio-physical Columns to Parcel Shapefile
## [Author]: Kevin Neal
## [Date]:   April 25, 2021

library(rgdal)

##################
## Data
shape.parcel <- readOGR("E:/Research/Thesis/Data/shapefiles/tri_county" , "sa_01_parcels2014")
df.parcel    <- shape.parcel@data

bio.files <- list.files("E:/Research/Thesis/Data/csv/bioPhysical/" , full.names = T)
bio.list  <- sapply(bio.files , read.csv , simplify = F)

csv.names <- c("otherCount" , "treesCount" , "grassCount" , "meanNDVI")

names(bio.list) <- csv.names

###########################
## Adding tree and grass data to parcels shapefile
for(i in 1 : nrow(df.parcel)){
  other.id  <- bio.list$otherCount$uniqueID[i]
  trees.id  <- bio.list$treesCount$uniqueID[i]
  grass.id  <- bio.list$grassCount$uniqueID[i]
  mean.id   <- bio.list$meanNDVI$uniqueID[i]
  parcel.id <- df.parcel$uniqueID[i]

  if((parcel.id == other.id) & (parcel.id == trees.id) & (parcel.id == grass.id) & (parcel.id == mean.id)){
    df.parcel$countOther[i] <- bio.list$otherCount$count[i]
    df.parcel$countTrees[i] <- bio.list$treesCount$count[i]
    df.parcel$countGrass[i] <- bio.list$grassCount$count[i]
    
    total <- df.parcel$countOther[i] + df.parcel$countGrass[i] + df.parcel$countTrees[i]
    
    if(total != 0){
      df.parcel$perGrass[i] <- round((df.parcel$countGrass[i] / total) * 100 , digits = 2)
      df.parcel$perTrees[i] <- round((df.parcel$countTrees[i] / total) * 100 , digits = 2)
    }
    
    if(total == 0){
      df.parcel$perGrass[i] <- 0.00
      df.parcel$perTrees[i] <- 0.00
    }

    df.parcel$meanNDVI[i] <- round(bio.list$meanNDVI$mean[i] , digits = 5)
  }
}

###########################
## Saving updated parcel shapefile
shape.parcel@data <- df.parcel

writeOGR(shape.parcel ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_01_parcels2014"       ,
         driver = "ESRI Shapefile" ,
         overwrite_layer = T)
