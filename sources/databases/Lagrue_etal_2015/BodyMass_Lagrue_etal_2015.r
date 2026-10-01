# Lagrue, Poulin & Cohen (2015) PNAS 112:1791-1796 (online December 2014), Dataset S1
# (pnas.1422475112.sd01.txt): metazoan community of four New Zealand lakes, one row per
# species x life stage x lake x season with 'Body mass (mg)'. Masses are wet masses:
# free-living animals were weighed (individually or as pooled conspecifics), fish
# individually per lake and season, and parasites were measured and their volume
# converted to mass at the density of water (SI Appendix, Methods). Only adults
# ('Ad') identified to species are used; larval insects (L) and larval parasite
# stages (Mc, Rd, Sp, C) are dropped, as are genus- and family-level names.
adat <- read.csv(file.path(wd_source, 'pnas.1422475112.sd01.txt'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                 fileEncoding = 'UTF-8-BOM')
adat$taxon <- gsub('\\s+', ' ', trimws(adat$Species))
adat <- adat[adat[['Life stage']] == 'Ad', ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff|unid)\\b', adat$taxon, ignore.case = TRUE), ]
adat <- adat[adat$taxon != 'Proboscis worm', ]                 # common-name entry (Nemertea)
adat$mass_g <- suppressWarnings(as.numeric(adat[['Body mass (mg)']])) / 1000
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
grp_map <- c(Fish = 'Chordata', Insect = 'Arthropoda', Crustacean = 'Arthropoda', Mite = 'Arthropoda',
             Mollusc = 'Mollusca', Annelid = 'Annelida', Trematode = 'Platyhelminthes',
             Cestode = 'Platyhelminthes', Nematoda = 'Nematoda', Acanthocephalan = 'Acanthocephala',
             Other = NA_character_)
adat$phylum <- unname(grp_map[adat[['Taxonomic group']]])
adat$n <- 1
adat$source_mass <- 'Lagrue_etal_2015'
LAG <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum')]
save(LAG, file = file.path(wd_rdata, 'BodyMass_Lagrue_etal_2015.Rdata'))
