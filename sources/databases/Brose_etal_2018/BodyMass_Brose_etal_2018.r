# GATEWAy (Brose 2018, iDiv dataset 283 v3): mean body masses of the consumers
# and resources of 290 food webs (222,151 trophic links; grams fresh mass per
# the database metadata and Brose et al. 2019 SI). See README.md.
#  1. Consumer and resource rows are stacked; only adult, female, male or
#     unspecified life stages with a positive mean mass are kept
#     (StackGateway(), R/library/foodweb_units.r).
#  2. Group-level placeholder values (a mean mass shared by >= 5 taxa of one
#     link.citation: 0.01 g on 115 tide-pool species, 4.01e-5 g on 37
#     Chesapeake species, ...) are dropped as imputed, one log entry per
#     citation (DropPlaceholders(); issue #14, owner decision 2026-10-03).
#  3. The per-web actions of foodweb_units.csv are applied: the tide pools
#     outside the Gulf of St Lawrence, Skipwith Pond and the Taieri tributaries
#     are dropped with a logged reason; the dry-mass webs (Gearagh, Hengill,
#     Dutch grassland soils, UK streams) are converted to wet grams with the
#     taxon groups of foodweb_units_groups.csv (ToWetMass(from = 'dry'), shelled
#     molluscs as whole wet mass) and carry the conversion CiteIDs in
#     source_mass (ApplyUnitActions()). All other webs are kept as reported.
adat   <- read.csv(file.path(wd_source, '283_2_FoodWebDataBase_2018_12_10.csv'), header = TRUE)
units  <- read.csv(file.path(wd_source, 'foodweb_units.csv'),
                   stringsAsFactors = FALSE, na.strings = c('', 'NA'))
groups <- read.csv(file.path(wd_source, 'foodweb_units_groups.csv'),
                   stringsAsFactors = FALSE, na.strings = c('', 'NA'))

adat <- StackGateway(adat)
adat <- DropPlaceholders(adat, 'link.citation', 'Brose_etal_2018')
adat <- ApplyUnitActions(adat, units, key = 'foodweb.name', groups = groups,
                         group_key = 'link.citation', label = 'Brose_etal_2018')
BRO <- adat[, c('taxon', 'mass_g', 'n', 'source_mass')]
save(BRO, file = file.path(wd_rdata, 'BodyMass_Brose_etal_2018.Rdata'))
