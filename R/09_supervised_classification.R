################################################################################
# 09_supervised_classification.R
# Step 9: supervised classification with field data  (WORK IN PROGRESS)
#
# Input : field vegetation plots from Bwindi Impenetrable National Park
#         (point shapefile, WGS84 / UTM zone 35S) with 9 vegetation classes
#         Landsat time stacks from step 2
#
# The script loads the field plots and the image stack. The next steps
# planned were:
#   1. extract the pixel values of every band at the plot locations
#      (raster::extract)
#   2. train a random forest on those values with the vegetation class as
#      the response (randomForest)
#   3. check accuracy with the out-of-bag confusion matrix
#   4. predict the class of every pixel (raster::predict) and write the map
################################################################################

library(raster)
library(rgdal)
library(randomForest)

source("R/00_config.R")

# Field plots with 9 vegetation classes
classes <- shapefile(file.path(base_dir, "local_data",
                               "BINP_vegplot_wgs84utm35s",
                               "BINP_Veg_Plot_Dennis_wgs84utm35s.shp"))
View(classes@data)

# Time stack of band 1 (step 2)
image1 <- stack(file.path(base_dir, "bfmspatial_1_ext", "stack_1_sel",
                          "stack_band_1.grd"))
