# Uyeda et al. (2017) American Naturalist 190:185-199. vertData.csv (Dryad
# 10.5061/dryad.3c6d2, CC0): species-level standard metabolic rate data set;
# lnMass is the natural log of body mass in grams (857 vertebrate species,
# cleaned from White et al. 2006 and McKechnie & Wolf 2004). Row names are
# Genus_species.
adat <- read.csv(file.path(wd_source, 'vertData.csv'), header = TRUE,
                 stringsAsFactors = FALSE, row.names = 1)
adat <- data.frame(taxon  = gsub('_', ' ', rownames(adat)),
                   mass_g = exp(suppressWarnings(as.numeric(adat$lnMass))),
                   endo   = adat$endo,
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# Fish species in this SMR compilation are small/juvenile individuals (median
# 0.4 log10 below other sources). vertData.csv carries no class column, so fishes
# are identified as ectotherms (endo == 0) whose genus occurs in the FishBase
# cache (sources/Rdata/BodyMass_Fishbase.Rdata) and dropped.
fb_env <- new.env(); load(file.path(wd_rdata, 'BodyMass_Fishbase.Rdata'), envir = fb_env)
fish_genera <- unique(sub(' .*$', '', get(ls(fb_env)[1], envir = fb_env)$taxon))
adat <- adat[!(adat$endo == 0 & sub(' .*$', '', adat$taxon) %in% fish_genera), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon), ]
adat$mass_type <- 'wet'
adat$mass_group <- 'vertebrate'
adat$n <- 1
adat$source_mass <- 'Uyeda_etal_2017'
UYE <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'mass_type', 'mass_group')]
save(UYE, file = file.path(wd_rdata, 'BodyMass_Uyeda_etal_2017.Rdata'))
