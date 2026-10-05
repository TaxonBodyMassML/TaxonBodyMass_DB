# Data and code from: Corticosterone concentration varies with metabolic rate in vertebrates

Dataset DOI: [10.5061/dryad.79cnp5jbt](https://doi.org/10.5061/dryad.79cnp5jbt)

## Description of the data and file structure

This dataset contains all data and R code for analysis associated with article "Corticosterone Concentration Varies with Metabolic Rate". The dataset includes glucocorticoid hormone concentrations, maximum lifespan, body mass, mass-specific metabolic rate, and study-level metadata  compiled from published literature of 160 species across three vertebrate classes (reptiles, birds, and mammals). Data were used to examine the allometric relationships between baseline and elevated corticosterone concentrations, body mass, mass-specific metabolic rate, and maximum lifespan across taxa. Results show negative correlations between baseline corticosterone concentrations and body mass, and positive correlations between baseline corticosterone concentrations and mass-specific metabolic rate. There was no correlation between baseline corticosterone concentrations and lifespan when controlling for metabolic rate. Baseline and elevated corticosterone concentrations show a strong, positive relationship across species. 

### Files and variables

### File: VertData.xlsx

**Description:** Microsoft Excel workbook containing all data used in analyses, organized across three sheets by reptiles, birds, and mammals (n = 49, 83, 35, respectively). Data include baseline and elevated glucocorticoid concentrations (corticosterone and cortisol), body mass, maximum lifespan, mass-specific metabolic rate, and study-level metadata including sex, sample size, breeding season, life stage, environment, assay method, and stressor type.

##### Variables

| Column                      | Description                                                                                                                                                                            | Units                                    |
| :-------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------- |
| Species Name                | Scientific name of  species                                                                                                                                                            | <br />                                   |
| Common Name                 | Common name of the species                                                                                                                                                             | <br />                                   |
| Sex                         | Sex of individuals sampled (M = male, F = female, B = both sexes combined)                                                                                                             | <br />                                   |
| n                           | Number of sampled individuals                                                                                                                                                          | count                                    |
| Season                      | Breading season  of individuals (Breeding or Non-breeding)                                                                                                                             | <br />                                   |
| Life Stage                  | Life history stage of individuals (e.g., Adult, Juvenile)                                                                                                                              | <br />                                   |
| Lifespan                    | Maximum  lifespan for the species                                                                                                                                                      | years                                    |
| Body Mass                   | Body mass                                                                                                                                                                              | grams (g)                                |
| MSMR                        | Mass-specific metabolic rate                                                                                                                                                           | (reptiles = W/g, birds & mammals = mW/g) |
| Basal CC                    | Baseline corticosterone concentration                                                                                                                                                  | ng/mL                                    |
| Basal Cortisol              | Baseline cortisol concentration                                                                                                                                                        | ng/mL                                    |
| Elevated CC                 | Stress-induced corticosterone concentration                                                                                                                                            | ng/mL                                    |
| Time Range                  | Time elapsed between initial capture and blood sample collection (<3 = less than 3 minutes, >3 = greater than 3 minutes)                                                               | minutes                                  |
| Assay Method                | Assay method used to quantify hormone concentrations (RIA = radioimmunoassay, EIA = enzyme immunoassay, ELISA = enzyme-linked immunosorbent assay, DIDA = double-antibody immunoassay) | <br />                                   |
| Environment                 | Study conditions (Captive or Field)                                                                                                                                                    | <br />                                   |
| Stressor                    | Type of stressor  (ACTH injection, Restraint, or Other)                                                                                                                                | <br />                                   |
| **For Reptiles only&#xA0;** | <br />                                                                                                                                                                                 | <br />                                   |
| Temp                        | Body temperature or environmental temperature of sampled individuals                                                                                                                   | °C                                       |
| **For Mammals only**        | <br />                                                                                                                                                                                 | <br />                                   |
| Dominant                    | Whether species in dominant or non-dominant in corticosterone (D = corticosterone dominant, ND = cortisol dominant)                                                                    | <br />                                   |

#### Missing Data

Blank cells indicate data were not available or not reported in the source publication for that variable. Not all species have complete data for every column. These cells default to "NA" in following R scripts. 

### File: VertCleanTree.R

**Description:** R script for constructing the phylogenetic tree for all species included in analyses and exports the resulting phylogeny as a Nexus (.nex) file. This script must be run first, as the exported Nexus file is required as input for Master_Models.R.

### File: Master_Models.R

**Description:** R script containing all primary statistical analyses. Includes phylogenetic generalized least squares (PGLS) models examining allometric relationships between baseline and elevated corticosterone concentrations, body mass, mass-specific metabolic rate (MSMR), and maximum lifespan across reptiles, birds, and mammals. Also includes model selection procedures, residual calculations, and generation of all figures. Requires the Nexus file produced by VertCleanTree.R as input.

## Access information

All data were compiled from peer-reviewed published literature. Full citations for source publications are provided in the supplementary materials of the associated manuscript.
