################################################################################
# 02_landsat_process_aoi_subset.R
# Step 2: process Landsat scenes cropped to the study area and build the
#         time stacks used in the rest of the workflow
#
# Input : Landsat surface-reflectance archives (*.tar.gz), crop extent ext2.shp
# Output: for each band (1-7) and NDVI
#           - cloud-masked scenes cropped to the AOI -> bfmspatial_<b>_ext/selection/
#           - time stack of the selected scenes      -> bfmspatial_<b>_ext/stack_<b>_sel/
#
# Same processing as step 1, but cropped to the study area. After processing,
# the "selection" folders were reviewed by hand and poor (e.g. very cloudy)
# scenes removed, so the stacks only contain the selected dates.
################################################################################

library(raster)
library(rgdal)
# bfastSpatial is not on CRAN: devtools::install_github("loicdtx/bfastSpatial")
library(bfastSpatial)

source("R/00_config.R")

# The per-scene processing was run once; set to TRUE to run it again.
# With FALSE the script only rebuilds the stacks from the selected scenes.
run_processing <- FALSE

# Folder with the raw Landsat archives
dir <- system.file("landsat_imagery", package = "bfastSpatial")

# Crop extent for the study area
myshape <- readOGR(file.path(base_dir, "ext2.shp"), layer = "ext2")
ext <- extent(myshape)


#### One time stack per band (1-7) and one for NDVI ############################
# Band and NDVI outputs follow the same steps, only the folder names differ.
layers <- data.frame(
  vi        = c(paste0("sr_band", landsat_bands), "ndvi"),
  root      = c(paste0("bfmspatial_", landsat_bands, "_ext"), "ndvi_ext"),
  stack_dir = c(paste0("stack_", landsat_bands, "_sel"), "stack_sel"),
  stack     = c(paste0("stack_band_", landsat_bands, ".grd"), "stack_ndvi.grd"),
  stringsAsFactors = FALSE
)

for (k in seq_len(nrow(layers))) {
  root <- file.path(base_dir, layers$root[k])

  # 1. Extract the band, apply the Fmask cloud mask and crop to the AOI
  srdir <- dirout <- file.path(root, "selection")
  dir.create(dirout, showWarnings = FALSE, recursive = TRUE)
  if (run_processing) {
    processLandsatBatch(x = dir, pattern = glob2rx("*.tar.gz"), outdir = dirout,
                        srdir = srdir, delete = TRUE, vi = layers$vi[k],
                        e = ext, mask = "fmask", keep = 0, overwrite = TRUE)
  }

  # 2. Stack the selected scenes into a time series
  list <- list.files(dirout, pattern = glob2rx("*.grd"), full.names = TRUE)
  dirout <- file.path(root, layers$stack_dir[k])
  dir.create(dirout, showWarnings = FALSE)
  stackName <- file.path(dirout, layers$stack[k])
  s <- timeStack(x = list, filename = stackName, datatype = "INT2S",
                 overwrite = TRUE)
}

# The last stack built is NDVI
plot(s)


#### Useful checks (not run) ###################################################
# getSceneinfo(list[1])            # sensor, path/row and date of a scene
# plot(density(raster(list[1])))   # reflectance distribution of a scene
