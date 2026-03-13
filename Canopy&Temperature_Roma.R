library(rgee)
library(terra)
library(ggplot2)
library(sf)
ee_Initialize(project = "ee-assuntasera")


canopy_height = ee$Image("users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1")
print( canopy_height$getInfo() )

studyArea = ee$FeatureCollection("projects/ee-assuntasera/assets/Roma_58091_2021_WGS84")



## filter for clouds, time window (2020) and area (studyArea)
## adding Landsat 9 temperature band reduced to max value
Ls9 = ee$ImageCollection("LANDSAT/LC09/C02/T1_L2")
Ls9f <- Ls9$
  filterBounds(studyArea)$
  filter(ee$Filter$lt("CLOUD_COVER", 20))$
  filter(ee$Filter$dayOfYear(150, 280))$
  select("ST_B10")$
  max()$
  multiply(0.00341802)$
  add(149)$
  subtract(273.15)$
  clip(studyArea)

##correlation
# Stack imagine
stack <- Ls9f$
  addBands(canopy_height)$
  rename(c("Temp", "CH"))$
  mask(canopy_height$gt(5))$
  clip(studyArea) 
         
# Sampling
samples <- stack$sample(
  region = studyArea,
  scale = 50,
  numPixels = 2000,
  geometries = TRUE
)
  
# Inspect
# samplesClient <- samples$getInfo()

## download sample points to r object
samplesClient.sf <- ee_as_sf(samples)
# plot(samplesClient.sf)
## write sample points to geopackage format, for loading to QGIS
sf::write_sf(samplesClient.sf, "samplesOutput.gpkg")
# if you want to load a geopackage file:
# sf::read_sf("samplesOutput.gpkg")

## if you want to export the stack to a geotif image in drive
task_img <- ee_image_to_drive(
  description = "stack",
  image = stack,
  fileFormat = "GEO_TIFF",
  region = studyArea,
  fileNamePrefix = "stack",
  scale = 30
) $start()

## (ee_as_rast is a shortcut to downloading in drive and then 
## in local space, but needs googledrive library and access 
## credentials )
## stack.rast <- ee_as_rast(stack)
#  plot(stack.raster)

ggplot(samplesClient.sf, aes(x=CH, y=Temp) ) + geom_point()

linear.model <- lm(data = samplesClient.sf,   Temp ~ CH )
plot(linear.model)
summary(linear.model)


##export
# clip temperature
canopy_height_clipped = canopy_height$clip(studyArea)

task_img <- ee_image_to_drive(
  image = canopy_height_clipped,
  fileFormat = "GEO_TIFF",
  region = studyArea$geometry(),
  fileNamePrefix = "Canopy height Roma",
  scale = 10
)
task_img$start()

# clip temperature
Ls9fTemp = Ls9f$clip(studyArea)


task_img <- ee_image_to_drive(
  image = Ls9fTemp,
  fileFormat = "GEO_TIFF",
  region = studyArea$geometry(),
  fileNamePrefix = "Temperature Roma",
  scale = 30
)
task_img$start()


