adat <- read.csv(file.path(wd_source, 'report-201802270108.csv'), header = TRUE)
adat <- adat[, c(1:5, 8:9)]
adat[which(adat == 0, arr.ind = TRUE)] <- NA
# Priority: adult-avg > adult-female > adult-male > female > male > general-avg
adat$mass_g <- NA_real_
for (ci in c(3, 4, 5, 6, 7, 2)) {
  fill <- is.na(adat$mass_g) & !is.na(adat[, ci])
  adat$mass_g[fill] <- adat[fill, ci]
}
adat <- adat[!is.na(adat$mass_g), c(1, ncol(adat))]
colnames(adat) <- c('taxon', 'mass_g')
adat$n <- 1
adat$source_mass <- 'Quaardvark'
AA <- adat
save(AA, file = file.path(wd_rdata, 'BodyMass_Quaardvark.Rdata'))
