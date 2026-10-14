################################################################################
# 05_kmeans_first_test.R
# Step 5: first test of unsupervised classification (k-means) on one date,
#         using the 7 reflectance bands + NDVI
#
# Input : cropped, cloud-masked scenes from step 2
# Output: 12_classes.tif (12 spectral clusters, written to the working directory)
#
# This was a first exploratory run. Step 7 is the full unsupervised
# classification (k-means, CLARA and random forest) over six dates.
################################################################################

library(raster)

source("R/00_config.R")

# List the processed scenes of each band (bands 1-7) and NDVI
layer_dirs <- c(paste0("bfmspatial_", landsat_bands, "_ext"), "ndvi_ext")
layer_files <- lapply(layer_dirs, function(d) {
  list.files(file.path(base_dir, d, "selection"),
             pattern = glob2rx("*.grd"), full.names = TRUE)
})

# First date: 8-layer stack (bands 1-7 + NDVI)
img_1   <- sapply(layer_files, `[`, 1)
image_1 <- stack(img_1)

# For quick tests, a small window can be classified instead of the full image:
# C1 <- crop(image_1, extent(image_1, 2200, 2500, 1700, 3000))
C1 <- image_1

# Pixel values as a table: one row per pixel, one column per layer
DF <- as.data.frame(C1)
summary(DF)

# kmeans() does not accept NA, so masked pixels get an out-of-range value
# (reflectance is 0-10000) and end up in their own cluster
DF[is.na(DF)] <- 50000

# 12 spectral clusters (100 iterations, best of 10 random starts)
E <- kmeans(DF, 12, iter.max = 100, nstart = 10)

# Rebuild a raster from the cluster labels (pixels are in row order)
EM <- matrix(E$cluster, nrow = C1@nrows, ncol = C1@ncols, byrow = TRUE)
E.raster <- raster(EM, crs = C1@crs,
                   xmn = C1@extent@xmin, ymn = C1@extent@ymin,
                   xmx = C1@extent@xmax, ymx = C1@extent@ymax)

# Spread the classes over 0-255 so they show with contrast in image viewers
E.raster <- E.raster * 20
writeRaster(E.raster, "12_classes.tif", datatype = "INT1U", overwrite = TRUE)
