## [Title]:  Adding Tract Information to Each Parcel
## [Author]: Kevin Neal
## [Date]:   April 17, 2021

import time
import arcpy
from arcpy import env

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
parcel2014 = shapesPath + "sa_01_parcels2014.shp"
tracts2014 = shapesPath + "sa_01_tracts2014.shp"

tempPath     = "E:/Research/Thesis/Data/shapefiles/temp/"
shapeTemp    = tempPath + "shape_temp.shp"

###########################
## 3. Assigning Tracts to Parcels
print "[Beginning]: Adding census tract number to parcel shapefile"

tracts = [f for f in arcpy.da.SearchCursor(tracts2014 , "TRACTCE")]
tracts = [item for t in tracts for item in t]

arcpy.MakeFeatureLayer_management(parcel2014 , "parcels")

i = 0
start    = time.time()

quarter  = str(len(tracts) * 0.25)
half     = str(len(tracts) * 0.50)
quarter3 = str(len(tracts) * 0.75)

quarter  = int(quarter.split(".")[0])
half     = int(half.split(".")[0])
quarter3 = int(quarter3.split(".")[0])

for tract in tracts:
    tract = str(tract)
    whereClause = '"' + "TRACTCE" + '" = ' + "'" + tract + "'"

    arcpy.Select_analysis(tracts2014 , shapeTemp , whereClause)

    arcpy.MakeFeatureLayer_management(shapeTemp , "temp")

    arcpy.SelectLayerByLocation_management("parcels" ,
                                           "WITHIN"  ,
                                           "temp"    ,
                                           selection_type = "NEW_SELECTION")

    arcpy.CalculateField_management("parcels" ,
                                    "TRACTCE" ,
                                    tract     ,
                                    "PYTHON")

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