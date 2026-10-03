# Brown, Hall & Sibly (2018) Nature Ecology & Evolution 2:262-268, Supplementary
# Information.
# SI Table 1 (41559_2017_430_MOESM3_ESM.csv) is the natural-mortality data set of
# McCoy & Gillooly (2008, Ecology Letters 11:710-716) with body size given as DRY
# mass. Brown et al. derived it from McCoy & Gillooly's wet masses with the fixed
# ratio stated in their Methods ("dry mass = (wet mass)/4"), so wet mass is
# recovered exactly by inverting that ratio: mass_g = Dry.mass.g / 0.25. Checks:
# Accipiter gentilis 256.1 g dry x 4 = 1,024.4 g, the mean of the male and female
# masses in Dunning (2008); within this database the ratio of other sources to the
# dry values is 3.999 for birds and 4.000 for mammals; the table maximum 3.75e7 g
# dry x 4 = 1.5e8 g, McCoy & Gillooly's largest value. No external conversion
# factor is involved, so no conversion CiteID is appended (precedent: Cohen_2014,
# Mulder_2011, which likewise invert the source's own ratio).
# SI Table 2 (41559_2017_430_MOESM2_ESM.csv) is the energy-content table; its
# 'Body mass g' is WET mass (Mus musculus 40 g, Passer domesticus 22 g) and is
# used as is.
dat1 <- read.csv(file.path(wd_source, '41559_2017_430_MOESM3_ESM.csv'))
dat1$taxon <- paste(dat1$Genus, dat1$Species)
dat1$mass_g <- dat1$Dry.mass.g / 0.25   # invert the source's dry = wet / 4
dat1 <- dat1[, c('taxon', 'mass_g')]
dat1$n <- 1

dat2 <- read.csv(file.path(wd_source, '41559_2017_430_MOESM2_ESM.csv'))
dat2$taxon <- gsub('.*: (.*)', '\\1', dat2$Taxon2)
dat2 <- dat2[, c('taxon', 'Body.mass.g')]   # wet mass, no conversion
colnames(dat2) <- c('taxon', 'mass_g')
dat2$n <- 1

adat <- rbind(dat1, dat2)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$source_mass <- 'Brown_etal_2018'
BR <- adat
save(BR, file = file.path(wd_rdata, 'BodyMass_Brown_etal_2018.Rdata'))
