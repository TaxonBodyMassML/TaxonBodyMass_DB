# Mulder & Vonk (2011) Ecology 92:2071 (Ecological Archives E092-171),
# Traitsoilnematofauna.txt: 29,552 individual soil nematodes from 200 Dutch sites.
# Mass is the individual DRY body mass in ug, derived in the source from measured
# length and width with the volumetric function of Andrassy (1956) and a dry:wet
# ratio of 0.20 (Petersen & Luxton 1982). Wet mass is recovered with that same
# ratio (dry / 0.20). Only adults (Lifestage female or male) identified to species
# (binomial Taxonomy) are used; genus- and family-level records and the Dauerlarvae
# morphon are dropped. Individual records are averaged within species by RunMe Pass 1.
adat <- read.delim(file.path(wd_source, 'Traitsoilnematofauna.txt'), header = TRUE, sep = '\t',
                   check.names = FALSE, stringsAsFactors = FALSE,
                   na.strings = c('', 'NA'), fileEncoding = 'latin1', quote = '')
adat <- adat[adat$Lifestage %in% c('female', 'male'), ]
adat <- data.frame(taxon  = trimws(adat$Taxonomy),
                   mass_g = suppressWarnings(as.numeric(adat$Mass)) * 1e-6 / 0.20,   # ug dry -> g wet
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat$phylum <- 'Nematoda'
adat$n <- 1
adat$source_mass <- 'Mulder_2011'
MUD <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum')]
save(MUD, file = file.path(wd_rdata, 'BodyMass_Mulder_2011.Rdata'))
