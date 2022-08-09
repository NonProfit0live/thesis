## [Title]:  Adding Tract Information to Each Parcel
## [Author]: Kevin Neal
## [Date]:   April 17, 2021

import ti
import arcpy
import numpy as np
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
pointsFull = shapesPath + "okc_01_parcels2014_points.shp"
parcelFull = shapesPath + "okc_01_parcels2014.shp"
tractsFull = shapesPath + "okc_00_tracts2014.shp"

eco3       = "E:/Research/Thesis/Data/shapefiles/tri_county/Originals/00_okc_eco3.shp"
shapeRed   = "E:/Research/Thesis/Data/shapefiles/tri_county/Originals/00_sa_redline.shp"
tractsClip = shapesPath + "sa_00_tracts2014.shp"
outParcel  = shapesPath + "sa_01_parcels2014.shp"

tempPath     = "E:/Research/Thesis/Data/shapefiles/temp/"
shapeTemp    = tempPath + "shape_temp.shp"

###########################
## 3. Adding Ecoregion and Redline
def addingEco_Redline(pointParcel , shapeEco , shapeRedline):
    shapefile = shapeEco.split("/")[len(shapeEco.split("/")) - 1].split(".")[0]

    print "[Beginning]: " + shapefile
    print "             - Adding ecoregion to point parcel shapefile"

    ecoregions = [f for f in arcpy.da.SearchCursor(shapeEco , "US_L3NAME")]
    ecoregions = [item for t in ecoregions for item in t]

    arcpy.MakeFeatureLayer_management(pointParcel , "parcels")

    for eco in ecoregions:
        eco = str(eco)

        whereClause = '"' + "US_L3NAME" + '" = ' + "'" + eco + "'"

        arcpy.Select_analysis(shapeEco , shapeTemp , whereClause)

        arcpy.MakeFeatureLayer_management(shapeTemp , "temp")

        arcpy.SelectLayerByLocation_management("parcels" ,
                                               "WITHIN"  ,
                                               "temp"    ,
                                               selection_type = "NEW_SELECTION")

        arcpy.CalculateField_management("parcels"       ,
                                        "ecoregion"     ,
                                        "'" + eco + "'" ,
                                        "PYTHON")

    print "             - [Progress]: END"
    print ""

    shapefile = shapeRedline.split("/")[len(shapeRedline.split("/")) - 1].split(".")[0]

    print "[Beginning]: " + shapefile
    print "             - Adding redline to point parcel shapefile"

    redlineID = [f for f in arcpy.da.SearchCursor(shapeRedline , "neighborho")]
    redlineID = [item for t in redlineID for item in t]

    redGrade  = [f for f in arcpy.da.SearchCursor(shapeRedline , "holc_grade")]
    redGrade  = [item for t in redGrade for item in t]

    i = 0

    for redline in redlineID:
        redline = str(redline)
        grade   = str(redGrade[i])

        whereClause = '"' + "neighborho" + '" = ' + redline

        arcpy.Select_analysis(shapeRedline , shapeTemp , whereClause)

        arcpy.MakeFeatureLayer_management(shapeTemp , "temp")

        arcpy.SelectLayerByLocation_management("parcels" ,
                                               "WITHIN"  ,
                                               "temp"    ,
                                               selection_type = "NEW_SELECTION")

        arcpy.CalculateField_management("parcels"         ,
                                        "redline"         ,
                                        "'" + grade + "'" ,
                                        "PYTHON")

        i += 1

    print "             - [Progress]: END"
    print ""
    print ""

###########################
## 3. Assigning Tracts to Parcels
def addingTracts(shapeTracts , clipTracts , pointParcel , shapeParcel , parcelOut):
    shapefile = pointParcel.split("/")[len(pointParcel.split("/")) - 1].split(".")[0]

    print "[Beginning]: " + shapefile
    print "             - Adding tract identifier to points shapefile"

    tracts = [f for f in arcpy.da.SearchCursor(shapeTracts , "TRACTCE")]
    tracts = [item for t in tracts for item in t]

    arcpy.MakeFeatureLayer_management(pointParcel , "parcels")

    i = 0
    start    = time.time()

    quarter  = str(len(tracts) * 0.25)
    half     = str(len(tracts) * 0.50)
    quarter3 = str(len(tracts) * 0.75)

    quarter  = int(quarter.split(".")[0])
    half     = int(half.split(".")[0])
    quarter3 = int(quarter3.split(".")[0])

    ###############################
    ## Adding census identifiers to points shapefile
    for tract in tracts:
        tract = str(tract)
        whereClause = '"' + "TRACTCE" + '" = ' + "'" + tract + "'"

        arcpy.Select_analysis(shapeTracts , shapeTemp , whereClause)

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

            print "                     - [Progress]: 25%"
            print "                     - [Duration]: " + str(duration)
            print ""

        if i == half:
            duration = end - start
            duration = time_convert(duration)

            print "                     - [Progress]: 50%"
            print "                     - [Duration]: " + str(duration)
            print ""

        if i == quarter3:
            duration = end - start
            duration = time_convert(duration)

            print "                     - [Progress]: 75%"
            print "                     - [Duration]: " + str(duration)
            print ""

    arcpy.Delete_management("parcels")

    end = time.time()
    duration = end - start
    duration = time_convert(duration)

    print "                     - [Progress]: 100%"
    print "                     - [Duration]: " + str(duration)
    print ""
    print ""

    ###############################
    ## Join parcel point tract ID, redline, and ecoregion to parcel polygon shapefile
    shapefile = shapeParcel.split("/")[len(shapeParcel.split("/")) - 1].split(".")[0]

    print "[Beginning]: " + shapefile
    print "             - Adding tract identifier to points shapefile"

    cursor = arcpy.UpdateCursor(shapeParcel)
    tracts = [f for f in arcpy.da.SearchCursor(pointParcel , "TRACTCE")]
    tracts = [item for t in tracts for item in t]

    redlines = [f for f in arcpy.da.SearchCursor(pointParcel , "redline")]
    redlines = [item for t in redlines for item in t]

    ecoregions = [f for f in arcpy.da.SearchCursor(pointParcel , "ecoregion")]
    ecoregions = [item for t in ecoregions for item in t]

    idPoints = [f for f in arcpy.da.SearchCursor(pointParcel , "uniqueID")]
    idPoints = [item for t in idPoints for item in t]

    idPolys = [f for f in arcpy.da.SearchCursor(shapeParcel , "uniqueID")]
    idPolys = [item for t in idPolys for item in t]

    quarter  = int(str(len(tracts) * 0.25).split(".")[0])
    half     = int(str(len(tracts) * 0.50).split(".")[0])
    quarter3 = int(str(len(tracts) * 0.75).split(".")[0])

    i = 0
    start = time.time()

    for row in cursor:
        tract     = str(tracts[i])
        redline   = str(redlines[i])
        ecoregion = str(ecoregions[i])

        idPoint = str(idPoints[i])
        idPoly  = str(idPolys[i])

        if idPoint == idPoly:

            row.setValue("TRACTCE"   , tract)
            row.setValue("redline"   , redline)
            row.setValue("ecoregion" , ecoregion)

            cursor.updateRow(row)

        i  += 1
        end = time.time()

        if i == quarter:
            duration = end - start
            duration = time_convert(duration)

            print "                     - [Progress]: 25%"
            print "                     - [Duration]: " + str(duration)
            print ""

        if i == half:
            duration = end - start
            duration = time_convert(duration)

            print "                     - [Progress]: 50%"
            print "                     - [Duration]: " + str(duration)
            print ""

        if i == quarter3:
            duration = end - start
            duration = time_convert(duration)

            print "                     - [Progress]: 75%"
            print "                     - [Duration]: " + str(duration)
            print ""

    end = time.time()
    duration = end - start
    duration = time_convert(duration)

    print "                     - [Progress]: 100%"
    print "                     - [Duration]: " + str(duration)
    print ""
    print ""

    ###############################
    ## Clipping parcel shapefile to study area

    arcpy.Clip_analysis(shapeParcel , clipTracts , parcelOut)

    print "[" + shapefile + "]: Clipped to study area"
    print ""
    print ""

###########################
## 4. Counting parcels
def parcelCount(shapeTracts , shapeParcel):
    shapefile = shapeTracts.split("/")[len(shapeTracts.split("/")) - 1].split(".")[0]

    print "[Beginning]: " + shapefile
    print "             - Counting parcels for " + shapefile

    cursor = arcpy.UpdateCursor(shapeTracts)

    parcelTracts = [f for f in arcpy.da.SearchCursor(shapeParcel , "TRACTCE")]
    parcelTracts = [item for t in parcelTracts for item in t]
    parcelTracts = np.array(parcelTracts)

    tracts = [f for f in arcpy.da.SearchCursor(shapeTracts , "TRACTCE")]
    tracts = [item for t in tracts for item in t]
    tracts = np.array(tracts)

    i = 0

    for row in cursor:
        tract = int(tracts[i])

        count = len(np.where(parcelTracts == tract)[0])

        row.setValue("parcels" , count)
        cursor.updateRow(row)

        i += 1

    print "             - [Duration]: END"
    print ""
    print ""

###########################
## 5. Calling functions
addingEco_Redline(pointsFull , eco3 , shapeRed)

addingTracts(tractsFull , tractsClip , pointsFull , parcelFull , outParcel)

parcelCount(tractsFull , parcelFull)
parcelCount(tractsClip , outParcel)

## Calculating Area in Parcel Shapefile
arcpy.MakeFeatureLayer_management(outParcel , "parcels")

arcpy.CalculateField_management("parcels" , "areaFT" , "!shape.area@squarefeet!" , "PYTHON_9.3")