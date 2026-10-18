# Verberk et al. (2020) Proc. R. Soc. B 287:20200488, Dryad 10.5061/dryad.tqjq2bvv9.
# latin1-encoded; fileEncoding needed so trimws() on raw bytes does not fail.
adat <- read.csv(file.path(wd_source, 'Diving_dataset.csv'), header = TRUE,
                 fileEncoding = 'latin1', stringsAsFactors = FALSE)
adat$taxon   <- trimws(adat$Species)
adat$mass_g  <- suppressWarnings(as.numeric(adat$Mass..kg.)) * 1000
adat <- adat[!is.na(adat$mass_g), ]
# key_map.csv: full citation text -> abbreviated key (built by build_references.py)
key_map_path <- file.path(wd_source, 'key_map.csv')
key_map <- if (file.exists(key_map_path)) {
  km <- read.csv(key_map_path, stringsAsFactors = FALSE, colClasses = 'character',
                 fileEncoding = 'utf-8')
  setNames(km$key, km$citation_text)
} else character(0)
src_raw <- trimws(adat$Literature.source)
src_raw[src_raw %in% c('', 'NA')] <- NA_character_
adat$ref_keys <- vapply(src_raw, function(x) {
  if (is.na(x)) return(NA_character_)
  k <- key_map[x]
  if (is.na(k)) NA_character_ else k
}, character(1), USE.NAMES = FALSE)
adat$n <- 1
adat$source_mass <- 'Verberk_2020'
VE <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(VE, file = file.path(wd_rdata, 'BodyMass_Verberk_2020.Rdata'))
