# Hrycik et al. (2024) Great Lakes benthic invertebrate individual weights

Source: Hrycik, A. R. (2024) Individual weight estimates for Great Lakes benthic invertebrates. Dryad. https://doi.org/10.5061/dryad.tx95x6b42 (bib key `Hrycik:2024aa`, `Citation.bib`).
Data: `IndividualWeights_AllData.csv` and `SpeciesList.csv`, the files of the Dryad deposit; the deposit's own README follows below the rule.
Licence: unknown; owner to check https://doi.org/10.5061/dryad.tx95x6b42 (this README is the Dryad README of the deposit and states no licence; Dryad deposits are CC0 by repository policy, not quoted on disk). The two csv files are tracked; see sources/LICENSES.md.
Source label: `Hrycik_2024`.

Columns used, Filters, Mass type and Imputed rows: the parse script `BodyMass_Hrycik_2024.r` documents the columns read and the filters applied; the full README in the convention of the other source folders is pending (issue #6, 2026-10-06).

---

# Data from: Individual weight estimates for Great Lakes benthic invertebrates

[https://doi.org/10.5061/dryad.tx95x6b42](https://doi.org/10.5061/dryad.tx95x6b42)

The files in this data set give information for benthic invertebrate weights for the Laurentian Great Lakes.
See companion data manuscript text for calculation methods. All files are formatted as comma-separated values and missing data are denoted with "NA."

## Description of the data and file structure

Description for file "IndividualWeights_AllData.csv"
This file gives summary statistics of individual weights for species to the highest possible taxonomic
resolution, and separates by lake, depth, and/or basin when necessary. The column headers are as follows:
Name (character string) = Name of the taxonomic unit represented. Species in most cases.
Lake (character string) = Great Lake(s) represented in grouping. "All" indicates that all possible data from the Great Lakes was combined.
DepthZone_m (character string) = Depth zone represented in grouping, either >=70 m or < 70 m. "All" indicates that data from all lake depths were combined.
Basin (character string) = Lake basin represented in grouping. "All" indicates that data from all lake basins are included.
AverageIndividualWeight_g (numeric) = Mean weight of an individual benthic invertebrate of the given taxonomic unit in grams.
SE_weight (numeric) = Standard error of mean individual weight.
MedianIndividualWeight_g (numeric) = Median weight of an individual benthic invertebrate of the given taxonomic unit in grams.
MinimumIndividualWeight_g (numeric) = Minimum weight of an individual benthic invertebrate of the given taxonomic unit in grams.
MaximumIndividualWeight_g (numeric) = Maximum weight of an individual benthic invertebrate of the given taxonomic unit in grams.
SampleSize_Nsamples (integer) = Sample size for a given taxonomic unit. Represents the number of samples in which the taxonomic unit was present.
\-----
Description for file "IndividualWeights_MajorGroups.csv"
This file has summary statistics for major taxonomic groups of benthic macroinvertebrates in different lakes, depth zones, and for Dreissena, the three basins of Lake Erie. The column headers are as follows:
Name (character string) = Name of the taxonomic unit represented.
Lake (character string) = Great Lake(s) represented in grouping. "All" indicates that all possible data from the Great Lakes was combined.
DepthZone_m (character string) = Depth zone represented in grouping, either >=70 m or < 70 m. "All" indicates that data from all lake depths were combined.
Basin (character string) = Lake basin represented in grouping. "All" indicates that data from all lake basins are included.
AverageIndividualWeight_g (numeric) = Mean weight of an individual benthic invertebrate of the given taxonomic unit in grams.
SE_weight (numeric) = Standard error of mean individual weight.
MedianIndividualWeight_g (numeric) = Median weight of an individual benthic invertebrate of the given taxonomic unit in grams.
MinimumIndividualWeight_g (numeric) = Minimum weight of an individual benthic invertebrate of the given taxonomic unit in grams.
MaximumIndividualWeight_g (numeric) = Maximum weight of an individual benthic invertebrate of the given taxonomic unit in grams.
SampleSize_Nsamples (integer) = Sample size for a given taxonomic unit. Represents the number of samples in which the taxonomic unit was present.
\-----
Description for file "SpeciesList.csv"
This file shows which taxa were grouped for calculations. The column headers are as follows:
Name (character string) = Name of the taxonomic unit represented following the format “Genus species” or “Genus species subspecies” if subspecies is known. Abbreviations: sp. = unknown species; spp. = unknown species but genus likely encompasses multiple species.
Group (character string) = Higher taxonomic used to classify the species for calculations in file "IndividualWeights_MajorGroups.csv."
Filters: for a taxon with an all-lakes, all-depths, all-basins summary row only that row is read (the lake-, depth- and basin-specific rows would double count it); a taxon without one keeps all its strata rows, which RunMe Pass 1 reduces to their geometric mean; positive `AverageIndividualWeight_g` only. The group labels 'Oligochaeta Fragments', 'Tubificid fragment', 'Naidid fragment' and 'Oligochaeta immature' are removed by the `_fragment(s)` / `_immature(s)` rules of `R/library/fix_nontaxa.r` (issue #44; `SpeciesList.csv` also lists 'Enchytraeid fragment', 'Lumbriculid fragment' and 'Immature lumbriculid', which carry no weight row), 'immature tubificid with hairs' / 'without hairs' are dropped as life-stage rows by the raw-name rules of `audit/raw_name_patterns.csv` (issue #38), and the 'Unid.' and 'sp.' / 'spp.' placeholders leave `FixFormatting()` as markers that `fix_nontaxa.r` removes.
Imputed rows: none flagged in source.
