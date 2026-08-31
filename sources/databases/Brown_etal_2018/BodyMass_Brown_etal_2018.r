dat1 <- read.csv(file.path(wd_source, '41559_2017_430_MOESM3_ESM.csv'))
dat1$taxon <- paste(dat1$Genus, dat1$Species)
dat1 <- dat1[, c('taxon', 'Dry.mass.g')]
colnames(dat1) <- c('taxon', 'mass_g')
dat1$n <- 1

dat2 <- read.csv(file.path(wd_source, '41559_2017_430_MOESM2_ESM.csv'))
dat2$taxon <- gsub('.*: (.*)', '\\1', dat2$Taxon2)
dat2 <- dat2[, c('taxon', 'Body.mass.g')]
colnames(dat2) <- c('taxon', 'mass_g')
dat2$n <- 1

adat <- rbind(dat1, dat2)
adat <- adat[!is.na(adat$mass_g), ]
adat$source_mass <- 'Brown_etal_2018'
BR <- adat
save(BR, file = file.path(wd_rdata, 'BodyMass_Brown_etal_2018.Rdata'))
