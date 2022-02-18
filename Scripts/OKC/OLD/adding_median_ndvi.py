## [Title]:  Calculating Median NDVI Value
## [Author]: Kevin Neal
## [Date]:   3-26-2021

import os
import pandas
import time
import arcpy
from arcpy import env

arcpy.CheckOutExtension("Spatial")

###########################
## 0. Time conversion function
def time_convert(seconds):
    seconds  = seconds % (24 * 3600)
    hour     = seconds // 3600
    seconds %= 3600
    minutes  = seconds // 60
    seconds %= 60

    return "%d:%02d:%02d" % (hour, minutes, seconds)

###########################
## 1. Environment Variables
env.overwriteOutput = True

###########################
## 2. Shapefiles and CSV Files
parcels = "E:/Research/Thesis/Data/shapefiles/tri_county/sa_00_parcels2014.shp"

df = pandas.read_csv("E:/Research/Thesis/Data/csv/OKC_ndviMean.csv")

cursor   = arcpy.UpdateCursor(parcels)
features = [f for f in arcpy.da.SearchCursor(parcels , "uniqueID")]

i = 0

for row in cursor:
    feature = int(features[i][0])

    csvID    = int(df.iloc[i , 0])
    ndviMean = df.iloc[i , 1]

    if pandas.isnull(df.iloc[i , 1]):
        ndviMean = 0.00

    if feature == csvID:
        row.setValue("ndviMean" , ndviMean)

        cursor.updateRow(row)

    i += 1

