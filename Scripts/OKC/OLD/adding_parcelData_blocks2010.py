## [Title]: Adding Parcel Information to Blocks 2010
## [Author]: Kevin Neal
## [Date]: August 11, 2020

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
env.workspace = "D:/Research/Thesis/Data/shapefiles/Study_Area"
env.overwriteOutput = True

###########################
## 2. Shapefiles
blocks2010 = "sa_01_blocks2010.shp"
parcel2014 = "sa_01_parcels2014_residential.shp"

###########################
## 3. Clipping parcel data to add up features that are residential
output      = "D:/Research/Thesis/Data/shapefiles/temp/"                # Output path to shorten other lines
blocks_temp = output + "blocks_temp.shp"                                # New blocks shapefile location
parcel_temp = output + "parcels_temp.shp"                               # New parcels shapefile location

cursor = arcpy.UpdateCursor(blocks2010)                                 # Cursor to update parcels field

blocks = [f for f in arcpy.da.SearchCursor(blocks2010 , "GEOID10")]     # Creates a list of GEOIDs used to clip each block

arcpy.MakeFeatureLayer_management(blocks2010 , "blocks2010")            # MUST BE CALLED SO Select by Attributes may be used!!!!!
arcpy.MakeFeatureLayer_management(parcel2014 , "parcels2014")           # Brings the shapefile into the map to be selected

quarter  = str(len(blocks) * 0.25)
half     = str(len(blocks) * 0.50)
quarter3 = str(len(blocks) * 0.75)

quarter  = int(quarter.split(".")[0])
half     = int(half.split(".")[0])
quarter3 = int(quarter3.split(".")[0])

i = 0
start = time.time()

print "[Beginning]: Counting residential houses in each GEOID"

for row in cursor:
    block = str(blocks[i])
    block = block.split("'")[1]

    whereClause = """"GEOID10" = """ + "'" + block + "'"               # SQL query for Select

    arcpy.Select_analysis(blocks2010  ,                                # Selects the blocks that are in the respective tract
                          blocks_temp ,
                          whereClause)

    arcpy.Clip_analysis(parcel2014  ,                                  # Clips the parcels shapefile to the new blocks shapefile
                        blocks_temp ,
                        parcel_temp)

    houses = int(arcpy.GetCount_management(parcel_temp)[0])            # Counts number of features in the clipped parcel shapefile

    row.setValue("parcels" , houses)                                   # Inserts the amount of residential features into the temp row
    cursor.updateRow(row)                                              # Updates row with the new parcels data

    ## Print statements so I know where the iteration is at and time duration
    if i == quarter:
        end = time.time()
        duration = end - start
        duration = time_convert(duration)

        print "[Progress]: 25%"
        print "[Duration]: " + duration
        print ""

    if i == half:
        end = time.time()
        duration = end - start
        duration = time_convert(duration)

        print "[Progress]: 50%"
        print "[Duration]: " + duration
        print ""

    if i == quarter3:
        end = time.time()
        duration = end - start
        duration = time_convert(duration)

        print "[Progress]: 75%"
        print "[Duration]: " + duration
        print ""

    i = i + 1

end = time.time()
duration = end - start
duration = time_convert(duration)

print "END"
print "[Duration]:  " + str(duration)
print ""

