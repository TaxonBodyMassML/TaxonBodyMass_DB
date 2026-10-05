# Wisnionski, Haase, Dy, Hudson & Gillooly (2026) Ecol. Evol. 16:e74243, Dryad
# 10.5061/dryad.79cnp5jbt: VertData_{reptiles,birds,mammals}.csv (the three
# sheets of VertData.xlsx), one row per species with the body mass (g), maximum
# lifespan, mass-specific metabolic rate and plasma corticosterone data the
# authors compiled from the literature (48 reptiles, 82 birds, 34 mammals).
# The data files carry no reference column; Table S1 of the supplement
# (ece374243-sup-0001-supinfo.pdf, parsed by parse_wisnionski_supmat.py into
# TableS1_parsed.csv and references.csv) prints the same rows with a bracketed
# reference number after every body mass. The mass source is mostly a
# compilation: AnAge [4] on 41 kept rows, Dunning (1993) [56] on 25, Bokony et
# al. (2009) [68] on 27, Gillooly et al. (2017) [7] on 4, White et al. (2006)
# [40] on 2; the rest cite the corticosterone study itself (README.md,
# Provenance).
files <- c(reptiles = 'Reptilia', birds = 'Aves', mammals = 'Mammalia')
adat <- do.call(rbind, lapply(names(files), function(g) {
  d <- read.csv(file.path(wd_source, sprintf('VertData_%s.csv', g)), header = TRUE,
                check.names = FALSE, stringsAsFactors = FALSE, fileEncoding = 'UTF-8-BOM',
                na.strings = c('', 'NA'))
  names(d) <- trimws(names(d))                 # 'Species Name ', 'Stressor ' carry trailing blanks
  mass_col <- grep('^Body Mass', names(d), value = TRUE)   # 'Body Mass' (g); 'Body Mass_g' in the reptile file
  stopifnot(length(mass_col) == 1)
  data.frame(taxon_csv = trimws(d[['Species Name']]),
             mass_g    = suppressWarnings(as.numeric(d[[mass_col]])),
             stage     = d[['Life Stage']],
             class     = files[[g]],
             stringsAsFactors = FALSE)
}))
# Table S1 prints 24 species under a name other than the data file's (current
# names for the data file's older synonyms, abbreviated subspecies, two
# misspellings corrected) and merges the data file's two black-browed albatross
# rows into one; the map below is from the data file's name to Table S1's.
csv_to_pdf <- c(
  'Egernia whitii'                 = 'Liopholis whitii',
  'Thamnophis elegans vagrans'     = 'Thamnophis errans',       # Table S1's name; the study [47] is of T. elegans
  'Pituophis catenifer affinis'    = 'Pituophis c. affinis',
  'Thamnophis sirtalis parietalis' = 'Thamnophis s. parietalis',
  'Canis lupus dingo'              = 'Canis l. dingo',
  'Mustela putorius furo'          = 'Mustela p. furo',
  'Cnemidophorus sexlineatus'      = 'Aspidoscelis sexlineatus',
  'Cnemidophorus uniparens'        = 'Aspidoscelis uniparens',
  'Crotalus helleri'               = 'Crotalus viridis',
  'Lacerta vivipara'               = 'Zootoca vivipara',
  'Podarcis sicula'                = 'Podarcis siculus',
  'Carduelis flammea'              = 'Acanthis flammea',
  'Diomedea melanophris'           = 'Thalassarche melanophris',
  'Thallasarche melanophris'       = 'Thalassarche melanophris',
  'Gallus domesticus'              = 'Gallus gallus',
  'Grus canadensis'                = 'Antigone canadensis',
  'Melozone aberti'                = 'Kieneria aberti',
  'Parus caeruleus'                = 'Cyanistes caeruleus',
  'Peucaea carpalis'               = 'Aimophila carpalis',
  'Rhynchophanes mccownii'         = 'Calcarius mccownii',
  'Spizella arborea'               = 'Spizelloides arborea',
  'Thryesphilus rufalbus'          = 'Thryophilus rufalbus',
  'Macropus rufogriseus'           = 'Notamacropus rufogriseus')
tab <- read.csv(file.path(wd_source, 'TableS1_parsed.csv'), stringsAsFactors = FALSE,
                colClasses = 'character', encoding = 'UTF-8')
adat$taxon_pdf <- ifelse(adat$taxon_csv %in% names(csv_to_pdf), csv_to_pdf[adat$taxon_csv], adat$taxon_csv)
m <- match(adat$taxon_pdf, tab$species_pdf)
if (anyNA(m))
  stop('Wisnionski_2026: not in Table S1: ', paste(adat$taxon_csv[is.na(m)], collapse = ', '))
# The body mass of every row must be the one Table S1 prints for the species
# (Table S1 rounds to the gram), otherwise the reference number does not belong
# to the value.
pdf_mass <- suppressWarnings(as.numeric(tab$mass_g[m]))
off <- !is.na(adat$mass_g) & !is.na(pdf_mass) & abs(adat$mass_g - pdf_mass) > pmax(0.5, 0.005 * pdf_mass)
if (any(off) || any(is.na(adat$mass_g) != is.na(pdf_mass)))
  stop('Wisnionski_2026: body mass disagrees with Table S1 for ',
       paste(adat$taxon_csv[off | is.na(adat$mass_g) != is.na(pdf_mass)], collapse = ', '))
# The per-row mass reference number(s) of Table S1 are kept as `ref_keys` for
# the primary-source attribution of issue #1 (SplitRefKeys(),
# R/library/citations/parse_reflists.r), resolved in references.csv. Table S1
# cites '[56,102]' for its single black-browed albatross value, the mean of the
# data file's two rows: 3564 g is Dunning's (1993) value (McCoy_2008 recovers
# the same number from Dunning 1993) and 3540 g is Angelier et al. (2007) [102].
adat$ref_keys <- SplitRefKeys(tab$mass_ref_keys[m], ';')
adat$ref_keys[adat$taxon_csv == 'Diomedea melanophris']     <- '56'
adat$ref_keys[adat$taxon_csv == 'Thallasarche melanophris'] <- '102'
# Two rows (Egernia whitii, Phrynocephalus vlangalii) report no body mass.
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# Five rows are of juveniles or young of the year (Life Stage 'Juvenile',
# '3 months', '20 months'; the '^' mark of Table S1) whose mass is the mass of
# the animals of the corticosterone study, so they are not adult records
# (README.md). The one 'Mix' row (Sturnus vulgaris) keeps Dunning's adult mass.
# Subspecies and domestic forms (Pituophis catenifer affinis, Thamnophis elegans
# vagrans, Thamnophis sirtalis parietalis, Canis lupus dingo, Mustela putorius
# furo) are truncated to the binomial.
adat$taxon <- sub('^(\\S+ \\S+) \\S+$', '\\1', adat$taxon_csv)
nonadult <- adat$stage %in% 'Juvenile' | grepl('months', adat$stage, fixed = TRUE)
stopifnot(identical(nonadult, tab$juvenile[match(adat$taxon_pdf, tab$species_pdf)] == 'TRUE'))
adat <- DropImputed(adat, nonadult, 'Wisnionski_2026',
                    'juvenile or young-of-year record (Life Stage; Table S1 ^ mark): not an adult mass')
adat$n <- 1
adat$source_mass <- 'Wisnionski_2026'
if (anyNA(adat$ref_keys)) warning('Wisnionski_2026: ', sum(is.na(adat$ref_keys)), ' record(s) without a mass reference')
WIS <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  class = adat$class, stringsAsFactors = FALSE)
save(WIS, file = file.path(wd_rdata, 'BodyMass_Wisnionski_2026.Rdata'))
