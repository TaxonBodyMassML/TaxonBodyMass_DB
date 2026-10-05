# StoichLife: A global dataset of plant and animal elemental content

[https://doi.org/10.5061/dryad.3tx95x6r2](https://doi.org/10.5061/dryad.3tx95x6r2)

## Description of the data and file structure

*Data compilation*

We developed the StoichLife template structure, which contains data about elemental content and their ratios (%C, %N, %P, C: N, C:P, and N:P) alongside body size measurements, and information regarding sampling locality, country, and taxonomic affiliation (i.e., phylum, class, order, family, species or morphospecies). This template was disseminated among prospective data contributors actively sampling and analyzing plant and animal elemental content across diverse regions worldwide (between 2014 and 2022). In our endeavor, we engaged 24 researchers who contributed datasets on animals (both invertebrates and vertebrates), resulting in 50 datasets, among which some were already published (15 datasets and one dataset from two sources). Additionally, we incorporated datasets from six large databases used in prior studies, including one dataset for zooplankton, 20 datasets for aquatic animals, five datasets for animals and plants 10, three datasets for coral reef macroalgae (Pangaea database), 80 datasets for green leaves, and 35 datasets for plants. The primary criteria for data inclusion were that: (i) elemental analyses were conducted on individual organisms under natural conditions, excluding those subjected to experimental manipulations such as nutrient enrichment; (ii) for animals, analyses were performed on whole-body (bulk) tissue, while plant stoichiometry was commonly described by leaf or shoot elemental composition; and (iii) georeferenced coordinates of sampling sites were available to facilitate spatial analyses.

*Data Search*

In parallel with acquiring data from new contributors and existing large databases, we conducted a systematic literature review to identify ecological stoichiometry studies published before 2021. Using Clarivate Analytics’ Web of Science Core database, we employed a set of search terms: “nutrient content” OR “nutrient composition” OR “elemental content” OR “elemental composition” OR “chemical composition” OR “nitrogen content” OR “nitrogen composition” OR “phosphorus content” OR “phosphorus composition” OR “percent nitrogen” OR “percent phosphorus” OR “N:P” OR “nitrogen-to-phosphorus” OR “ecological stoichiometry.” This rigorous search yielded 2,620 unique papers meeting our initial criteria.

Given our focus on obtaining individual-level data on the elemental content of plants and animals under natural conditions, we excluded (i) microbial data, as these typically involve analyses of entire microbial communities rather than individual cells, and (ii) studies involving laboratory or field experiments. Moreover, we omitted literature reviews and opinion papers, refining our initial search to a subset of 110 eligible papers. After thoroughly examining these papers, we narrowed the selection down to 33 papers that met our criteria 8,35–66. In cases where downloaded, archived datasets lacked essential data at the desired resolution (such as datasets reporting species means), we proactively contacted the respective authors to request access to the raw data.

Finally, we cross-referenced all identified datasets, the most comprehensive synthesis study on animal stoichiometry. However, additional datasets were kept from meeting our criteria through this process. These unpublished data represent a valuable resource that can now be harnessed to address stoichiometric questions using StoichLife. In compiling plant and animal stoichiometry data, we also gathered information on the spatial coordinates of the sampling locations. If this information was not explicitly provided in the publications, we contacted the corresponding authors to acquire the necessary spatial coordinates of the sampling sites. Despite its inherent limitations, the StoichLife database is the most comprehensive compilation of animal and plant data from terrestrial, freshwater, and marine realms across the globe to date. NAs represent not available or non-existing data to us.

### Files and variables

#### File: StoichLife\_dataset\_2025\_02\_14.xlsx

This file contains three sheets:

1. **Metadata Descriptions** – Provides detailed explanations of the dataset's variables and structure.
2. **References** – Lists all sources linked to the data, including published studies and unpublished datasets provided by authors. An additional file in the paper outlines the basic methods used for unpublished data.
3. **Data** – Contains the primary dataset.

The **Metadata sheet** in the data file contains the description of all the variables along with their corresponding units.

## Code/software

R (version 4.0.0 2020-04-24).

This submission includes a « **datapaper_sbiomap*SciDat.R****«, which is the code used and »StoichLife*data_2025_02_14.xlsx », which contains the dataset associated.
