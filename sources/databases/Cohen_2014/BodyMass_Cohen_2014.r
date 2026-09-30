# Cohen & Mulder (2014) Ecology 95:578 (Ecological Archives E095-051, SIZEWEB),
# 135FoodWebs.txt: soil invertebrate taxa (nematodes, mites, insects, myriapods,
# enchytraeids, earthworms) at 135 Dutch sites. Log(averageMass) is log10 of the
# average individual body mass in ug DRY mass, obtained in the source from body
# length via allometric equations under the assumption that dry mass is 20% of wet
# mass (metadata, Class II.B). Wet mass is therefore recovered with the source's
# own ratio (dry / 0.20), not with the generic factors of mass_conversion.r.
# Taxa are genera, families or morphons; only genus-level names are kept (family
# names and morphons such as 'Dauerlarvae stage' are dropped) and each distinct
# taxon/mass value is used once (values were held constant across webs).
adat <- read.delim(file.path(wd_source, '135FoodWebs.txt'), header = TRUE, sep = '\t',
                   check.names = FALSE, stringsAsFactors = FALSE,
                   na.strings = c('', 'NA'), fileEncoding = 'latin1')
names(adat) <- trimws(names(adat))
adat <- data.frame(taxon = trimws(adat[['Genus/Morphon']]),
                   logm  = suppressWarnings(as.numeric(adat[['Log(averageMass)']])),
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$logm), ]
adat <- adat[grepl('^[A-Z][a-z]+$', adat$taxon), ]                                   # single Latin word
adat <- adat[!grepl('(idae|inae|oidea|ida|ina|ea|morpha|iformes)$', adat$taxon), ]  # drop family/order names
adat <- adat[!duplicated(adat[, c('taxon', 'logm')]), ]
adat$mass_g <- (10^adat$logm) * 1e-6 / 0.20                                          # ug dry -> g wet
adat$n <- 1
adat$source_mass <- 'Cohen_2014'
COH <- adat[, c('taxon', 'mass_g', 'n', 'source_mass')]
save(COH, file = file.path(wd_rdata, 'BodyMass_Cohen_2014.Rdata'))
