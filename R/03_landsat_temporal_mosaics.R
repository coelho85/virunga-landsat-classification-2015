################################################################################
# 03_landsat_temporal_mosaics.R
# Step 3: build cloud-free temporal mosaics from the Landsat time stacks
#
# Input : time stacks from step 2 (bfmspatial_<b>_ext/stack_<b>_sel/*.grd)
# Output: ESRI ASCII grids, one per band and mosaic version
#           bfmspatial_<b>_ext/temp_mosaic_<v>/temp_mosaic_v<v>_b<b>.asc
#           ndvi_ext/temp_mosaic_<v>/temp_mosaic_v<v>_ndvi.asc
#
# Clouds were masked out (NA) in step 1, so the per-pixel mean over several
# dates, ignoring NA, fills cloud gaps with values from other dates. Four
# versions use different combinations of dates (layers of the stack):
#   v1: all selected dates
#   v2: dates 2, 3, 4, 5, 6
#   v3: dates 1, 4, 7
#   v4: dates 3, 5, 6
################################################################################

library(raster)

source("R/00_config.R")

# Layers (dates) of the time stack averaged in each mosaic version
mosaic_dates <- list(v1 = NULL,            # NULL = use all layers
                     v2 = c(2, 3, 4, 5, 6),
                     v3 = c(1, 4, 7),
                     v4 = c(3, 5, 6))

# Location of each time stack and the suffix used in the output file names
layers <- data.frame(
  root      = c(paste0("bfmspatial_", landsat_bands, "_ext"), "ndvi_ext"),
  stack_dir = c(paste0("stack_", landsat_bands, "_sel"), "stack_sel"),
  stack     = c(paste0("stack_band_", landsat_bands, ".grd"), "stack_ndvi.grd"),
  suffix    = c(paste0("b", landsat_bands), "ndvi"),
  stringsAsFactors = FALSE
)

for (k in seq_len(nrow(layers))) {
  root <- file.path(base_dir, layers$root[k])
  r_1  <- brick(file.path(root, layers$stack_dir[k], layers$stack[k]))

  for (v in seq_along(mosaic_dates)) {
    dates <- mosaic_dates[[v]]
    r_sel <- if (is.null(dates)) r_1 else r_1[[dates]]

    # Per-pixel mean over the selected dates, ignoring cloud-masked pixels
    r_mean <- mean(r_sel, na.rm = TRUE)

    dirout <- file.path(root, paste0("temp_mosaic_", v))
    dir.create(dirout, showWarnings = FALSE)
    out <- file.path(dirout, paste0("temp_mosaic_v", v, "_", layers$suffix[k], ".asc"))
    writeRaster(r_mean, filename = out, format = "ascii", prj = TRUE,
                overwrite = TRUE)
  }
}
