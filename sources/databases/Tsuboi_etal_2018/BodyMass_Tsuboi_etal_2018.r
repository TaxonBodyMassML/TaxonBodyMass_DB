# Tsuboi et al. (2018) Nature Ecology & Evolution 2:1492-1500. Brain-body data for
# jawed vertebrates; six xlsx files (Springer Nature figshare 6803276, CC0), one
# row per observation (individual or pooled sample). Body mass in grams.
# Rows explicitly labelled as non-adult (subadult, juvenile, immature) are
# dropped; 'unknown' age class is retained for tetrapods (offsets vs other
# sources are ~0) but not for fishes, where only adult-labelled rows are used.
files <- c(teleost   = 'teleost.xlsx',   amphibian = 'amphibian.xlsx',
           bird      = 'bird.xlsx',      mammal    = 'mammal.xlsx',
           reptile   = 'reptile.xlsx',   shark_ray = 'shark_ray.xlsx')
# Reference key lookup: citation string -> key (references.csv, one entry per unique string)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character',
                 encoding = 'UTF-8', fileEncoding = 'UTF-8')
  setNames(rl$key, rl$citation)
} else character(0)
out <- list()
for (grp in names(files)) {
  d <- readxl::read_excel(file.path(wd_source, files[grp]), sheet = 1,
                          na = c('', 'NA', 'None'))
  d <- as.data.frame(d)
  names(d) <- trimws(names(d))
  mass_col <- grep('^Body (mass|weight) \\(g\\)$', names(d), value = TRUE)[1]
  age_col  <- grep('^Age Class$', names(d), value = TRUE)[1]
  age <- trimws(tolower(as.character(d[[age_col]])))
  keep <- is.na(age) | age == '' | age == 'unknown' | grepl('^adult|^young adult', age)
  # Fishes: 'unknown'-age specimens are mostly small (juvenile) individuals and
  # sit ~0.5 log10 below other sources, so keep only records labelled adult.
  if (grp %in% c('teleost', 'shark_ray')) keep <- grepl('^adult', age)
  d <- d[keep, ]
  d$taxon <- trimws(paste(d$Genus, d$Species))
  ref_col <- grep('^Reference$', names(d), value = TRUE)[1]
  ref_raw <- if (!is.na(ref_col)) trimws(as.character(d[[ref_col]])) else rep(NA_character_, nrow(d))
  ref_keys <- if (length(ref_lookup) > 0) ref_lookup[ref_raw] else rep(NA_character_, nrow(d))
  ref_keys[is.na(ref_raw)] <- NA_character_
  res <- data.frame(taxon    = d$taxon,
                    mass_g   = suppressWarnings(as.numeric(d[[mass_col]])),
                    order    = iconv(as.character(d$Order),  to = 'ASCII//TRANSLIT'),
                    family   = iconv(as.character(d$Family), to = 'ASCII//TRANSLIT'),
                    ref_keys = ref_keys,
                    stringsAsFactors = FALSE)
  out[[grp]] <- res
}
adat <- do.call(rbind, out)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b|\\?', adat$taxon), ]
adat$n <- 1
adat$source_mass <- 'Tsuboi_etal_2018'
TSU <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'order', 'family', 'ref_keys')]
save(TSU, file = file.path(wd_rdata, 'BodyMass_Tsuboi_etal_2018.Rdata'))
