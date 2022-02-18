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
env.workspace = "D:/Research/Thesis/Data/shapefiles"
env.overwriteOutput = True

###########################
## 2. Shapefiles
okc_tracts2014 = "okc_01_tracts2014.shp"
sa_tracts2014  = env.workspace + "/Study_Area/sa_01_tracts2014.shp"
okc_parcel2014 = "okc_01_parcels2014_residential.shp"

###########################
## 3. Temp Shapefiles
output      = "D:/Research/Thesis/Data/shapefiles/temp/"                # Output path to shorten other lines
tracts_temp = output + "tracts_temp.shp"                                # New tracts  shapefile location
parcel_temp = output + "parcels_temp.shp"                               # New parcels shapefile location

arcpy.MakeFeatureLayer_management(okc_parcel2014 , "parcels2014")       # Brings the shapefile into the map to be selected

###########################
## 4. OKC Tracts
okTract_cursor = arcpy.UpdateCursor(okc_tracts2014)                        # Cursor to update OKC tracts field

okc_tracts = [f for f in arcpy.da.SearchCursor(okc_tracts2014 , "GEOID")]  # Creates a list of GEOIDs used to clip each tract

arcpy.MakeFeatureLayer_management(okc_tracts2014 , "okc_tracts")           # Bringing okc_tracts into the map for selection

quarter  = str(len(okc_tracts) * 0.25)
half     = str(len(okc_tracts) * 0.50)
quarter3 = str(len(okc_tracts) * 0.75)

quarter  = int(quarter.split(".")[0])
half     = int(half.split(".")[0])
quarter3 = int(quarter3.split(".")[0])

i = 0
start = time.time()

print "[Shapefile]: okc_01_tracts2014.shp"
print "[Beginning]: Counting residential houses in each GEOID"
print ""

for row in okTract_cursor:
    tract = str(okc_tracts[i])
    tract = tract.split("'")[1]

    whereClause = """"GEOID" = """ + "'" + tract + "'"                 # SQL query for Select

    arcpy.Select_analysis(okc_tracts2014  ,                            # Selects the blocks that are in the respective tract
                          tracts_temp ,
                          whereClause)

    arcpy.Clip_analysis(okc_parcel2014  ,                              # Clips the parcels shapefile to the new blocks shapefile
                        tracts_temp ,
                        parcel_temp)

    houses = int(arcpy.GetCount_management(parcel_temp)[0])            # Counts number of features in the clipped parcel shapefile

    row.setValue("parcels" , houses)                                   # Inserts the amount of residential features into the temp row
    okTract_cursor.updateRow(row)                                      # Updates row with the new parcels data

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

###########################
## 5. Study Area Tracts
saTract_cursor = arcpy.UpdateCursor(sa_tracts2014)                             # Cursor to update SA  tracts field
sa_tracts      = [f for f in arcpy.da.SearchCursor(sa_tracts2014  , "GEOID")]  # Creates a list of GEOIDs used to clip each tract

arcpy.MakeFeatureLayer_management(sa_tracts2014  , "sa_tracts")

quarter  = str(len(sa_tracts) * 0.25)
half     = str(len(sa_tracts) * 0.50)
quarter3 = str(len(sa_tracts) * 0.75)

quarter  = int(quarter.split(".")[0])
half     = int(half.split(".")[0])
quarter3 = int(quarter3.split(".")[0])

i = 0
start    = time.time()

print "[Shapefile]: sa_01_tracts2014.shp"
print "[Beginning]: Counting residential houses in each GEOID"
print ""

## SA Tracts 2014
for row in saTract_cursor:
    tract = str(sa_tracts[i])
    tract = tract.split("'")[1]

    whereClause = """"GEOID" = """ + "'" + tract + "'"                 # SQL query for Select

    arcpy.Select_analysis(sa_tracts2014  ,                            # Selects the blocks that are in the respective tract
                          tracts_temp ,
                          whereClause)

    arcpy.Clip_analysis(okc_parcel2014  ,                              # Clips the parcels shapefile to the new blocks shapefile
                        tracts_temp ,
                        parcel_temp)

    houses = int(arcpy.GetCount_management(parcel_temp)[0])            # Counts number of features in the clipped parcel shapefile

    row.setValue("parcels" , houses)                                   # Inserts the amount of residential features into the temp row
    saTract_cursor.updateRow(row)                                      # Updates row with the new parcels data

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






