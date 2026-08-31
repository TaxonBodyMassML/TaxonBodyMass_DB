# Fetch body mass data from rdataretriever datasets and save to Rdata.
# Requires Python + retriever package (see README Prerequisites).
# Called from RunMe.r when DataRetrieve = TRUE.
# Depends on: wd_rdata, FixFormatting(), FixMisspellings(), RemoveNonTaxa()

# mammal-life-hist: family available; no order column
mlh <- rdataretriever::fetch('mammal-life-hist')[[1]]
mlh$taxon <- paste(mlh$genus, mlh$species)
mlh <- mlh[, c('taxon', 'mass_g', 'family')]
mlh$family <- as.character(mlh$family)
mlh <- mlh[which(!is.na(mlh$mass_g) & mlh$mass_g > 0), ]
mlh$n <- 1
mlh$source_mass <- 'rdataretriever-mammal-life-hist'

# bird-size: family column is an integer code, not a name — drop it
bir <- rdataretriever::fetch('bird-size')[[1]]
bir <- bir[, c('species_name', 'm_mass')]
colnames(bir) <- c('taxon', 'mass_g')
bir <- bir[which(!is.na(bir$mass_g) & bir$mass_g > 0), ]
bir$n <- 1
bir$source_mass <- 'rdataretriever-bird-size'

# predator-prey-body-ratio: no taxonomy beyond binomial
ppb <- rdataretriever::fetch('predator-prey-body-ratio')[[1]]
ppb <- ppb[which(ppb$taxonomy_consumer != '' & ppb$taxonomy_resource != ''), ]
ppb1 <- ppb[, c('taxonomy_consumer', 'mean_mass_g_consumer')]
ppb2 <- ppb[, c('taxonomy_resource', 'mean_mass_g_resource')]
colnames(ppb1) <- colnames(ppb2) <- c('taxon', 'mass_g')
ppb <- bind_rows(ppb1, ppb2)
ppb <- ppb[which(!is.na(ppb$mass_g) & ppb$mass_g > 0), ]
ppb$n <- 1
ppb$source_mass <- 'rdataretriever-predator-prey-body-ratio'

# pantheria: order and family available
pan <- rdataretriever::fetch('pantheria')[[1]]
pan <- pan[, c('msw05_binomial', 'adultbodymass_g', 'msw05_order', 'msw05_family')]
colnames(pan) <- c('taxon', 'mass_g', 'order', 'family')
pan$order  <- as.character(pan$order)
pan$family <- as.character(pan$family)
pan <- pan[which(!is.na(pan$mass_g) & pan$mass_g > 0), ]
pan$n <- 1
pan$source_mass <- 'rdataretriever-pantheria'

# amniote-life-hist: EAV format — filter to adult body mass; class/order/family available
amn <- rdataretriever::fetch('amniote-life-hist')[[1]]
amn <- amn[amn$trait == 'adult_body_mass_g', ]
amn$taxon  <- paste(amn$genus, amn$species)
amn$mass_g <- as.numeric(amn$trait_value)
amn <- amn[, c('taxon', 'mass_g', 'classes', 'ordered', 'family')]
colnames(amn)[3:4] <- c('class', 'order')
amn$class  <- as.character(amn$class)
amn$order  <- as.character(amn$order)
amn$family <- as.character(amn$family)
amn <- amn[which(!is.na(amn$mass_g) & amn$mass_g > 0), ]
amn$n <- 1
amn$source_mass <- 'rdataretriever-amniote-life-hist'

# socean-diet-data: multi-table dataset — must index by name; no taxonomy beyond binomial
sdd <- rdataretriever::fetch('socean-diet-data')$diet
sdd1 <- sdd[, c('predator_name', 'predator_mass_mean')]
sdd2 <- sdd[, c('prey_name',     'prey_mass_mean')]
colnames(sdd1) <- colnames(sdd2) <- c('taxon', 'mass_g')
sdd <- bind_rows(sdd1, sdd2)
sdd <- sdd[which(!is.na(sdd$mass_g) & sdd$mass_g > 0), ]
sdd$n <- 1
sdd$source_mass <- 'rdataretriever-socean-diet-data'

# vertnet sources: load if files are available locally (too large for git;
# rdataretriever server download currently broken)
load_if_exists <- function(path) {
  if (!file.exists(path)) return(NULL)
  e <- new.env()
  load(path, envir = e)
  get(ls(e)[1], envir = e)
}

vra <- load_if_exists(file.path(wd_rdata, 'BodyMass_vertnet-amphibians.Rdata'))
vrr <- load_if_exists(file.path(wd_rdata, 'BodyMass_vertnet-reptiles.Rdata'))

adat <- bind_rows(mlh, bir, ppb, pan, amn, sdd, vra, vrr)
adat <- FixFormatting(adat)
adat <- FixMisspellings(adat)
adat <- RemoveNonTaxa(adat)
adat <- adat[which(!is.na(adat$mass_g) & adat$mass_g > 0), ]
for (col in c('class', 'order', 'family'))
  if (!col %in% names(adat)) adat[[col]] <- NA_character_
DR <- adat[adat$taxon != 0, ]

save(DR, file = file.path(wd_rdata, 'BodyMass_DataRetrieverAll.Rdata'))
