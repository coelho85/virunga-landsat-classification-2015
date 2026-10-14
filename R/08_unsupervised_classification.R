################################################################################
# 08_unsupervised_classification.R
# Step 8: unsupervised land-cover classification of six Landsat 8 scenes
#
# Input : Landsat 8 OLI bands 1-7 (GeoTIFF) of six dates, path/row 173/061,
#         in landsat/images_selection/
# Output: three 12-class maps per scene in landsat/unsupervised/
#           <scene>_kmeans12.tif  k-means
#           <scene>_clara.tif     CLARA (k-medoids for large datasets)
#           <scene>_rf.tif        unsupervised random forest
#
# Each scene is cropped to the study area and classified into 12 spectral
# clusters with three methods, so the results can be compared and later
# labelled as land-cover classes using field data (see step 9).
################################################################################

library(raster)
library(rgdal)
library(randomForest)
library(cluster)

source("R/00_config.R")

setwd(file.path(base_dir, "landsat", "images_selection"))
out_dir <- file.path(base_dir, "landsat", "unsupervised")

# Landsat 8 scene IDs: LC8 + path/row 173/061 + year + day of year
scenes <- c("LC81730612014213LGN00",   # 2014-08-01
            "LC81730612015008LGN00",   # 2015-01-08
            "LC81730612015040LGN00",   # 2015-02-09
            "LC81730612015232LGN00",   # 2015-08-20
            "LC81730612015264LGN00",   # 2015-09-21
            "LC81730612015280LGN00")   # 2015-10-07

n_classes <- 12

# Fixed seed so the random starts and samples give the same result each run
set.seed(2016)

# Crop box: AOI extent in the CRS of the scenes (all share path/row and CRS)
ext_2 <- aoi_extent_in_crs_of(raster(paste0(scenes[1], "_B1.tif")))

for (name in scenes) {

  #### Load the 7 OLI bands and crop to the study area #########################
  raster_1 <- stack(paste0(name, "_B", landsat_bands, ".tif"))
  raster_1_c <- crop(x = raster_1, y = ext_2)

  # Pixel values as a matrix (one row per pixel). Clustering ignores NA
  # pixels; `i` keeps their positions to write the classes back to the map.
  v <- getValues(raster_1_c)
  i <- which(complete.cases(v))
  v <- na.omit(v)


  #### 1. k-means ##############################################################
  E <- kmeans(v, n_classes, iter.max = 100, nstart = 10)
  kmeans_raster <- raster(raster_1_c)
  kmeans_raster[i] <- E$cluster
  writeRaster(kmeans_raster, file.path(out_dir, paste0(name, "_kmeans12.tif")),
              overwrite = TRUE)


  #### 2. CLARA ################################################################
  # Partitioning around medoids on 500 sub-samples; more robust to outliers
  # than k-means and fast enough for millions of pixels
  clus <- clara(v, n_classes, samples = 500, metric = "manhattan", pamLike = TRUE)
  clara_raster <- raster(raster_1_c)
  clara_raster[i] <- clus$clustering
  writeRaster(clara_raster, file.path(out_dir, paste0(name, "_clara.tif")),
              overwrite = TRUE)


  #### 3. Unsupervised random forest ###########################################
  # a) Random forest in unsupervised mode on a sample of 500 pixels gives a
  #    proximity matrix (how often two pixels end up in the same leaf)
  vx <- v[sample(nrow(v), 500), ]
  rf_prox <- randomForest(vx, ntree = 1000, proximity = TRUE)$proximity
  # b) k-means on the proximities groups similar pixels into 12 clusters
  E_rf <- kmeans(rf_prox, n_classes, iter.max = 100, nstart = 10)
  # c) A supervised random forest trained on those clusters classifies
  #    every pixel of the image
  rf <- randomForest(vx, as.factor(E_rf$cluster), ntree = 500)
  rf_raster <- predict(raster_1_c, rf)
  writeRaster(rf_raster, file.path(out_dir, paste0(name, "_rf.tif")),
              overwrite = TRUE)


  #### Compare the three maps side by side #####################################
  class_stack <- stack(kmeans_raster, clara_raster, rf_raster)
  names(class_stack) <- c("kmeans", "clara", "randomForest")
  plot(class_stack)
}
