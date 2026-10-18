adat <- read.csv(file.path(wd_source, 'FieldMR_SciDataPub.csv'), header = TRUE,
                 fileEncoding = 'UTF-8-BOM')
taxon_tax <- adat[, c('SpeciesAcceptedName', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$SpeciesAcceptedName), ]
taxon_tax$kingdom <- iconv(as.character(taxon_tax$Kingdom), to = 'ASCII//TRANSLIT')
taxon_tax$phylum  <- iconv(as.character(taxon_tax$Phylum),  to = 'ASCII//TRANSLIT')
taxon_tax$class   <- iconv(as.character(taxon_tax$Class),   to = 'ASCII//TRANSLIT')
taxon_tax$order   <- iconv(as.character(taxon_tax$Order),   to = 'ASCII//TRANSLIT')
taxon_tax$family  <- iconv(as.character(taxon_tax$Family),  to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'kingdom', 'phylum', 'class', 'order', 'family')]
# Reference key lookup: Reference citation string -> key (references.csv)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character',
                 encoding = 'UTF-8', fileEncoding = 'UTF-8')
  setNames(rl$key, rl$citation)
} else character(0)
adat <- adat[, c('SpeciesAcceptedName', 'Mass_g', 'Reference')]
colnames(adat)[1:2] <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
ref_raw <- trimws(as.character(adat$Reference))
ref_keys <- if (length(ref_lookup) > 0) ref_lookup[ref_raw] else rep(NA_character_, nrow(adat))
ref_keys[is.na(ref_raw) | ref_raw == ''] <- NA_character_
adat$ref_keys <- ref_keys
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat$n <- 1
adat$source_mass <- 'Castro_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
CA <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'kingdom', 'phylum', 'class', 'order',
               'family', 'ref_keys')]
save(CA, file = file.path(wd_rdata, 'BodyMass_Castro_2025.Rdata'))
