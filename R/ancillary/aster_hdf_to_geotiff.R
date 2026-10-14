################################################################################
# ancillary/aster_hdf_to_geotiff.R
# Convert ASTER L1 scenes (HDF-EOS) to GeoTIFF, one file per VNIR band
#
# Input : ASTER HDF files (*42627.hdf) in aster/
# Output: aster_output_1/<scene>_b1.tif, _b2.tif, _b3.tif
#         + a .txt file with the gdalinfo metadata of each band
#
# ASTER was tested as extra imagery for the study area (15 m VNIR bands).
# Uses the GDAL command-line tools through gdalUtils, so GDAL must be installed.
################################################################################

library(raster)
library(gdalUtils)

source("R/00_config.R")

aster_dir <- file.path(base_dir, "aster")
out_dir   <- file.path(base_dir, "aster_output_1")
setwd(aster_dir)

list <- list.files(aster_dir, pattern = "*42627.hdf")


#### 1. List the sub-datasets of the 3 VNIR bands in every HDF file ###########
# An ASTER HDF holds several sub-datasets; the first three are VNIR bands 1-3.
list_sub <- data.frame(matrix(NA, nrow = length(list), ncol = 4))
names(list_sub) <- c("image", "b1", "b2", "b3")
for (i in seq_along(list)) {
  sds_aux <- get_subdatasets(list[i])
  list_sub[i, ] <- c(i, sds_aux[1], sds_aux[2], sds_aux[3])
}


#### 2. Convert every band of every scene to GeoTIFF ##########################
for (band in c("b1", "b2", "b3")) {
  for (i in seq_along(list)) {
    sds <- list_sub[i, band]

    # Scene name: sub-dataset strings look like
    # HDF4_EOS:EOS_SWATH:"<file>.hdf":<swath>:<band>; keep <file> without .hdf
    name <- strsplit(strsplit(sds, ":")[[1]][3], ".hdf")[[1]][1]

    # Reproject from the swath geolocation (WGS84) and write GeoTIFF
    gdalwarp(sds, file.path(out_dir, paste0(name, "_", band, ".tif")),
             s_srs = "+init=epsg:4326")

    # Keep the metadata next to the image
    write(gdalinfo(sds), file.path(out_dir, paste0(name, "_", band, ".txt")))
  }
}


#### Note: merging (mosaicking) scenes with GDAL ##############################
# gdal_merge.py is much faster than "Mosaic to New Raster" in ArcMap:
#   gdal_merge.py -o out.tif in1.tif in2.tif
#   gdal_merge.py -o out.bil -of ENVI in1.tif in2.tif           (ENVI output)
#   gdal_merge.py -o out.bil -of ENVI -ps 30 30 in1.tif in2.tif (30 m pixels)
# The resampling method of -ps is not documented, so use gdalwarp to change
# pixel size.
