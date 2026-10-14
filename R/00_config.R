################################################################################
# 00_config.R
# Shared settings for the Virunga Landsat classification workflow.
#
# Every script in this folder starts with source("R/00_config.R"), so the data
# location only has to be changed here. The original analysis ran on Windows
# with all data on the H: drive.
################################################################################

# Root folder holding all input and output data for the project
base_dir <- "H:/virunga"

# Area of interest (AOI): Virunga Conservation Area + Bwindi Impenetrable
# National Park (VCA_BINP_AOI), used to crop every image to the study area
aoi_dir   <- file.path(base_dir, "local_data", "VCA_BINP_AOI")
aoi_layer <- "VCA_BINP_AOI"

# Landsat surface-reflectance bands processed in the workflow (+ NDVI)
landsat_bands <- 1:7

# Read the AOI shapefile and return its bounding box as a SpatialPolygons
# object, reprojected to the CRS of `target` (a Raster* object). Cropping with
# the reprojected box avoids reprojecting the (large) rasters themselves.
aoi_extent_in_crs_of <- function(target) {
  aoi      <- rgdal::readOGR(aoi_dir, layer = aoi_layer)
  aoi_box  <- as(raster::extent(aoi), "SpatialPolygons")
  sp::proj4string(aoi_box) <- sp::proj4string(aoi)
  sp::spTransform(aoi_box, sp::CRS(sp::proj4string(target)))
}
