adat <- read.table(file.path(wd_source, 'avian_ssd_jan07.txt'), sep = '\t', header = TRUE)
adat <- adat[, c('Species_name', 'M_mass', 'F_mass', 'unsexed_mass')]
colnames(adat)[1] <- 'taxon'
adat[which(adat == '-999', arr.ind = TRUE)] <- NA
adat$mass_g <- apply(adat[, -1], 1, mean, na.rm = TRUE)
adat <- adat[, c('taxon', 'mass_g')]
adat <- adat[!is.nan(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = mean(mass_g), n = length(mass_g))
adat$source_mass <- 'Lislevand_etal_2007'
LI <- adat
save(LI, file = file.path(wd_rdata, 'BodyMass_Lislevand_etal_2007.Rdata'))
