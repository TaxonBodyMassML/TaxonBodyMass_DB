# Ribeiro Anunciação et al. (2025) Biodiversity Data Journal 13:e170578, ATLANTIC
# DUNG BEETLE TRAITS (ATLANTIC_DUNG_BEETLE_TRAITS_revised.csv, CC0). Two mass
# columns are used: 'Biomass (g)' (records compiled from 29 published studies) and
# 'Biomass (mean - g) (g)' (species means from up to 15 individuals weighed by the
# authors to 0.001 g). The data set does not state dry vs fresh mass; by owner
# decision (2026-09-29) values are treated as fresh (wet) mass. Species names carry
# subgenera in parentheses and author/year strings, which are stripped; taxa not
# identified to species ('sp.', 'aff.', morphospecies) are dropped.
adat <- read.csv(file.path(wd_source, 'ATLANTIC_DUNG_BEETLE_TRAITS_revised.csv'),
                 header = TRUE, stringsAsFactors = FALSE, check.names = FALSE,
                 na.strings = c('', 'NA'), fileEncoding = 'UTF-8-BOM')
nm <- adat$species
nm <- gsub('\\s*\\([^)]*\\)', '', nm)                       # drop (Subgenus) and (Author, year)
nm <- sub('^([A-Z][a-z]+ [a-z]+).*$', '\\1', trimws(nm))    # keep binomial, drop authors/subspecies
ok <- grepl('^[A-Z][a-z]+ [a-z]+$', nm) & !grepl('\\b(sp|spp|cf|aff|nr|indet)\\b', nm)
mass_cols <- c('Biomass (g)', 'Biomass (mean - g) (g)')
out <- do.call(rbind, lapply(mass_cols, function(col) {
  m <- suppressWarnings(as.numeric(adat[[col]]))
  data.frame(taxon = nm, mass_g = m, stringsAsFactors = FALSE)[ok & !is.na(m) & m > 0, ]
}))
out$class  <- 'Insecta'
out$order  <- 'Coleoptera'
out$family <- 'Scarabaeidae'
out$mass_type <- 'wet'
out$mass_group <- 'insect'
out$n <- 1
out$source_mass <- 'Anunciacao_etal_2025'
ANU <- out[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family',
               'mass_type', 'mass_group')]
save(ANU, file = file.path(wd_rdata, 'BodyMass_Anunciacao_etal_2025.Rdata'))
