# ReptTraits v1.2 (Oskyrko, Mi, Meiri & Du 2024, Scientific Data 11:243), the
# trait table 'ReptTraits dataset v1-2_data.csv' (one row per species, 12,060
# reptiles) and its twin 'ReptTraits dataset v1-2_sources.csv' (the same cells
# holding the citation of each value). Trait T20, 'Maximum body mass (g)', is
# the only mass column (hatchling mass, T26, is not an adult mass). The column
# is a compilation of maxima, and for the squamates it is overwhelmingly the
# mass Feldman et al. (2016) and Meiri (2018) computed from the maximum
# snout-vent length with clade-specific allometric equations, re-cited to the
# works that supplied the length (README.md, Data and Record set): such values
# are estimates, not measurements, and leave through DropImputed() in three
# steps, by citation, by value and by the species' presence in those two
# sources (owner decision 2026-10-04). What remains is kept with the citation
# of every row as ref_keys (issue #1).
dat  <- read.csv(file.path(wd_source, 'ReptTraits dataset v1-2_data.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                 fileEncoding = 'UTF-8-BOM')
srcs <- read.csv(file.path(wd_source, 'ReptTraits dataset v1-2_sources.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                 fileEncoding = 'UTF-8-BOM')
# The one species the two files spell differently (the data file drops the
# hyphen of Phelsuma v-nigra); every other name matches one to one.
srcs$Species[srcs$Species == 'Phelsuma v-nigra'] <- 'Phelsuma vnigra'
stopifnot(setequal(dat$Species, srcs$Species), !anyDuplicated(dat$Species))
mass_col <- 'Maximum body mass (g)'
adat <- data.frame(taxon    = trimws(dat$Species),
                   mass_g   = suppressWarnings(as.numeric(dat[[mass_col]])),
                   order    = dat$Order,
                   family   = dat$Family,
                   mass_src = srcs[[mass_col]][match(dat$Species, srcs$Species)],
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
if (anyNA(adat$mass_src)) stop('Oskyrko_2024: ', sum(is.na(adat$mass_src)), ' mass value(s) without a source cell')

# (1) By citation. Slavenko et al. (2019) and Zimin et al. (2022) are
# Meiri-lab macroecological analyses whose squamate body masses were estimated
# from maximum SVL with the Feldman et al. (2016) equations; Meiri et al.
# (2021) state that for reptiles 'we converted lengths to masses using the
# allometric equations published by Feldman et al.' and that their masses are
# maxima (the turtle and crocodilian rows); Feldman & Meiri (2013), Feldman et
# al. (2015) and Feldman (2015, the thesis behind Feldman et al. 2016) are the
# equations' own papers. Of the 9,441 squamate rows citing the first two or
# the Feldman works, 93% sit within 0.0105 log10 of the value of
# Feldman_etal_2016 or Meiri_2018 for the species (README.md); the rest are
# species those sources lack, estimated the same way from newer lengths.
allometric <- c('Slavenko et al. 2019', 'Zimin et al. 2022', 'Meiri et al. 2021',
                'Feldman & Meiri 2013', 'Feldman et al. 2015', 'Feldman 2015')
cites <- lapply(strsplit(adat$mass_src, ',', fixed = TRUE), trimws)
cites_allometric <- vapply(cites, function(k) any(k %in% allometric), logical(1))
adat <- DropImputed(adat, cites_allometric, 'Oskyrko_2024',
                    'body mass cited to a length-mass allometry compilation (Slavenko et al. 2019, Zimin et al. 2022, Meiri et al. 2021, Feldman & Meiri 2013, Feldman et al. 2015, Feldman 2015): estimated from maximum length')

# (2) By value. The remaining rows cite field guides, longevity compilations
# and primary papers, but most of their values are the Feldman_etal_2016 or
# Meiri_2018 estimate of the species to the last digit: the citation is the
# source of the length, not of a weighed animal. The two source tables are
# read as those parsers read them (Feldman's mass column; Meiri's maximum SVL
# through the intercept and slope of each row), and a value identical to
# either (1e-6 log10) or within the re-rounding tolerance of the dependency
# registry (0.0105 log10, the Meiri_2018 -> Feldman_etal_2016 edge) is the same
# estimate under another citation.
fe <- read.csv(file.path(dirname(wd_source), 'Feldman_etal_2016',
                         'Appendix S1 - Lepidosaur body sizes.csv'), header = TRUE)
fe_mass <- setNames(suppressWarnings(as.numeric(fe$mass..g.)), trimws(fe$binomial))
me <- read.csv(file.path(dirname(wd_source), 'Meiri_2018', 'geb12773-sup-0001-appendixs1.csv'))
me_mass <- round(10^(as.numeric(me$intercept) + as.numeric(me$slope) *
                     log10(suppressWarnings(as.numeric(me$maximum.SVL)))), 3)
me_mass <- setNames(me_mass, trimws(gsub('.*: (.*)', '\\1', me$Binomial)))
LogDist <- function(ref) {
  v <- unname(ref[adat$taxon])
  d <- abs(log10(adat$mass_g) - log10(v))
  ifelse(is.na(d), Inf, d)
}
dist_est  <- pmin(LogDist(fe_mass), LogDist(me_mass))
adat <- DropImputed(adat, dist_est < 1e-6, 'Oskyrko_2024',
                    'value identical to the Feldman et al. 2016 / Meiri 2018 SVL-derived mass of the species: the same allometric estimate under another citation')
dist_est  <- pmin(LogDist(fe_mass), LogDist(me_mass))
adat <- DropImputed(adat, dist_est < 0.0105, 'Oskyrko_2024',
                    'value within 0.0105 log10 of the Feldman et al. 2016 / Meiri 2018 SVL-derived mass of the species: the re-rounded allometric estimate')

# (3) By presence (owner decision 2026-10-04, option A2 of issue #77): a kept
# row whose species has a Feldman_etal_2016 or Meiri_2018 value at
# accepted-name level is dropped whatever its value (the species' maximum is
# already an SVL estimate in the database, and the remaining differences are
# other lengths through the same equations). The accepted name is matched
# three ways, since the parser cannot run the enrichment: the raw binomial;
# the same genus with the epithet's gender ending removed (bilineatus /
# bilineata, lorentzii / lorentzi, calligaster / calligastra); and the genus
# transfers the enrichment of the first run (2026-10-04) resolved between the
# two files, listed here (ReptTraits name = the Feldman / Meiri name).
fm_names <- unique(c(names(fe_mass)[!is.na(fe_mass)], names(me_mass)[!is.na(me_mass)]))
StemKey <- function(x) {
  p <- strsplit(x, ' ', fixed = TRUE)
  paste(vapply(p, `[`, '', 1), sub('(ii|i|us|um|a|is|e|er|ra)$', '', vapply(p, `[`, '', 2)))
}
fm_synonyms <- c('Elaphe taeniura'            = 'Orthriophis taeniurus',
                 'Leiopython fredparkeri'     = 'Bothrochilus fredparkeri',
                 'Letheobia zenkeri'          = 'Typhlops zenkeri',
                 'Mastigodryas pleii'         = 'Mastigodryas pleei',
                 'Metlapilcoatlus nummifer'   = 'Atropoides nummifer',
                 'Phrynonax sexcarinatus'     = 'Pseustes sexcarinatus',
                 'Rhadinella stadelmani'      = 'Rhadinaea stadelmani',
                 'Rhinotyphlops leucocephalus' = 'Madatyphlops leucocephalus',
                 'Sonora straminea'           = 'Chilomeniscus stramineus',
                 'Suta dwyeri'                = 'Parasuta dwyeri',
                 'Suta spectabilis'           = 'Parasuta spectabilis')
in_fm <- adat$taxon %in% fm_names |
  StemKey(adat$taxon) %in% StemKey(fm_names) |
  unname(fm_synonyms[adat$taxon]) %in% fm_names
adat <- DropImputed(adat, in_fm, 'Oskyrko_2024',
                    'species present in Feldman et al. 2016 / Meiri 2018 at accepted-name level (raw name, gender ending or listed synonym): its maximum is already an SVL estimate in the database (owner decision 2026-10-04, A2)')

adat$n <- 1
adat$source_mass <- 'Oskyrko_2024'
adat$class <- 'Reptilia'
for (col in c('order', 'family'))
  adat[[col]] <- iconv(as.character(adat[[col]]), to = 'ASCII//TRANSLIT')
# The citation cell of every kept row (author-year keys, comma-separated,
# several per row allowed) is kept as `ref_keys` for the primary-source
# attribution of issue #1 (SplitRefKeys(), R/library/citations/parse_reflists.r);
# the keys are resolved in references.csv (key, citation), transcribed from
# 'ReptTraits dataset v1-2_references.csv'.
adat$ref_keys <- SplitRefKeys(adat$mass_src, ',')
if (anyNA(adat$ref_keys)) warning('Oskyrko_2024: ', sum(is.na(adat$ref_keys)), ' record(s) without a citation')
OSK <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family', 'ref_keys')]
rownames(OSK) <- NULL
save(OSK, file = file.path(wd_rdata, 'BodyMass_Oskyrko_2024.Rdata'))
