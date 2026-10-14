# Virunga Landsat Land-Cover Classification

R workflow for classifying land cover in the **Greater Virunga Landscape**, which spans
Uganda, Rwanda and the Democratic Republic of Congo. The study area is the Virunga
Conservation Area plus Bwindi Impenetrable National Park. The workflow uses
multi-temporal **Landsat 8** surface-reflectance imagery (path/row 173/061, 2014–2015)
and field vegetation plots.

The workflow covers:

- **Cloud masking and stacking.** Every band is masked with Fmask and stacked into a time series with [`bfastSpatial`](https://github.com/loicdtx/bfastSpatial).
- **Cloud-free mosaics.** Several dates are averaged per pixel to fill cloud gaps.
- **Extra input layers.** OVERLAND biophysical products (LAI, FAPAR, cover fractions…) and Sentinel-2 tiles are cropped to the study area.
- **Unsupervised classification.** Three methods are compared: k-means, CLARA and unsupervised random forest.
- **Supervised classification.** A random forest trained on field plots (still in progress).

## Workflow

Run the scripts in `R/` in numerical order. Each one sources `R/00_config.R`.

| Step | Script | What it does |
|---|---|---|
| 0 | `00_config.R` | Data folder (`base_dir`), study-area shapefile and shared helper |
| 1 | `01_landsat_process_full_scenes.R` | Extracts bands 1–7 + NDVI from the Landsat archives, applies Fmask and builds time stacks (full scenes) |
| 2 | `02_landsat_process_aoi_subset.R` | Same as step 1, cropped to the study area. Builds the stacks of the selected scenes used next |
| 3 | `03_landsat_temporal_mosaics.R` | Cloud-free temporal mosaics: per-pixel mean over 4 combinations of dates |
| 4 | `04_landsat_export_rgb_bands.R` | Exports red/green/blue bands of one date for visual interpretation |
| 5 | `05_kmeans_first_test.R` | First k-means test on one date (7 bands + NDVI, 12 clusters) |
| 6 | `06_crop_overland_products.R` | Crops 20 OVERLAND biophysical products to the study area |
| 7 | `07_crop_sentinel_mosaic.R` | Prepares Sentinel-2 tiles for the study area *(work in progress)* |
| 8 | `08_unsupervised_classification.R` | k-means, CLARA and unsupervised random forest (12 classes) on six Landsat 8 dates |
| 9 | `09_supervised_classification.R` | Loads field vegetation plots (9 classes) for a random-forest classification *(work in progress)* |

`R/ancillary/` holds two side scripts that tested ASTER imagery:

- `aster_hdf_to_geotiff.R` converts ASTER HDF scenes to GeoTIFF.
- `aster_mosaic_test.R` compares ways to mosaic overlapping scenes.

```
Landsat archives (.tar.gz)
  └─ 01/02  Fmask + band extraction ─► time stacks per band + NDVI
               ├─ 03  temporal mosaics (cloud-free)
               ├─ 04  RGB export
               └─ 05  k-means test
Landsat 8 scenes (6 dates) ─► 08  k-means | CLARA | unsupervised RF
Field plots + stacks       ─► 09  supervised random forest
OVERLAND products / Sentinel-2 ─► 06 / 07  cropped to study area
```

## Data

The imagery and field data are not included because of their size and data-sharing
restrictions. The scripts expect this folder layout under `base_dir`:

```
base_dir/
├── local_data/VCA_BINP_AOI.*                    study-area polygon
├── local_data/BINP_vegplot_wgs84utm35s/         field vegetation plots
├── ext2.shp                                     crop extent (step 2)
├── landsat/images_selection/LC8*_B[1-7].tif     Landsat 8 bands (step 8)
├── overland/landsat/catalogue/<product>/*.tif   OVERLAND products
├── sentinel/mosaic/*.jp2                        Sentinel-2 tiles
└── aster/*.hdf                                  ASTER scenes (ancillary)
```

Landsat surface-reflectance archives (USGS ESPA, with Fmask) are read from the
`landsat_imagery` folder of the `bfastSpatial` package.

## Requirements

These scripts were written in 2016 with R 3.x and use the `raster`/`sp` stack:

- `raster`, `sp`, `rgdal`
- `randomForest`, `cluster`
- `bfastSpatial` (from GitHub: `devtools::install_github("loicdtx/bfastSpatial")`)
- `gdalUtils` and a local GDAL install (ancillary ASTER scripts only)

> **Note:** `rgdal` and `rgeos` were retired from CRAN in 2023. To run the scripts on a
> current R version, install the archived packages, or port the scripts to
> `terra`/`sf`. In that case, `readOGR()` becomes `sf::st_read()` and
> `raster()`/`stack()` become `terra::rast()`.

## Author

Felipe Coelho Costa — WWF remote-sensing work on the Greater Virunga Landscape.
