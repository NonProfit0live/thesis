## [Title]: Adding Ecoregion Information to sa_tracts2014
## [Author]: Kevin Neal
## [Date]: August 31, 2020

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
env.workspace = "E:/Research/Thesis/Data/shapefiles/Study_Area/"
env.overwriteOutput = True

###########################
## 2. Shapefiles
sa_eco3       = "sa_03_eco3.shp"
sa_tracts2014 = "sa_03_tracts2014.shp"
sa_parcels    = "sa_01_parcels2014_residential.shp"
sa_timbers    = "sa_03_tracts2014_timbers.shp"
sa_plains     = "sa_03_tracts2014_plains.shp"

###########################
## 3. Temp Shapefiles
output      = "E:/Research/Thesis/Data/shapefiles/temp/"                 # Output path to shorten other lines
eco_temp    = output + "eco_temp.shp"                                    # New ecoregion  shapefile location
tracts_temp = output + "tracts_temp.shp"                                 # New tracts shapefile location
parcel_temp = output + "parcels_temp.shp"                                # New parcels shapefile location

arcpy.MakeFeatureLayer_management(sa_eco3       , "eco3")
arcpy.MakeFeatureLayer_management(sa_tracts2014 , "tracts")

###########################
## 4. SA Tracts
cursor_tracts = arcpy.UpdateCursor(sa_tracts2014)
cursor_eco3   = arcpy.UpdateCursor(sa_eco3)
cursor_timber = arcpy.UpdateCursor(sa_timbers)
cursor_plains = arcpy.UpdateCursor(sa_plains)

ecoregions = [f for f in arcpy.da.SearchCursor(sa_eco3       , "na_l3name")]
tracts     = [f for f in arcpy.da.SearchCursor(sa_tracts2014 , "TRACTCE")]

timber_eco_tracts = [f for f in arcpy.da.SearchCursor(sa_timbers , "TRACTCE")]
plains_eco_tracts = [f for f in arcpy.da.SearchCursor(sa_plains  , "TRACTCE")]

## Collecting tracts in each ecoregion
i = 0

for i in range(len(ecoregions)):
    ecoregion = str(ecoregions[i])
    ecoregion = ecoregion.split("'")[1]

    whereClause = """"na_l3name" = """ + "'" + ecoregion + "'"

    arcpy.Select_analysis(sa_eco3  ,
                          eco_temp ,
                          whereClause)

    arcpy.Clip_analysis(sa_tracts2014 ,
                        eco_temp ,
                        tracts_temp)

    if ecoregion == "Central Great Plains":
        plains_tracts  = [f for f in arcpy.da.SearchCursor(tracts_temp , "TRACTCE")]

    if ecoregion == "Cross Timbers":
        timbers_tracts = [f for f in arcpy.da.SearchCursor(tracts_temp , "TRACTCE")]

    i += 1

# Changing list elements to strings
for i in range(len(plains_tracts)):
    tract = str(plains_tracts[i]).split("'")[1]
    plains_tracts[i] = tract

for i in range(len(timbers_tracts)):
    tract = str(timbers_tracts[i]).split("'")[1]
    timbers_tracts[i] = tract

# Adding ecoregion to tract shapefile
i = 0

for row in cursor_tracts:
    tract = str(tracts[i]).split("'")[1]

    if tract in plains_tracts:
        row.setValue("ecoregion1" , "Central Great Plains")

        cursor_tracts.updateRow(row)

    if tract in timbers_tracts:
        row.setValue("ecoregion2" , "Cross Timbers")

        cursor_tracts.updateRow(row)

    i += 1

# Updating parcel information in Timbers shapefile
i = 0

for row in cursor_timber:
    tract = str(timber_eco_tracts[i]).split("'")[1]

    eco1 = row.getValue("ecoregion1")

    if eco1 == "Central Great Plains":

        whereClause = """"TRACTCE" = """ + "'" + tract + "'"

        arcpy.Select_analysis(sa_timbers ,
                              tracts_temp ,
                              whereClause)

        arcpy.Clip_analysis(sa_parcels ,
                            tracts_temp ,
                            parcel_temp)

        houses = int(arcpy.GetCount_management(parcel_temp)[0])

        row.setValue("parcels" , houses)
        cursor_timber.updateRow(row)

    i += 1

# Updating parcel information in Timbers shapefile
i = 0

for row in cursor_plains:
    tract = str(plains_eco_tracts[i]).split("'")[1]

    eco2 = row.getValue("ecoregion2")

    if eco2 == "Cross Timbers":
        whereClause = """"TRACTCE" = """ + "'" + tract + "'"

        arcpy.Select_analysis(sa_plains ,
                              tracts_temp ,
                              whereClause)

        arcpy.Clip_analysis(sa_parcels ,
                            tracts_temp ,
                            parcel_temp)

        houses = int(arcpy.GetCount_management(parcel_temp)[0])

        row.setValue("parcels" , houses)
        cursor_plains.updateRow(row)

    i += 1




