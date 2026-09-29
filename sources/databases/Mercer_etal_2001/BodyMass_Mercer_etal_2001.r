# Mercer, Chown & Marshall (2001) Antarctic Science 13:135-143: mean fresh body
# masses of Marion Island invertebrates (Tables I-III). The PDF is a poor OCR
# scan, so the adult rows were transcribed by hand from the page images into
# Mercer_2001_adult_fresh_mass_transcribed.csv (2026-09-29; page numbers given).
# Only adult (A, A/N, A?) rows identified to species are included; rows for
# genus-level taxa, nymphs, larvae, pupae and immatures are omitted. Subspecies
# are truncated to binomials. Masses are fresh mass in mg.
adat <- read.csv(file.path(wd_source, 'Mercer_2001_adult_fresh_mass_transcribed.csv'),
                 stringsAsFactors = FALSE)
adat <- data.frame(taxon  = adat$taxon,
                   mass_g = adat$fresh_mass_mean_mg / 1000,
                   class  = adat$class,
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$n <- 1
adat$source_mass <- 'Mercer_etal_2001'
MER <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class')]
save(MER, file = file.path(wd_rdata, 'BodyMass_Mercer_etal_2001.Rdata'))
