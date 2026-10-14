################################################################################
# 06_crop_overland_products.R
# Step 6: crop the OVERLAND biophysical products to the study area
#
# Input : GeoTIFFs produced by the OVERLAND processor from the Landsat scenes,
#         one folder per product in overland/landsat/catalogue/
# Output: cropped copies in a "crop" sub-folder of each product folder
#           <product>/crop/<original_name>_crop.tif
#
# These products (leaf area index, FAPAR, cover fractions, water content...)
# are extra input layers that can be used next to the spectral bands to
# describe vegetation.
################################################################################

library(raster)
library(rgdal)

source("R/00_config.R")

catalogue_dir <- file.path(base_dir, "overland", "landsat", "catalogue")

# One folder per OVERLAND product
products <- c(
  "area_soil_ref",            #  1 Area soil reference
  "brown_cover_fraction",     #  2 Brown (non-photosynthetic) cover fraction
  "canopy_shadow_factor",     #  3 Canopy shadow factor
  "cloud_optical_depth",      #  4 Cloud optical depth
  "cloud_reflec",             #  5 Cloud reflectance
  "distance_vis",             #  6 Distance of visibility
  "fapar",                    #  7 Fraction of absorbed PAR
  "green_cover_fraction",     #  8 Green cover fraction
  "green_leaf_index",         #  9 Green leaf index
  "leaf_area_index",          # 10 Leaf area index (LAI)
  "leaf_chlorophyll_content", # 11 Leaf chlorophyll content
  "leaf_water_content",       # 12 Leaf water content
  "model_fit",                # 13 Model fit
  "ndvi",                     # 14 NDVI
  "soil_brightness",          # 15 Soil brightness
  "soil_fraction",            # 16 Soil fraction
  "vegetation_brown_ratio",   # 17 Vegetation brown ratio
  "water_fraction",           # 18 Water fraction
  "water_height",             # 19 Water height
  "water_vapour_col"          # 20 Water vapour column
)

# Crop box: AOI extent reprojected to the CRS of the OVERLAND products
# (taken from the first file of the first product)
first_file <- list.files(file.path(catalogue_dir, products[1]),
                         pattern = "\\.tif$", full.names = TRUE)[1]
ext_2 <- aoi_extent_in_crs_of(raster(first_file))

for (product in products) {
  product_dir <- file.path(catalogue_dir, product)
  setwd(product_dir)

  srdir <- dirout <- file.path(product_dir, "crop")
  dir.create(dirout, showWarnings = FALSE)

  list <- list.files(product_dir, pattern = "\\.tif$")
  for (i in seq_along(list)) {
    # <name>.tif -> crop/<name>_crop.tif
    name <- sub("\\.tif$", "", list[i])
    out  <- file.path(srdir, paste0(name, "_crop.tif"))
    crop(x = raster(list[i]), y = ext_2, filename = out)
  }
}
