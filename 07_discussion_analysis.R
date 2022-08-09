library(rgdal)
library(dplyr)
library(ggplot2)

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

# Extracting the statistically significant parcels
shape.parcel2 <- shape.parcel[shape.parcel$lisaTest > 0 ,]


df.data2 <- shape.parcel@data %>%
            select(-CLUCat : -uniqueID , -countOther : -countTrees) %>%
            group_by(redline) %>%
            summarize(totalPop   = round(mean(totalPop   , na.rm = T) , 4) ,
                      medianAge  = round(mean(medianAge  , na.rm = T) , 4) ,
                      driveAlone = round(mean(driveAlone , na.rm = T) , 4) ,
                      carpool    = round(mean(carpool    , na.rm = T) , 4) ,
                      workTravel = round(mean(workTravel , na.rm = T) , 4) ,
                      ged        = round(mean(workTravel , na.rm = T) , 4) ,
                      associates = round(mean(associates , na.rm = T) , 4) ,
                      bachelors  = round(mean(bachelors  , na.rm = T) , 4) ,
                      graduate   = round(mean(graduate   , na.rm = T) , 4) ,
                      owned      = round(mean(owned      , na.rm = T) , 4) ,
                      rented     = round(mean(rented     , na.rm = T) , 4) ,
                      occupied   = round(mean(occupied   , na.rm = T) , 4) ,
                      vacant     = round(mean(vacant     , na.rm = T) , 4) ,
                      houseAge   = round(mean(houseAge   , na.rm = T) , 4) ,
                      medIncome  = round(mean(medIncome  , na.rm = T) , 4) ,
                      areaFT     = round(mean(areaFT     , na.rm = T) , 4) ,
                      perGrass   = round(mean(perGrass   , na.rm = T) , 4) ,
                      perTrees   = round(mean(perTrees   , na.rm = T) , 4) ,
                      meanNDVI   = round(mean(meanNDVI   , na.rm = T) , 4) ,
                      moransI    = round(mean(moransI    , na.rm = T) , 4) ,
                      fitted     = round(mean(fitted     , na.rm = T) , 4))


df.plots <- shape.parcel2@data %>%
            select(fitted , meanNDVI , moransI)

lm.fitted <- lm(df.plots$meanNDVI ~ df.plots$fitted)

summary(lm.fitted)

ggplot(df.plots) +
geom_point(aes(x = fitted ,
               y = meanNDVI)) +
geom_smooth(method = "lm" ,
            se = F ,
            aes(x = fitted ,
                y = meanNDVI)) +
scale_y_continuous(limits = c(-1 , 1)) +
scale_x_continuous(limits = c(-1 , 2) ,
                   breaks = seq(-1 , 2 , by = 0.5)) +
labs(x = "Statistical Fitted Values" ,
     y = "Mean NDVI") +
theme_bw() +
theme(text = element_text(size = 9 , family = "serif" , face = "bold"))



ggplot(df.plots) +
geom_point(aes(x = fitted ,
               y = moransI)) +
geom_hline(yintercept = 0 ,
           color = "red" ,
           size  = 1) +
geom_vline(xintercept = 0 ,
           color = "black" ,
           size = 1) +
scale_x_continuous(limits = c(-1 , 2) ,
                   breaks = seq(-1 , 2 , by = 0.5)) +
labs(x = "Statistical Fitted Values" ,
     y = "Moran's - I Statistic") +
theme_bw() +
theme(text = element_text(size = 9 , family = "serif" , face = "bold"))











write.csv(df.data2 ,
          "C:/Users/nealk/OneDrive - University of Oklahoma/Research/Thesis/Results/discussionStats.csv" ,
          row.names = F)



writeOGR(shape.parcel ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_02_parcels2014_untransformed" ,
         driver = "ESRI Shapefile" ,
         overwrite_layer = T)

plot(shape.parcel$medIncome , shape.parcel$meanNDVI)
abline(lm(shape.parcel$meanNDVI ~ shape.parcel$medIncome))
