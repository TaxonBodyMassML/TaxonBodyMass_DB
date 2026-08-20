adat <- read.csv(file.path(wd_source, 'report-201802270108.csv'), header = TRUE)
adat <- adat[, c(1:5, 8:9)]
adat[which(adat == 0, arr.ind = TRUE)] <- NA
nNAdat <- !is.na(adat)
dat1 <- adat[which(nNAdat[, 2] == TRUE), c(1, 2)]
colnames(dat1) <- c('taxon', 'mass_g')
dat2 <- adat[which(nNAdat[, 2] == FALSE & nNAdat[, 3] == TRUE), c(1, 3)]
colnames(dat2) <- c('taxon', 'mass_g')
adat <- rbind(dat1, dat2)
adat <- FixNames(adat)
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Quaardvark'
AA <- adat
save(AA, file = file.path(wd_rdata, 'BodyMass_Quaardvark.Rdata'))
