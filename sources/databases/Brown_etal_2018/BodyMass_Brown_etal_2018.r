# Brown, Hall & Sibly (2018) Nature Ecology & Evolution 2:262-268, Supplementary
# Information, SI Table 2 (41559_2017_430_MOESM2_ESM.csv): body mass and ash-free
# energy content of 74 taxa. 'Body mass g' is WET mass (Mus musculus 40 g, Passer
# domesticus 22 g) and is used as is; Taxon2 holds a common-name prefix and the
# scientific name after the colon.
# SI Table 1 (41559_2017_430_MOESM3_ESM.csv, natural mortality rates with body
# size as dry mass = wet mass / 4) is McCoy & Gillooly's (2008, Ecology Letters
# 11:710-716) Appendix S1 reproduced row for row and is no longer read here: it
# enters the database through the source McCoy_2008, parsed from the appendix
# itself, which carries the per-row reference code needed to decide the mass
# conversion (issue #7). The file is kept in this folder for reference only.
adat <- read.csv(file.path(wd_source, '41559_2017_430_MOESM2_ESM.csv'))
adat$taxon <- gsub('.*: (.*)', '\\1', adat$Taxon2)
adat <- adat[, c('taxon', 'Body.mass.g')]   # wet mass, no conversion
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$n <- 1
adat$source_mass <- 'Brown_etal_2018'
BR <- adat
save(BR, file = file.path(wd_rdata, 'BodyMass_Brown_etal_2018.Rdata'))
