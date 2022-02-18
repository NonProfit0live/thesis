## [Title]: Calulating Tree and Grass Percentage
## [Author]: Kevin Neal
## [Date]: February 23, 2021

import os
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
## 2. Data (shapefiles and rasters)
shapesPath = "E:/Research/Thesis/Data/shapefiles/tri_county/"
blocks   = shapesPath + "sa_00_blocks2010.shp"
tracts   = shapesPath + "sa_00_tracts2014.shp"
counties = shapesPath + "sa_00_counties.shp"
eco3     = shapesPath + "sa_00_eco3.shp"

tempPath     = "E:/Research/Thesis/Data/shapefiles/temp/"
rastTemp     = tempPath + "raster_temp.tif"
shapeTemp    = tempPath + "shape_temp.shp"

classificationOKC = "E:/Research/Thesis/Data/rasters/OKC_Classification.tif"

parcels = []
rasters = []

parcelPath = "E:/Research/Thesis/Data/shapefiles/parcels/"
rasterPath = "E:/Research/Thesis/Data/rasters/parcels/"
parcelList = os.listdir(parcelPath)
rasterList = os.listdir(rasterPath)

for file in parcelList:
    if file.find("residential") == -1 and file.endswith(".shp"):
        parcels.append(file)

parcels.sort()

## This will not work in PyCharm but works in ArcMap
# print "[Splitting Raster Up]: Beginning"
# print ""
#
# for i in range(len(parcels)):
#     parcel = parcelPath + parcels[i]
#
#     num = i + 1
#
#     if i < 9:
#         rasterOut = rasterPath + "0" + str(num) + "_parcel.tif"
#
#     else:
#         rasterOut = rasterPath + str(num) + "_parcel.tif"
#
#     arcpy.gp.ExtractByMask_sa(classificationOKC , parcel , rasterOut)
#
#     print "     [Extract by Mask]: " + rasterOut.split("/")[len(rasterOut.split("/")) -1]
#
#     i += 1
#
# print "[Splitting Raster Up]: End"
# print ""

for file in rasterList:
    if file.endswith(".tif"):
        rasters.append(file)

rasters.sort()

###########################
## 3. Calculating Percentages Function
# studyArea      = eco3
# classification = classificationOKC


def percentages(studyArea , classification ):
    cursor   = arcpy.UpdateCursor(studyArea)
    features = [f for f in arcpy.da.SearchCursor(studyArea , "uniqueID")]
    features = [item for t in features for item in t]

    quarter  = int(str(len(features) * 0.25).split(".")[0])
    half     = int(str(len(features) * 0.50).split(".")[0])
    quarter3 = int(str(len(features) * 0.75).split(".")[0])

    i = 0
    start = time.time()

    for row in cursor:
        feature = str(features[i])

        whereClause = '"' + "uniqueID" + '" = ' + feature               # SQL query for Select

        arcpy.Select_analysis(studyArea , shapeTemp , whereClause)

        temp = arcpy.gp.ExtractByMask_sa(classification , shapeTemp , rastTemp)

        count = [f for f in arcpy.da.SearchCursor(arcpy.BuildRasterAttributeTable_management(temp) , "Count")]
        value = [f for f in arcpy.da.SearchCursor(arcpy.BuildRasterAttributeTable_management(temp) , "Value")]

        count = [item for t in count for item in t]                                                                     # Typecasting tuple to list
        value = [item for t in value for item in t]                                                                     # Typecasting tuple to list

        if len(value) == 1 and value[0] == 0:
            trees = 0.00
            grass = 0.00

            countOther = count[0]
            countTrees = 0
            countGrass = 0

        if len(value) == 2:
            if value[1] == 1:
                trees = (count[1] / sum(count)) * 100
                grass = 0.00

                countOther = count[0]
                countTrees = count[1]
                countGrass = 0

            if value[1] == 2:
                trees = 0.00
                grass = (count[1] / sum(count)) * 100

                countOther = count[0]
                countTrees = 0
                countGrass = count[1]

        if len(value) == 3:
            trees = (count[1] / sum(count)) * 100
            grass = (count[2] / sum(count)) * 100

            countOther = count[0]
            countTrees = count[1]
            countGrass = count[2]

        row.setValue("countOther" , countOther)
        row.setValue("countTrees" , countTrees)
        row.setValue("countGrass" , countGrass)
        row.setValue("perTrees"   , trees)
        row.setValue("perGrass"   , grass)

        cursor.updateRow(row)

        ## Print statements so I know where the iteration is at and time duration
        i  += 1
        end = time.time()

        if i == quarter:
            duration = end - start
            duration = time_convert(duration)

            print "            - [Progress]: 25%"
            print "            - [Duration]: " + str(duration)
            print ""

        if i == half:
            duration = end - start
            duration = time_convert(duration)

            print "            - [Progress]: 50%"
            print "            - [Duration]: " + str(duration)
            print ""

        if i == quarter3:
            duration = end - start
            duration = time_convert(duration)

            print "            - [Progress]: 75%"
            print "            - [Duration]: " + str(duration)
            print ""

    end = time.time()
    duration = end - start
    duration = time_convert(duration)

    print "END"
    print "[Duration]:  " + str(duration)
    print ""
    print ""

###########################
## 4. Calling Function
# percentages(eco3     , classificationOKC)
# percentages(counties , classificationOKC)
# percentages(tracts   , classificationOKC)
# percentages(blocks   , classificationOKC)

for k in range(len(parcels)):
    shapefile = parcelPath + parcels[k]
    raster    = rasterPath + rasters[k]

    print "[Beginning]: " + shapefile.split("/")[len(shapefile.split("/")) - 1]

    percentages(shapefile , raster , "Parcels")

    k += 1

