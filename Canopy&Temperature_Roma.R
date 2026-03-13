library(rgee)
ee_Initialize(project = "ee-assuntasera")


canopy_height = ee$Image("users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1")
print( canopy_height$getInfo() )

studyArea = ee$FeatureCollection("projects/ee-assuntasera/assets/Roma_58091_2021_WGS84")

canopy_height_clipped = canopy_height$clip(studyArea)

task_img <- ee_image_to_drive(
  image = canopy_height_clipped,
  fileFormat = "GEO_TIFF",
  region = studyArea$geometry(),
  fileNamePrefix = "Canopy height Roma",
  scale = 10
)
task_img$start()

## filter for clouds, time window (2020) and area (sudyArea)
## adding landsat 9 temperature band reduced to max value
Ls9 = ee$ImageCollection("LANDSAT/LC09/C02/T1_L2")
Ls9f <- Ls9$
  filterBounds(studyArea)$
  filter(ee$Filter$lt("CLOUD_COVER", 20))$
  filter(ee$Filter$dayOfYear(150, 280))$
  select("ST_B10")$
  max()$
  multiply(0.00341802)$
  add(149)$
  subtract(273.15)

## clip temperature
Ls9fTemp = Ls9f$clip(studyArea)

task_img <- ee_image_to_drive(
  image = Ls9fTemp,
  fileFormat = "GEO_TIFF",
  region = studyArea$geometry(),
  fileNamePrefix = "Temperature Roma",
  scale = 30
)
task_img$start()


