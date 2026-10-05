# Metabolic traits are shaped by phylogenetic conservatism and environment, not just body size

[https://doi.org/10.5061/dryad.d7wm37qb7](https://doi.org/10.5061/dryad.d7wm37qb7)

## Description of the data and file structure

See the methods section for details on metabolic data collection and analysis.

**Files:**

mr_ant_525.csv: Main data CSV containing metabolic rate data and ventilation patterns for individual ants collected from six environmental locations, including climatic and soil P variables and activity data

metadata_mr_ant.csv: A list of the column headings from mr_ant_525.csv with the metadata and detailed descriptions, units, and NA value indications for each parameter and trait

mr_ant_models.R: An annotated R script with the data wrangling and main analysis for the findings presented in the manuscript

mr_ant_supp_analysis.R: An annotated R script with supplementary tests to support findings from the main models

mr_genus_tree.tre: A genus phylogenetic tree of 34 ant genera used in the study

mr_phylo.tre: A site-species level tree of 139 site-species (where species at sites (n = 11) are tips) containing soft polytomies built off a genus level tree.

mr_ant_climate_modelling.zip: A folder containing annotated R scripts and data files to create interpolated climate variables for sites at the macroscale (from worldclim 2.1 - not used in main analysis) and microscale (microclimate models of temperature and vapor pressure deficit). 

### Files and variables

#### File: metadata_mr_ant.csv

**Description:** Metadata for mr_ant_525.csv

#### File: mr_genus_tree.tre

**Description:** A genus-level phylogeny of ant genera used in the study. Phylogenetic tree modified from Economo et al. (2018). Macroecology and macroevolution of the latitudinal diversity gradient in ants. Nature Communications. 9:1-8.

#### File: mr_phylo.tre

**Description:** A species-level phylogeny of ant "species" used in the study, where tips are soft polytomies with species at sites as separate tips. Phylogenetic tree modified from Economo et al. (2018). Macroecology and macroevolution of the latitudinal diversity gradient in ants. Nature Communications. 9:1-8.

#### File: mr_ant_525.csv

**Description:** Main data text file. See the metadata CSV for descriptions of variables.

#### Folder: mr_ant_climate_modelling.zip

**Description:** A folder containing annotated R scripts and data files to create interpolated climate variables for sites at the macroscale (from worldclim 2.1 - not used in main analysis) and microscale (microclimate models of temperature and vapor pressure deficit). 

##### Zipped Folder Files Metadata:

**climate_modelling.R** – R script to run analyses for obtaining microclimate data layers used in the main analysis. Includes link and details on downloading Worldclim 2.1 files for producing the macroclimate layers.

**metadata_mr_ant_climate_modelling** - Metadata for mr_ant_climate_modelling.zip

**macroclim_mean_annual.csv** - Interpolated climate variables at macroscale using worldclim 2.1

Variables:

* site: location name abbreviation matches to ‘location2’ column in mr_ant_525.csv
* site.pcat: location name plus site phosphorus category (HP = high phosphorus, LP = low phosphorus)
* long: longitude
* lat: latitude
* mat = Mean annual macroclimate temperature (Worldclim 2.1) (°C) Bio1 30s
* map = Mean annual macroclimate precipitation (Worldclim 2.1) (mm) Bio12 30s

**microclim_2009_2023_annual_means.csv** - output from climate_modelling.R analysis

Variables:

* id: site ID identifier - output from microclimate model
* mat.micro: Mean annual microclimate temperature per site (°C)
* mat.rhmicro: Mean annual microclimate relative humidity (%)
* site.pcat: location name plus site phosphorus category (HP = high phosphorus, LP = low phosphorus)
* mavpd.micro: Mean annual vapor pressure deficit per site in (kPa)

**microclim_2009_2023_warmestquarter_means.csv**

same column values as for microclim_2009_2023_annual_means.csv, but for microclimate variable output for the Austral summer - warmest quarter months of December to February

**shade.csv** - Vegetation shade data collected in plots at each site. Shade is measured at 9 1x1m square quadrats per plot with 4 plots per site, 8 plots per location. Shade variables used in climate_modelling.R for parameterizing the microclimate model.

Variables:

* Site: location name abbreviation matches to ‘location2’ column in mr_ant_525.csv
* p.categorical: phosphorus category of site (HP = high phosphorus, LP = low phosphorus)
* site.pcat: location name plus site phosphorus category (HP = high phosphorus, LP = low phosphorus)
* site.plot: location name plus site phosphorus category plus plot ID (1-4)
* lat: Latitude of plot
* long: Longitude of plot
* quadrat: Quadrat number per plot (1-9)
* shade: % vegetation cover aggregated shrub, canopy layers with maximum set to 100%

#### Code/software

#### File: mr_ant_models.R 

**Description:** Data wrangling and main models used in analysis. All packages are provided at the beginning of the code. Code run with R version 4.1.1 "Kick Things"

#### File: mr_ant_supp_analysis.R

**Description:** Data wrangling and supplementary analysis to support the main models. All packages are provided at the beginning of the code. Code run with R version 4.1.1 "Kick Things"

#### File: climate_modelling.R

**Description:** File in zipped folder "mr_ant_climate_modelling.zip": Annotated R script to run analyses for obtaining microclimate data layers and macroclimate data layers used in the main analysis. Code run with R version 4.1.1 "Kick Things"
