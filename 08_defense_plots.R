## [Title]:  Data Visualization
## [Author]: Kevin Neal
## [Date]:   April 20, 2022

setwd("C:/Users/nealk/OneDrive - University of Oklahoma/Research/Thesis/Data/")

library(sf)
library(tidyr)
library(tidyverse)
library(ggplot2)

## [Imports]:
parcels <- st_read("shapefiles/tri_county/sa_02_parcels2014_untransformed.shp")


ggplot(parcels) +
geom_histogram(aes(x = totalPop))

path.names <- list.files("csv/bioPhysical/" , pattern = ".csv")

csvs <- lapply(path.names , read.csv)

names(csvs) <- path.names

df.plots <- data.frame(otherCount = csvs$`00_otherCount.csv`$count ,
                       treesCount = csvs$`01_treesCount.csv`$count ,
                       grassCount = csvs$`02_grassCount.csv`$count ,
                       ndviMean   = csvs$`03_ndviMean.csv`$mean)

df.plots <- df.plots %>%
            mutate(perTrees = treesCount / (otherCount + treesCount + grassCount) * 100 ,
                   perGrass = grassCount / (otherCount + treesCount + grassCount) * 100) %>%
            na.omit()

df.plots.l <- df.plots                                                                %>%
              pivot_longer(cols = one_of("perTrees" , "perGrass") ,
                           names_to  = "vegetation_type" ,
                           values_to = "percentage")                                  %>%
              mutate(vegetation_type = gsub("perTrees" , "Trees" , vegetation_type) ,
                     vegetation_type = gsub("perGrass" , "Grass" , vegetation_type))  %>%
              filter(percentage > 0)


## [Grass and Tree Scatterplot]:
grass <- df.plots.l %>% filter(vegetation_type == "Grass" , percentage > 0)
trees <- df.plots.l %>% filter(vegetation_type == "Trees" , percentage > 0)

df.stats <- data.frame(vegetation_type = c("Trees" , "Grass") ,
                       r2    = rep(NA , 2) ,
                       slope = rep(NA , 2))

stats.trees <- summary(lm(grass$ndviMean ~ grass$percentage))
stats.grass <- summary(lm(trees$ndviMean ~ trees$percentage))

df.stats[df.stats$vegetation_type == "Trees" , "r2"]    <- round(stats.trees$r.squared       , 4)
df.stats[df.stats$vegetation_type == "Trees" , "slope"] <- round(stats.trees$coefficients[2] , 4)

df.stats[df.stats$vegetation_type == "Grass" , "r2"]    <- round(stats.grass$r.squared       , 4)
df.stats[df.stats$vegetation_type == "Grass" , "slope"] <- round(stats.grass$coefficients[2] , 4)



p1 <- ggplot(df.plots.l , 
             aes(x = percentage ,
                 y = ndviMean)) +
      geom_point(size = 0.5 ,
                 color = "darkgreen" ,
                 aes(x = percentage  ,
                     y = ndviMean)) +
      geom_smooth(method  = "lm"  ,
                  color   = "red" ,
                  formula = y ~ x ,
                  aes(x = percentage ,
                      y = ndviMean)) +
      facet_wrap(~ vegetation_type) +
      scale_y_continuous(limits = c(-1 , 1)) +
      labs(x = "Percentage of Coverage in Parcel (%)" ,
           y = "Mean NDVI of Parcel") +
      theme_bw() +
      theme(text = element_text(size = 9 , family = "serif" , face = "bold"))








density.scat.treesGrass <- ggplot(df.plots.l , 
                                  aes(x = percentage ,
                                      y = ndviMean)) +
                              geom_bin2d(bins = 500) +
                              geom_smooth(method  = "lm"  ,
                                          color   = "red" ,
                                          size = 0.25 ,
                                          formula = y ~ x ,
                                          aes(x = percentage ,
                                              y = ndviMean)) +
                              facet_wrap(~ vegetation_type) +
                              scale_y_continuous(limits = c(-1 , 1)) +
                              labs(x = "Percentage of Coverage in Parcel (%)" ,
                                   y = "Mean NDVI of Parcel" ,
                                   fill = "Density Aggregation") +
                              theme_bw() +
                              theme(text = element_text(size = 9 , family = "serif" , face = "bold") ,
                                    legend.position = "bottom")























ggsave("C:/Users/nealk/OneDrive - University of Oklahoma/Research/Thesis/Results/presentation/grassTrees_densityplot.tiff" ,
       density.scat.treesGrass ,
       dpi = 300   ,
       width  = 5 ,
       height = 2.6  ,
       units  = "in")


## [Redline Maps]:
parcels.redline <- parcels %>%
                   filter(redline != "0")

p2 <- ggplot() +
      geom_sf(data = parcels.redline ,
              aes(fill = redline) ,
              color = "black" ,
              size = 0.0005) +
      scale_fill_manual(values = c("green" , "yellow" , "orange" , "red")) +
      labs(fill = "Redline Classification") +
      theme_bw() +
      theme(text = element_text(size = 9 , family = "serif" , face = "bold") ,
            legend.position = "bottom")


ggsave("C:/Users/nealk/OneDrive - University of Oklahoma/Research/Thesis/Results/presentation/redline_districts.tiff" ,
       p2 ,
       dpi = 300   ,
       width  = 5 ,
       height = 10  ,
       units  = "in")













