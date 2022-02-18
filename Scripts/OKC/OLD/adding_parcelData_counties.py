## [Title]: Adding Parcel Information to Counties
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
sa_counties   = "sa_01_counties.shp"
sa_parcel2014 = "sa_01_parcels2014_residential.shp"

###########################
## 3. Temp Shapefiles
output      = "D:/Research/Thesis/Data/shapefiles/temp/"                 # Output path to shorten other lines
county_temp = output + "county_temp.shp"                                 # New county  shapefile location
parcel_temp = output + "parcels_temp.shp"                                # New parcels shapefile location

arcpy.MakeFeatureLayer_management(sa_parcel2014 , "parcels2014")         # Brings the shapefile into the map to be selected
arcpy.MakeFeatureLayer_management(sa_counties   , "counties")

###########################
## 4. SA Counties
cursor = arcpy.UpdateCursor(sa_counties)                                 # Cursor to update SA counties field

counties = [f for f in arcpy.da.SearchCursor(sa_counties , "NAME")]      # Creates a list of NAME used to clip each county

i = 0
start = time.time()

print "[Shapefile]: sa_01_eco3.shp"
print "[Beginning]: Counting residential houses in each NAME"
print ""

for row in cursor:
    county = str(counties[i])
    county = county.split("'")[1]

    whereClause = """"NAME" = """ + "'" + county + "'"                   # SQL query for Select

    arcpy.Select_analysis(sa_counties  ,                                 # Selects the counties that are in the respective county
                          county_temp ,
                          whereClause)

    arcpy.Clip_analysis(sa_parcel2014 ,                                  # Clips the parcels shapefile to the new blocks shapefile
                        county_temp      ,
                        parcel_temp)

    houses = int(arcpy.GetCount_management(parcel_temp)[0])              # Counts number of features in the clipped parcel shapefile

    row.setValue("parcels" , houses)                                     # Inserts the amount of residential features into the temp row
    cursor.updateRow(row)                                                # Updates row with the new parcels data

    print "[" + county + "]: Completed"

    i = i + 1

end = time.time()
duration = end - start
duration = time_convert(duration)

print ""
print "END"
print "[Duration]:  " + str(duration)
print ""