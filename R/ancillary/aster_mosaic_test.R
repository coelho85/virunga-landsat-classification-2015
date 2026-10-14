################################################################################
# ancillary/aster_mosaic_test.R
# Test of different ways to mosaic two overlapping ASTER scenes in R
#
# Input : ASTER HDF files in aster_merge_test/
# Output: band 1 GeoTIFFs and test mosaics in aster_merge_test/
#
# Exploratory script comparing merge(), mosaic() with different functions for
# the overlap (max, min, mean), extend() and resample().
################################################################################

library(raster)
library(gdalUtils)

source("R/00_config.R")

work_dir <- file.path(base_dir, "aster_merge_test")
setwd(work_dir)

list_mosaic <- list.files(pattern = ".hdf")


#### 1. Convert band 1 of every scene to GeoTIFF (as in aster_hdf_to_geotiff.R)
list_sub_mosaic <- data.frame(matrix(NA, nrow = length(list_mosaic), ncol = 4))
names(list_sub_mosaic) <- c("image", "b1", "b2", "b3")
for (i in seq_along(list_mosaic)) {
  sds_aux <- get_subdatasets(list_mosaic[i])
  list_sub_mosaic[i, ] <- c(i, sds_aux[1], sds_aux[2], sds_aux[3])
}

for (i in seq_along(list_mosaic)) {
  sds  <- list_sub_mosaic[i, "b1"]
  name <- strsplit(strsplit(sds, ":")[[1]][3], ".hdf")[[1]][1]
  gdalwarp(sds, file.path(work_dir, paste0(name, "_b1.tif")),
           s_srs = "+init=epsg:4326")
  write(gdalinfo(sds), file.path(work_dir, paste0(name, "_b1.txt")))
}


#### 2. Mosaic tests with the first two scenes ################################
list_tif <- list.files(pattern = "b1.tif")
r1 <- raster(list_tif[1])
r2 <- raster(list_tif[2])

# Empty raster covering both scenes
full.extent <- unionExtent(r1, r2)
bounding.raster <- raster(full.extent, crs = projection(r1))

# a) merge(): first raster wins in the overlap
x <- list(r1, r2)
x$filename <- "test_merge.tif"
m <- do.call(merge, x)

# b) mosaic(): overlapping pixels combined with a function
m <- mosaic(r1, r2, fun = max, tolerance = 0.5)

# c) extend each scene to the full extent first, then mosaic
n   <- extend(r1, r2, filename = "r1_r2.tif")
n_2 <- extend(r2, r1, filename = "r2_r1.tif")
r3 <- raster("r1_r2.tif")
r4 <- raster("r2_r1.tif")
m1 <- mosaic(r4, r3, fun = min, tolerance = 0.5)

# d) resample one scene onto the grid of the other, then mosaic with the mean
r5 <- resample(r1, r2, method = "bilinear")
r6 <- resample(r2, r1, method = "bilinear")
m  <- mosaic(r2, r5, fun = mean, tolerance = 0.5)
