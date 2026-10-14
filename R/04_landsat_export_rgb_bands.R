################################################################################
# 04_landsat_export_rgb_bands.R
# Step 4: export the red, green and blue bands of one scene for visual
#         interpretation (true-colour composite) in a GIS
#
# Input : cropped, cloud-masked scenes from step 2 (bfmspatial_<b>_ext/selection/)
# Output: land_images/image_1_red.asc, image_1_green.asc, image_1_blue.asc
#
# Band numbers follow Landsat 8 OLI: band 2 = blue, 3 = green, 4 = red.
################################################################################

library(raster)

source("R/00_config.R")

# List the processed scenes of each band (one file per date)
band_files <- lapply(landsat_bands, function(b) {
  list.files(file.path(base_dir, paste0("bfmspatial_", b, "_ext"), "selection"),
             pattern = glob2rx("*.grd"), full.names = TRUE)
})

# Take the first date: one file per band (bands 1-7)
img_1 <- sapply(band_files, `[`, 1)

# Full 7-band image of that date (kept for inspection)
image_1 <- stack(img_1)

image_red   <- raster(img_1[4])
image_green <- raster(img_1[3])
image_blue  <- raster(img_1[2])

# Write each band as an ESRI ASCII grid with a .prj file
dirout <- file.path(base_dir, "land_images")
dir.create(dirout, showWarnings = FALSE)

writeRaster(image_red,   filename = file.path(dirout, "image_1_red.asc"),
            format = "ascii", prj = TRUE, overwrite = TRUE)
writeRaster(image_green, filename = file.path(dirout, "image_1_green.asc"),
            format = "ascii", prj = TRUE, overwrite = TRUE)
writeRaster(image_blue,  filename = file.path(dirout, "image_1_blue.asc"),
            format = "ascii", prj = TRUE, overwrite = TRUE)

# True-colour preview
plotRGB(image_1, r = 4, g = 3, b = 2, stretch = "lin")
