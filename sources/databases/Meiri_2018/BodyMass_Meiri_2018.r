adat <- read.csv(file.path(wd_source, 'geb12773-sup-0001-appendixs1.csv'))
adat$taxon <- gsub('.*: (.*)', '\\1', adat$Binomial)
adat <- FixNames(adat)

intercept <- as.numeric(adat$intercept)
slope     <- as.numeric(adat$slope)
suppressWarnings(
  maxSVL <- as.numeric(adat$maximum.SVL)
)
adat$mass_g <- round(10^(intercept + slope * log(maxSVL, 10)), 3)
adat <- adat[!is.na(adat$mass_g), ]
adat <- adat[, c('taxon', 'mass_g')]
adat <- ddply(adat, .(taxon), summarise,
              mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Meiri_2018'
ME <- adat
save(ME, file = file.path(wd_rdata, 'BodyMass_Meiri_2018.Rdata'))
