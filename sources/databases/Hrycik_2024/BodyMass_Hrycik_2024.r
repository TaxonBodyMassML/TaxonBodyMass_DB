adat <- read.csv(file.path(wd_source, 'IndividualWeights_AllData.csv'), header = TRUE)

# For taxa with an All-lakes/All-depths/All-basins summary row, use only that row
# to avoid double-counting with lake- or depth-specific rows.
# For taxa with no such row, retain all strata rows so RunMe.r Pass 1 can
# compute the within-source geometric mean across strata.
all_taxa <- adat$Name[adat$Lake == 'All' & adat$DepthZone_m == 'All' & adat$Basin == 'All']
adat <- adat[
  ( adat$Name %in% all_taxa & adat$Lake == 'All' & adat$DepthZone_m == 'All' & adat$Basin == 'All') |
  (!adat$Name %in% all_taxa),
]

adat <- adat[, c('Name', 'AverageIndividualWeight_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- adat[adat$mass_g > 0, ]
adat$n <- 1
adat$source_mass <- 'Hrycik_2024'
HRY <- adat
save(HRY, file = file.path(wd_rdata, 'BodyMass_Hrycik_2024.Rdata'))
