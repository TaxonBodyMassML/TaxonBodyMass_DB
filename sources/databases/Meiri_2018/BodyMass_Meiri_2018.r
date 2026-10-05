# Meiri (2018, Global Ecol. Biogeogr. 27:1168, doi 10.1111/geb.12773): the trait
# table of the world's lizards (Appendix S1, geb12773-sup-0001-appendixs1.csv,
# cp1252). No mass is measured: it is computed here from the table's maximum
# SVL through the clade-specific Feldman et al. (2016) equation the table gives
# for each species (columns intercept and slope; 'mass_equation (Feldman et al.
# 2016 unless stated)'), so the source is `derived_allometry` in the provenance
# registry with Feldman:2016aa as its equation reference. The length sources
# are the three SVL reference columns ('References: SVL of unsexed individuals,
# neonates and hatchlings', 'References: SVL of females', 'References: SVL of
# males'; author-year keys of Appendix S3, comma-separated, a few cells with
# ';'), kept as ref_keys (issue #1): the cells are joined and split with
# SplitRefKeys(), and each raw key is mapped through key_map.csv (written by
# build_references.r from Appendices S1 and S3) to its references.csv key
# wherever the raw form is not the key of one unique Appendix S3 entry (a year
# letter, a spelling the key table does not use, or a key the table holds for
# several papers, told apart by their Taxa column); a key that stays ambiguous
# or has no entry keeps its raw form (reported as unmatched_key). The fourth
# reference column, 'References (Biology: all columns except M, N and O)', backs
# the other traits and not the SVL (M, N, O), and is not used.
adat <- read.csv(file.path(wd_source, 'geb12773-sup-0001-appendixs1.csv'),
                 fileEncoding = 'cp1252', encoding = 'UTF-8')
adat$taxon <- gsub('.*: (.*)', '\\1', adat$Binomial)
taxon_tax <- adat[, c('taxon', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[, c('taxon', 'family')]

intercept <- as.numeric(adat$intercept)
slope     <- as.numeric(adat$slope)
suppressWarnings(
  maxSVL <- as.numeric(adat$maximum.SVL)
)
adat$mass_g <- round(10^(intercept + slope * log(maxSVL, 10)), 3)
adat <- adat[!is.na(adat$mass_g), ]
# the SVL references of every record -> references.csv keys (issue #1)
svl_cols <- c('References..SVL.of.unsexed.individuals..neonates.and.hatchlings',
              'References..SVL.of.females', 'References..SVL.of.males')
cells <- apply(adat[, svl_cols], 1, function(r) {
  r <- r[!is.na(r) & nzchar(trimws(r))]
  if (length(r) == 0) NA_character_ else paste(r, collapse = ';')
})
raw_keys <- SplitRefKeys(cells, '[,;]')
key_map  <- read.csv(file.path(wd_source, 'key_map.csv'), stringsAsFactors = FALSE,
                     encoding = 'UTF-8', na.strings = character())
ex <- ExplodeRefKeys(raw_keys)
m  <- match(paste(adat$taxon[ex$record], ex$native_key, sep = '\r'),
            paste(key_map$taxon, key_map$raw_key, sep = '\r'))
ex$key <- ifelse(is.na(m), ex$native_key, key_map$key[m])
mapped <- tapply(ex$key, ex$record, function(k) paste(unique(k), collapse = '; '))
adat$ref_keys <- NA_character_
adat$ref_keys[as.integer(names(mapped))] <- unname(mapped)
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat$n <- 1
adat$source_mass <- 'Meiri_2018'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
ME <- adat
save(ME, file = file.path(wd_rdata, 'BodyMass_Meiri_2018.Rdata'))
