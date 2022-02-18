## [Title]:  Cleaning Original Shapefiles to Study Area
## [Author]: Kevin Neal
## [Date]:   May 28, 2021

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
env.workspace = "E:/Research/Thesis/Data/shapefiles/tri_county/Originals/"

###########################
## 2. Data (shapefiles and rasters)
shapesPath = "E:/Research/Thesis/Data/shapefiles/tri_county/Originals/"
okCity     = shapesPath + "ok_cities.shp"
okTracts   = shapesPath + "ok_tracts2014.shp"
okNeighbor = shapesPath + "ok_neighborhoods.shp"
okParcels  = shapesPath + "ok_parcels2014.shp"
usCounties = shapesPath + "us_counties.shp"
usEco3     = shapesPath + "us_eco3.shp"
usStates   = shapesPath + "us_states.shp"
usRedline  = shapesPath + "us_redline.shp"

tempPath     = "E:/Research/Thesis/Data/shapefiles/temp/"
tempShape    = tempPath + "shape_temp.shp"
projectShape = tempPath + "reproject_temp.shp"

outPath          = "E:/Research/Thesis/Data/shapefiles/tri_county/"
outTracts_full   = outPath + "okc_00_tracts2014.shp"
outParcel_full   = outPath + "okc_00_parcels2014.shp"
outCounties_full = shapesPath + "00_okc_counties.shp"
outEco3_full     = shapesPath + "00_okc_eco3.shp"

outTracts_clip   = outPath + "sa_00_tracts2014.shp"
outParcel_clip   = outPath + "sa_00_parcels2014.shp"
outCounties_sa   = shapesPath + "00_sa_counties.shp"
outEco3          = shapesPath + "00_sa_eco3.shp"
outState         = shapesPath + "00_sa_oklahoma.shp"
outRedline       = shapesPath + "00_sa_redline.shp"
outNeighbor      = shapesPath + "00_sa_neighborhood.shp"

studyArea = shapesPath + "00_sa_okc.shp"

spatial_reference = arcpy.Describe(okParcels).spatialReference

###########################
## 3. Counties Shapefile
print "[Counties Shapefile]: "

whereClause = '"' + "GEOID" + '"' + "IN ('40017' , '40027' , '40109')"

arcpy.Select_analysis(usCounties , tempShape , whereClause)

print "      - Clipped to Canadian, Cleveland, and Oklahoma counties"

arcpy.Project_management(tempShape , outCounties_full , spatial_reference)

print "      - Reprojected to parcels shapefile"
print "      - END \n \n "

###########################
## 4. Cities Shapefile
print "[Oklahoma Cities Shapefile]: "

whereClause = '"' + "NAME" + '" = ' + "'" + "Oklahoma City" + "'"

arcpy.Select_analysis(okCity , tempShape , whereClause)

print "      - Clipped to full Oklahoma City spatial extent"

arcpy.Project_management(tempShape , projectShape , spatial_reference)

print "      - Reprojected to parcels shapefile"

arcpy.Clip_analysis(projectShape , outCounties_full , studyArea)                   # Clipping cities shapefile to OKC spatial extent

print "      - Clipped to Canadian, Cleveland, and Oklahoma counties spatial extent"

arcpy.Clip_analysis(outCounties_full , studyArea  , outCounties_sa)                # Clipping counties shapefile to OKC spatial extent

print "      - [Counties Shapefile]: Clipped to Canadian, Cleveland, and Oklahoma counties Oklahoma City spatial extent"
print "      - END \n \n "

###########################
## 5. Oklahoma City Neighborhoods Shapefile
print "[OKC Neighborhoods Shapefile]: "

arcpy.Project_management(okNeighbor , projectShape , spatial_reference)

print "      - Reprojected to parcels shapefile"

arcpy.Clip_analysis(projectShape , studyArea , outNeighbor)

print "      - Clipped to Oklahoma City spatial extent"
print "      - END \n \n "

###########################
## 6. States Shapefile
print "[US States Shapefile]: "

whereClause = '"' + "NAME" + '" = ' + "'" + "Oklahoma" + "'"

arcpy.Select_analysis(usStates , tempShape , whereClause)

print "      - Clipped to state of Oklahoma"

arcpy.Project_management(tempShape , outState , spatial_reference)

print "      - Reprojected to parcels shapefile"
print "      - END \n \n "

###########################
## 7. Redline Shapefile
print "[US Redline Shapefile]: "

arcpy.Project_management(usRedline , projectShape , spatial_reference)

print "      - Reprojected to parcels shapefile"

arcpy.Clip_analysis(projectShape , studyArea , outRedline)

print "      - Clipped to Oklahoma City spatial extent"
print "      - END \n \n "

###########################
## 8. Tracts Shapefile
print "[US Census Tracts Shapefile]: "

arcpy.AddField_management(okTracts , "parcels" , "LONG")

print "      - New field added (parcels)"

arcpy.Project_management(okTracts , projectShape , spatial_reference)

print "      - Reprojected to parcels shapefile"

arcpy.MakeFeatureLayer_management(projectShape , "tracts")
arcpy.MakeFeatureLayer_management(studyArea    , "okc")

arcpy.SelectLayerByLocation_management("tracts" , "INTERSECT" , "okc")

arcpy.FeatureClassToFeatureClass_conversion("tracts" , outPath , "okc_00_tracts2014.shp")      # Clipping tracts shapefile to full tract

print "      - Clipped to full census tract"

arcpy.Clip_analysis(projectShape , studyArea , outTracts_clip)                                 # Clipping tracts shapefile to OKC spatial extent

print "      - Clipped to Oklahoma City spatial extent"
print "      - END \n \n "

###########################
## 9. Ecoregion Shapefile
print "[US Ecoregion Level 3 Shapefile]: "

whereClause = '"' + "US_L3NAME" + '"' + "IN ('Central Great Plains' , 'Cross Timbers')"

arcpy.Select_analysis(usEco3 , tempShape , whereClause)

print "      - Clipped to Central Great Plains and Cross Timbers"

arcpy.Project_management(tempShape , projectShape , spatial_reference)

print "      - Reprojected to parcels shapefile"

arcpy.Clip_analysis(projectShape , outTracts_full , outEco3_full)

print "      - Clipped to census tract full"

arcpy.Clip_analysis(projectShape , studyArea , outEco3)

print "      - Clipped to Oklahoma City spatial extent"
print "      - END \n \n "

###########################
## 10. Parcel Shapefile
print "[OKC Parcels Shapefile]: "

whereClause = '"' + "CLUCat" + '"' + "IN ('Residential' , 'Rural Residential')"

arcpy.Select_analysis(okParcels , tempShape , whereClause)

print "      - Selecting only residential and rural residential features"

arcpy.Clip_analysis(tempShape , outTracts_full , outParcel_full)

print "      - Clipping to census tract full spatial extent"
print "      - END \n \n "




