################################################################################
# 07_crop_sentinel_mosaic.R
# Step 7: prepare Sentinel-2 imagery for the study area  (WORK IN PROGRESS)
#
# Input : Sentinel-2 mosaic tiles (*.jp2) in sentinel/mosaic/
# Output: sentinel/mosaic/crop/ (intended)
#
# This step was started to add higher-resolution (10 m) Sentinel-2 data next
# to Landsat. The script builds the crop extent; the crop loop itself was not
# written yet (it would follow the same pattern as step 6).
################################################################################

library(raster)
library(rgdal)

source("R/00_config.R")

sentinel_dir <- file.path(base_dir, "sentinel", "mosaic")
setwd(sentinel_dir)

# Output folder for the cropped tiles
srdir <- dirout <- file.path(sentinel_dir, "crop")
dir.create(dirout, showWarnings = FALSE)

# Sentinel-2 tiles are delivered as JPEG2000
list <- list.files(sentinel_dir, pattern = "\\.jp2$")

# Crop box: AOI extent reprojected to the CRS of the Sentinel-2 tiles
bb <- raster(list[1])
ext_2 <- aoi_extent_in_crs_of(bb)

# TODO: crop each tile to ext_2 and write it to `dirout` (see step 6)
