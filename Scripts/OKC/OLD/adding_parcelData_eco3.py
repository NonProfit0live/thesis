## [Title]: Adding Parcel Information to Ecoregion Level 3
## [Author]: Kevin Neal
## [Date]: August 14, 2020

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

    return "%d:%02d:%02d" % (hour , minutes , seconds)

###########################
## 1. Environment Variables
env.workspace = "D:/Research/Thesis/Data/shapefiles/Study_Area"
env.overwriteOutput = True

###########################
## 2. Shapefiles
sa_eco3       = "sa_01_eco3.shp"
sa_parcel2014 = "sa_01_parcels2014_residential.shp"

###########################
## 3. Temp Shapefiles
output      = "D:/Research/Thesis/Data/shapefiles/temp/"                 # Output path to shorten other lines
eco_temp    = output + "eco_temp.shp"                                    # New ecoregion  shapefile location
parcel_temp = output + "parcels_temp.shp"                                # New parcels shapefile location

arcpy.MakeFeatureLayer_management(sa_parcel2014 , "parcels2014")         # Brings the shapefile into the map to be selected
arcpy.MakeFeatureLayer_management(sa_eco3       , "eco3")

###########################
## 4. SA Ecoregion
cursor = arcpy.UpdateCursor(sa_eco3)                                     # Cursor to update SA ecoregion field

eco_regions = [f for f in arcpy.da.SearchCursor(sa_eco3 , "na_l3name")]  # Creates a list of Ecoregion names used to clip each ecoregion

i = 0
start = time.time()

print "[Shapefile]: sa_01_eco3.shp"
print "[Beginning]: Counting residential houses in each na_l3name"
print ""

for row in cursor:
    eco_region = str(eco_regions[i])
    eco_region = eco_region.split("'")[1]

    whereClause = """"na_l3name" = """ + "'" + eco_region + "'"          # SQL query for Select

    arcpy.Select_analysis(sa_eco3  ,                                     # Selects the blocks that are in the respective ecoregion
                          eco_temp ,
                          whereClause)

    arcpy.Clip_analysis(sa_parcel2014 ,                                  # Clips the parcels shapefile to the new ecoregion shapefile
                        eco_temp      ,
                        parcel_temp)

    houses = int(arcpy.GetCount_management(parcel_temp)[0])              # Counts number of features in the clipped parcel shapefile

    row.setValue("parcels" , houses)                                     # Inserts the amount of residential features into the temp row
    cursor.updateRow(row)                                                # Updates row with the new parcels data

    print "[" + eco_region + "]: Completed"

    i = i + 1

end = time.time()
duration = end - start
duration = time_convert(duration)

print "END"
print "[Duration]:  " + str(duration)
print ""