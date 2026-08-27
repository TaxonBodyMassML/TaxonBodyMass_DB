adat1  <- read.csv(file.path(wd_source, 'S1a.csv'), header = TRUE)
adat2  <- read.csv(file.path(wd_source, 'S2b.csv'), header = TRUE)
adat3  <- read.csv(file.path(wd_source, 'S3.csv'),  header = TRUE)
tax_s3 <- adat3[, c('species', 'family', 'order')]
tax_s3$family <- iconv(as.character(tax_s3$family), to = 'ASCII//TRANSLIT')
tax_s3$order  <- iconv(as.character(tax_s3$order),  to = 'ASCII//TRANSLIT')
names(tax_s3)[1] <- 'taxon'
adat4  <- read.csv(file.path(wd_source, 'S4.csv'),  header = TRUE)
adat5  <- read.csv(file.path(wd_source, 'S5a.csv'), header = TRUE)
adat6  <- read.csv(file.path(wd_source, 'S5b.csv'), header = TRUE)
adat7  <- read.csv(file.path(wd_source, 'S5c.csv'), header = TRUE)
adat8  <- read.csv(file.path(wd_source, 'S6a.csv'), header = TRUE)
adat9  <- read.csv(file.path(wd_source, 'S6b.csv'), header = TRUE)
adat10 <- read.csv(file.path(wd_source, 'S7.csv'),  header = TRUE)
tax_s7 <- adat10[, c('species', 'order')]
tax_s7$order  <- iconv(as.character(tax_s7$order),  to = 'ASCII//TRANSLIT')
tax_s7$family <- NA_character_
names(tax_s7)[1] <- 'taxon'
taxon_tax <- rbind(tax_s3, tax_s7[, c('taxon', 'family', 'order')])
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]

adat1  <- adat1[,  c('valid_name', 'mass_g')]
adat2  <- adat2[,  c('species',    'mass_g')]
adat3  <- adat3[,  c('species',    'mass_g')]
adat4  <- adat4[,  c('Species',    'mass_g')]
adat5  <- adat5[,  c('Species',    'mass_g')]
adat6  <- adat6[,  c('Species',    'mass_g')]
adat7  <- adat7[,  c('Species',    'mass_g')]
adat8  <- adat8[,  c('Species',    'mass_g')]
adat9  <- adat9[,  c('Species',    'mass_g')]
adat10 <- adat10[, c('species',    'mass_g')]

colnames(adat1) <- colnames(adat2) <- colnames(adat3) <- colnames(adat4) <-
  colnames(adat5) <- colnames(adat6) <- colnames(adat7) <- colnames(adat8) <-
  colnames(adat9) <- colnames(adat10) <- c('taxon', 'mass_g')

adat <- rbind(adat1, adat2, adat3, adat4, adat5, adat6, adat7, adat8, adat9, adat10)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- subset(adat, taxon != 'Unknown_genus')
adat <- subset(adat, taxon != 'Unknown_species')
adat <- subset(adat, taxon != 'Unidentified')
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Makarieva_2008'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
MA <- adat
save(MA, file = file.path(wd_rdata, 'BodyMass_Makarieva_2008.Rdata'))
