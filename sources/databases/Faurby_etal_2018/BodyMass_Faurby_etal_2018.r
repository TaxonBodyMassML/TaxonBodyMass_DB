adat <- read.csv(file.path(wd_source, 'Trait_data.csv'), header = TRUE)
# Keep extant species only: drop IUCN status EP (extinct in prehistory),
# EX (extinct) and EW (extinct in the wild).
adat <- adat[!(adat$IUCN.Status.1.2 %in% c('EP', 'EX', 'EW')), ]
taxon_tax <- adat[, c('Binomial.1.2', 'Order.1.2', 'Family.1.2')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Binomial.1.2), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$Order.1.2),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family.1.2), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Binomial.1.2', 'Mass.g', 'Mass.Method', 'Mass.Source')]
colnames(adat)[1:2] <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
# Phylogenetically imputed masses and masses taken from a relative of suggested
# similar size are not species-specific. 'Reported' values and the 'Assumed
# isometric based on <dimension>' / 'Estimated based on equation from
# <dimension>' values (a measured dimension of the species scaled to mass) are
# kept, the latter as allometry-derived values.
adat <- DropImputed(adat,
                    adat$Mass.Method == 'Imputed' | grepl('^As relative', adat$Mass.Method),
                    'Faurby_etal_2018',
                    'Mass.Method Imputed or As relative of suggested similar size')
# Provenance (issue #1, Stage 2): the work each mass was taken from is carried
# in the row itself (`Mass.Source`, a full citation or a bare 'Journal volume:
# pages (year)' string; 'Smith, F. A., et al. 2003 ... (Updated Version 4.1
# obtained from senior author)' on most rows, the hop-2 route to Smith_2003).
# The record keeps, as `ref_keys`, the hash key 'h:<sha1-8>' of the normalised
# citation string (ParseInRowCitations() / CitationHashKey(),
# R/library/citations/), one key per row; the same keys index
# sources/databases/Faurby_etal_2018/primary_references.csv. On the allometry
# rows (`Mass.Method` 'Assumed isometric based on <dimension>' or 'Estimated
# based on equation from <dimension>') `Mass.Source` is the work that measured
# the species' dimension, and `Mass.Comparison` / `Mass.Comparison.Source` the
# reference species and its source (README, Provenance); such a record carries
# the record-level override `prov_type = 'derived_allometry'` so that its
# provenance row says the value is computed, not reported.
adat$ref_keys  <- ParseInRowCitations(adat$Mass.Source)$keys
adat$prov_type <- ifelse(adat$Mass.Method == 'Reported', NA_character_, 'derived_allometry')
if (anyNA(adat$ref_keys)) warning('Faurby_etal_2018: ', sum(is.na(adat$ref_keys)), ' record(s) without a Mass.Source')
adat <- adat[, c('taxon', 'mass_g', 'ref_keys', 'prov_type')]
adat$n <- 1
adat$source_mass <- 'Faurby_etal_2018'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
FA <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'order', 'family', 'ref_keys', 'prov_type')]
save(FA, file = file.path(wd_rdata, 'BodyMass_Faurby_etal_2018.Rdata'))
