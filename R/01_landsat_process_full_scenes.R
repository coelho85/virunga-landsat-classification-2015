################################################################################
# 01_landsat_process_full_scenes.R
# Step 1: process Landsat surface-reflectance archives (full scenes)
#
# Input : Landsat surface-reflectance archives (*.tar.gz) ordered from USGS
#         ESPA, stored in the bfastSpatial "landsat_imagery" folder
# Output: for each band (1-7) and NDVI
#           - one cloud-masked .grd file per scene   -> bfmspatial_<b>/
#           - a multi-date time stack (.grd)         -> bfmspatial_<b>/stack_<b>/
#           - the same stack as a GeoTIFF            -> bfmspatial_<b>/tiff/
#
# Clouds and cloud shadows are removed with the Fmask layer delivered with
# each scene (mask = "fmask", keep = 0 keeps only clear-land pixels).
################################################################################

library(raster)
library(rgdal)
# bfastSpatial is not on CRAN: devtools::install_github("loicdtx/bfastSpatial")
library(bfastSpatial)

source("R/00_config.R")

# Folder with the raw Landsat archives
dir <- system.file("landsat_imagery", package = "bfastSpatial")
list <- list.files(dir, full.names = TRUE)

# Full scenes are processed here, so no crop extent is applied.
# (Step 2 repeats the processing cropped to the study area.)
ext <- NULL


#### Example: process a single scene (band 3) to check the output ##############
srdir <- dirout <- file.path(base_dir, "bfmspatial")
dir.create(dirout, showWarnings = FALSE)

processLandsat(x = list[1], outdir = dirout, srdir = srdir, delete = TRUE,
               vi = "sr_band3", e = ext, mask = "fmask", keep = 0,
               overwrite = TRUE)

# Quick visual check of the processed scene
list <- list.files(dirout, pattern = glob2rx("*.grd"), full.names = TRUE)
plot(r <- raster(list[3]))


#### Batch processing: one time stack per band #################################
for (b in landsat_bands) {
  band_dir <- file.path(base_dir, paste0("bfmspatial_", b))

  # 1. Extract the band from every archive and apply the cloud mask
  srdir <- dirout <- band_dir
  dir.create(dirout, showWarnings = FALSE)
  processLandsatBatch(x = dir, pattern = glob2rx("*.tar.gz"), outdir = dirout,
                      srdir = srdir, delete = TRUE, vi = paste0("sr_band", b),
                      e = ext, mask = "fmask", keep = 0, overwrite = TRUE)

  # 2. Stack all dates into a single time series (dates read from scene IDs)
  list <- list.files(dirout, pattern = glob2rx("*.grd"), full.names = TRUE)
  dirout <- file.path(band_dir, paste0("stack_", b))
  dir.create(dirout, showWarnings = FALSE)
  stackName <- file.path(dirout, paste0("stack_band_", b, ".grd"))
  s <- timeStack(x = list, filename = stackName, datatype = "INT2S",
                 overwrite = TRUE)

  # 3. Export the stack as a multi-layer GeoTIFF for use in other software
  dirout <- file.path(band_dir, "tiff")
  dir.create(dirout, showWarnings = FALSE)
  raster <- file.path(dirout, paste0("raster_brick_b", b, ".tif"))
  rf <- writeRaster(s, filename = raster, format = "GTiff", overwrite = TRUE)
}


#### NDVI time stack ###########################################################
srdir <- dirout <- file.path(base_dir, "ndvi")
dir.create(dirout, showWarnings = FALSE)
processLandsatBatch(x = dir, pattern = glob2rx("*.tar.gz"), outdir = dirout,
                    srdir = srdir, delete = TRUE, vi = "ndvi", e = ext,
                    mask = "fmask", keep = 0, overwrite = TRUE)

list <- list.files(dirout, pattern = glob2rx("*.grd"), full.names = TRUE)
dirout <- file.path(base_dir, "ndvi", "stack")
dir.create(dirout, showWarnings = FALSE)
stackName <- file.path(dirout, "stack_ndvi.grd")
s <- timeStack(x = list, filename = stackName, datatype = "INT2S",
               overwrite = TRUE)
plot(s)


#### Sanity check on the last band processed (band 7) ##########################
# Surface reflectance is scaled 0-10000; negative values or values above
# 10000 indicate invalid pixels.
check_band_7 <- rf[[1]]
plot(density(check_band_7))
plot(check_band_7)
plot(rf)

check_vec_b7 <- as.vector(check_band_7)
negative_b7  <- which(check_vec_b7 < 0)
higher_10000 <- which(check_vec_b7 > 10000)
