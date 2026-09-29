# Ikeda (2014) Marine Biology 161:2753-2766, Electronic Supplementary Material
# (227_2014_2540_MOESM1_ESM.pdf): tables S1-S3 list individual dry mass (DW, mg),
# carbon and nitrogen for the metazooplankton specimens used in the respiration,
# ammonia-excretion and O:N analyses; table S4 maps data codes to species and
# stage/sex. The PDF tables were parsed with parse_ikeda_esm.py (pdftotext -layout,
# column-position splitting) into ikeda2014_esm_parsed.csv, which is read here.
# Only adult records are used: copepodite stage C6 (adult) females/males, adults
# (A), gravid females (FG), F/M, or unstaged records; C1-C5 copepodites and
# juveniles (J) are dropped, as are genus-level names. Dry mass is converted to
# wet mass with group-specific factors from R/library/mass_conversion.r.
adat <- read.csv(file.path(wd_source, 'ikeda2014_esm_parsed.csv'), stringsAsFactors = FALSE)
adat$stage <- trimws(adat$stage)
juv <- grepl('^C[1-5]|\\bC[1-5]\\b|\\bJ\\b|juv|larva|nauplii|zoea|furcilia|calyptopis', adat$stage, ignore.case = TRUE) |
       grepl('\\bC[1-5]', adat$species)   # stage embedded in the species string (e.g. 'Calanoides acutus C4,5')
adat <- adat[!juv, ]
adat$taxon <- trimws(adat$species)
adat$taxon <- sub('^([A-Z][a-z]+ [a-z]+).*$', '\\1', adat$taxon)          # drop 'f. sulcata' etc.
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon), ]
adat$mass_g <- suppressWarnings(as.numeric(adat$dw_mg)) / 1000           # mg dry -> g dry
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
group_map <- c(COPE = 'crustacean_zooplankton', EUPH = 'crustacean_zooplankton',
               AMPH = 'crustacean_zooplankton', DECA = 'crustacean_zooplankton',
               MYSI = 'crustacean_zooplankton', OSTR = 'crustacean_zooplankton',
               CNID = 'gelatinous_zooplankton', CTEN = 'gelatinous_zooplankton',
               SIPH = 'gelatinous_zooplankton', SALP = 'gelatinous_zooplankton',
               TUNI = 'gelatinous_zooplankton', DOLI = 'gelatinous_zooplankton',
               APPE = 'gelatinous_zooplankton', PYRO = 'gelatinous_zooplankton',
               THAL = 'gelatinous_zooplankton',
               CHAE = 'invertebrate', MOLL = 'invertebrate', PTER = 'invertebrate',
               POLY = 'invertebrate', HETE = 'invertebrate')
unknown <- setdiff(unique(adat$taxon_group), names(group_map))
if (length(unknown) > 0) stop('Ikeda_2014: unmapped taxon group(s): ', paste(unknown, collapse = ', '))
mass_group <- unname(group_map[adat$taxon_group])
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = mass_group)
adat$n <- 1
adat$source_mass <- 'Ikeda_2014'
IKE <- adat[, c('taxon', 'mass_g', 'n', 'source_mass')]
save(IKE, file = file.path(wd_rdata, 'BodyMass_Ikeda_2014.Rdata'))
