## [Title]:  Statistical Analysis
## [Author]: Kevin Neal
## [Date]:   April 25, 2021

library(spdep)
library(rgdal)
library(scales)
library(ggplot2)
library(stringr)
library(spatialEco)

##################
## Data
shape.parcel  <- readOGR("E:/Research/Thesis/Data/shapefiles/tri_county" , "sa_01_parcels2014")
shape.parcel2 <- shape.parcel

shape.parcel2$redline   <- as.factor(shape.parcel2$redline)
shape.parcel2$ecoregion <- as.factor(shape.parcel2$ecoregion)

shape.parcel2$houseAge[shape.parcel2$houseAge == 0] <- NA                               # Changes year built values to NA if there was no recorded year the house was built.

no.data  <- c(107101 , 400101 , 501003)
extremes <- c(107500 , 107808 , 108404 , 202106 , 301410)

shape.parcel2 <- shape.parcel2[!is.element(shape.parcel2$TRACTCE , no.data)  ,]             # Census tracts with no data or outside of Canadian, Cleveland, and Oklahoma counties
shape.parcel2 <- shape.parcel2[!is.element(shape.parcel2$TRACTCE , extremes) ,]             # Census tracts with extreme values

shape.parcel2 <- sp.na.omit(shape.parcel2)

##################
## Simple Linear Regression
## Continuous Columns
# continuous.cols <- c("totalPop" , "medianAge"  , "driveAlone" , "carpool"   , "workTravel" ,
#                      "ged"      , "associates" , "bachelors"  , "graduate"  , "owned"      ,
#                      "rented"   , "occupied"   , "vacant"     , "houseAge"  , "medIncome"  ,
#                      "perTrees" , "perGrass")
# 
# texts <- c("Total Population"     , "Median Household Age" , "Percent Driving Alone"   , "Percent Carpooling"  ,
#            "Travel Time to Work"  , "Percent GED"          , "Percent Associates"      , "Percent Bachelors"   ,
#            "Percent Graduate"     , "Percent Owned"        , "Percent Rented"          , "Percent Occupied"    ,
#            "Percent Vacant"       , "House Age"            , "Median Household Income" , "Percentage of Trees" ,
#            "Percentage of Grass")
# 
# for(i in 1 : length(continuous.cols)){
#   column <- continuous.cols[i]
#   text   <- texts[i]
# 
#   df.temp <- df.parcel[, names(df.parcel) == column]
# 
#   regression <- summary(lm(df.parcel$meanNDVI ~ df.temp))
# 
#   stat.r <- format(regression$r.squared           , scientific = F)
#   stat.p <- format(regression$coefficients[1 , 4] , scientific = F)
# 
#   intercept <- format(regression$coefficients[1 , 1] , scientific = F)
#   slope     <- format(regression$coefficients[2 , 1] , scientific = F)
#   equation  <- paste("y = " , intercept , " + " , slope , "x" , sep = "")
# 
#   if(grepl("-" , slope)){
#     slope2 <- gsub("-" , "" , slope)
#     equation <- paste("y = " , intercept , " - " , slope2 , "x" , sep = "")
#   }
# 
#   plot <- ggplot(df.parcel ,
#                  aes(x = df.temp ,
#                      y = meanNDVI)) +
#     geom_point(color = "red" ,
#                size = 0.1) +
#     geom_smooth(formula = y ~ x ,
#                 method  = "lm") +
#     ylim(-1 , 1) +
#     theme(plot.caption = element_text(hjust = 0)) +
#     labs(title    = "OKC Statistical Analysis" ,
#          subtitle = paste(text , " v. Mean NDVI" , sep = "") ,
#          x = text ,
#          y = "Mean NDVI" ,
#          caption = paste(equation , "\n" ,
#                          "[" , expression(R^2) , "]: " , stat.r , "\n" ,
#                          "[P-Value]: " , stat.p , sep = ""))
# 
#   if(column == "medIncome"){  plot <- plot + scale_x_continuous(labels = comma) }
# 
#   ggsave(plot = plot ,
#          filename = paste("E:/Research/Thesis/Results/ols/" , column , ".tiff" , sep = "") ,
#          height = 4 ,
#          width = 8  ,
#          dpi = 300 ,
#          units = "in")
# }

## Discrete Columns
# discrete.cols <- c("redline" , "ecoregion")
# texts2        <- c("Redline House" , "Ecoregion")
# 
# for(i in 1 : length(discrete.cols)){
#   column <- discrete.cols[i]
#   text   <- texts2[i]
# 
#   df.temp <- df.parcel[, names(df.parcel) == column]
# 
#   plot <- ggplot(df.parcel ,
#                  aes(x = df.temp ,
#                      y = meanNDVI)) +
#     geom_point(color = "red" ,
#                size  = 0.1) +
#     ylim(-1 , 1) +
#     labs(title = "OKC Statistical Analysis" ,
#          subtitle = paste(text , " v. Mean NDVI" , sep = "") ,
#          x = text ,
#          y = "Mean NDVI")
# 
#   ggsave(plot = plot ,
#          filename = paste("E:/Research/Thesis/Results/ols/" , column , ".tiff" , sep = "") ,
#          height = 4 ,
#          width = 8  ,
#          dpi = 300 ,
#          units = "in")
# }

##################
## Arcsine Transformation
independent <- c("medianAge" , "driveAlone" , "carpool" , "workTravel" , "ged"    , "associates" , "bachelors" , 
                 "graduate"  , "owned"      , "rented"  , "occupied"   , "vacant" , "houseAge"   , "medIncome" , 
                 "redline"   , "ecoregion"  , "areaFT"  , "perGrass"   , "meanNDVI")

for(i in 1 : ncol(shape.parcel2)){
  column <- names(shape.parcel2)[i]
  
  if(column %in% independent){
    if(!is.element(column , c("areaFT" , "medianAge" , "workTravel" , "houseAge" , "medIncome" , "redline" , "ecoregion" , "meanNDVI"))){
      non.percentage <- shape.parcel2@data[, names(shape.parcel2) == column] / 100
      
      shape.parcel2@data[, names(shape.parcel2) == column] <- asin(sqrt(non.percentage))
    }
  }
  
  if(column %in% c("perTrees" , "perGrass")){
    non.percentage <- shape.parcel2@data[, names(shape.parcel2) == column] / 100
    
    shape.parcel2@data[, names(shape.parcel2) == column] <- asin(sqrt(non.percentage))
  }
}

##################
## Simple Ordinary Least Squares
## Testing for what dependent variable to use in the main statistical analysis
test.trees <- lm(shape.parcel2@data$meanNDVI ~ shape.parcel2@data$perTrees)     # [Adjusted R2]: 0.66
test.grass <- lm(shape.parcel2@data$meanNDVI ~ shape.parcel2@data$perGrass)     # [Adjusted R2]: 0.09

summary(test.trees)
summary(test.grass)

##################
## Multiple Ordinary Least Squares
multi.formula <- as.formula(paste("shape.parcel2@data$perTrees ~ " , paste(independent , collapse = "+")))

multiple.regression <- lm(multi.formula , shape.parcel2@data)

summary(multiple.regression)

independent.new <- independent[!independent %in% c("associates" , "vacant")]

multi.formula <- as.formula(paste("shape.parcel2@data$perTrees ~ " , paste(independent.new , collapse = "+")))

multiple.regression2 <- lm(multi.formula , shape.parcel2@data)

summary(multiple.regression2)

AIC(multiple.regression)                                                        # [AIC]: -320288.4
AIC(multiple.regression2)                                                       # [AIC]: -320288.4 <- USE THIS ONE, as every independent variable is statistically significant

shape.parcel2$fitted <- multiple.regression2$fitted.values

##################
## Summary Statistics
description.independent <- c("Median household age"                  , "Percentage driving alone"            , "Percentage driving carpool"       , "Average commute time (minutes)"    , "Percentage having a GED" , 
                             "Percentage having a bachelor's degree" , "Percentage having a graduate degree" , "Percentage houses that are owned" , "Percentage houses that are rented" , 
                             "Percentage houses that are occupied"   , "Age of house (years)"                , "Median household income"          , "Redline neighborhoods"             , 
                             "Ecoregion"                             , "Area of parcel (feet squared)"       , "Percentage grass"                 , "Mean NDVI")

df.summaryStats <- data.frame(Variables   = independent.new ,
                              Description = description.independent ,
                              Type        = rep(NA , length(independent.new)) ,
                              Range       = rep(NA , length(independent.new)) ,
                              Mean        = rep(NA , length(independent.new)) ,
                              Median      = rep(NA , length(independent.new)) ,
                              StDev       = rep(NA , length(independent.new)))

for(i in 1 : length(independent.new)){
  column <- independent.new[i]

  df.column <- shape.parcel2@data[, names(shape.parcel2@data) == column]

  if(class(df.column) != "factor"){
    stat.range <- range(df.column  , na.rm = T)
    
    df.summaryStats$Type[i]   <- str_to_title(class(df.column))
    df.summaryStats$Range[i]  <- paste(round(stat.range[1] , digits = 4) , " - " , round(stat.range[2] , digits = 4) , sep = "")
    df.summaryStats$Mean[i]   <- round(mean(df.column   , na.rm = T) , digits = 4)
    df.summaryStats$Median[i] <- round(median(df.column , na.rm = T) , digits = 4)
    df.summaryStats$StDev[i]  <- round(sd(df.column     , na.rm = T) , digits = 4)
  }
  
  if(class(df.column) == "factor"){
    df.summaryStats$Type[i]  <- str_to_title(class(df.column))
    df.summaryStats$Range[i] <- paste(levels(df.column) , collapse = ", ")
  }
}

write.csv(df.summaryStats , 
          "E:/Research/Thesis/Results/summaryStats.csv" ,
          row.names = F)

df.summaryStats2 <- data.frame(Variables   = "perTrees" ,
                               Description = "Percentage trees" ,
                               Type        = rep(NA , 1) ,
                               Range       = rep(NA , 1) ,
                               Mean        = rep(NA , 1) ,
                               Median      = rep(NA , 1) ,
                               StDev       = rep(NA , 1))

df.column <- shape.parcel2@data$perTrees

stat.range <- range(df.column , na.rm = T)

df.summaryStats2$Type   <- "Numeric"
df.summaryStats2$Range  <- paste(round(stat.range[1] , digits = 4) , " - " , round(stat.range[2] , digits = 4) , sep = "")
df.summaryStats2$Mean   <- round(mean(df.column   , na.rm = T) , digits = 4)
df.summaryStats2$Median <- round(median(df.column , na.rm = T) , digits = 4)
df.summaryStats2$StDev  <- round(sd(df.column     , na.rm = T) , digits = 4)

##################
## Spatial Autocorrelation
neighbors <- poly2nb(shape.parcel2 , queen = T)                                                    # Creates a neighbors shapefile

list.weights <- nb2listw(neighbors , style = "W" , zero.policy = T)                                # List of neighbors per feature and if there are no connections, then zero.policy provides a 0

globalMoran <- moran.test(shape.parcel2$fitted , list.weights , zero.policy = T)                   # [Moran's I Statistic]: .6828 <- positive spatial autocorrelation, meaning spatial clustering
localMoran  <- localmoran(shape.parcel2$fitted , list.weights , zero.policy = T)

morans.mc <- moran.mc(shape.parcel2$fitted  , list.weights , zero.policy = T , nsim = 999)         # Monte-Carlo analysis to test multiple parameters

shape.parcel2$moransI <- localMoran[, 1]                                                           # Adding local moran's-i statistic to shapefile
shape.parcel2$pValue  <- localMoran[, 5]                                                           # Adding local p-value statistic

mean.fitted <- shape.parcel2$fitted  - mean(shape.parcel2$fitted)                                  # Centers the fitted regression model around the mean
mean.local  <- shape.parcel2$moransI - mean(shape.parcel2$moransI)                                 # Centers the local Moran's I around the mean

p.threshold <- 0.001

shape.parcel2$lisaTest <- NA

for(i in 1 : nrow(shape.parcel2)){
  mean.fit <- mean.fitted[i]
  mean.loc <- mean.local[i]
  p.value  <- localMoran[i , 5]
  
  if(is.na(p.value)){
    p.value <- 999
  }
  
  if(p.value <= p.threshold){
    if(mean.fit < 0 & mean.loc < 0){ shape.parcel2$lisaTest[i] <- 1 }                              # Low  - Low
    if(mean.fit < 0 & mean.loc > 0){ shape.parcel2$lisaTest[i] <- 2 }                              # Low  - High
    if(mean.fit > 0 & mean.loc < 0){ shape.parcel2$lisaTest[i] <- 3 }                              # High - Low
    if(mean.fit > 0 & mean.loc > 0){ shape.parcel2$lisaTest[i] <- 4 }                              # High - High
  }
  
  if(p.value > p.threshold){
    shape.parcel2$lisaTest[i] <- 0                                                                 # Statistically Insignificant
  }
}

sum(shape.parcel2$lisaTest == 0)
sum(shape.parcel2$lisaTest == 1)
sum(shape.parcel2$lisaTest == 2)
sum(shape.parcel2$lisaTest == 3)
sum(shape.parcel2$lisaTest == 4)




##################
## Export
writeOGR(shape.parcel2 ,
         "E:/Research/Thesis/Data/shapefiles/tri_county" ,
         "sa_02_parcels2014"       ,
         driver = "ESRI Shapefile" ,
         overwrite_layer = T)









