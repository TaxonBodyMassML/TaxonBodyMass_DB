# EltonTraits 1.0 (Wilman et al. 2014, Ecological Archives E095-178): the bird
# half (BirdFuncDat.txt, 9,993 species) and the mammal half (MamFuncDat.txt,
# 5,400 species; parsed since #65) enter under the one label 'Wilman_etal_2014'.
# Both halves give one body mass per species (`BodyMass-Value`, g; n = 1), the
# source of the value (`BodyMass-Source`) and whether it is species-level
# (`BodyMass-SpecLevel` 1), a genus or family typical value (0) or, for
# mammals, a phylogenetically imputed value (2). The source column is kept as
# `ref_keys` for the primary-source attribution of issue #1 (SplitRefKeys(),
# R/library/citations/parse_reflists.r): for mammals the comma-separated
# `Ref_` codes of MamFuncDatSources.txt, for birds the source word itself
# ('Dunning08', 'HBW8' ... 'HBW15', 'PrimScale', 'Other'), both resolved in
# references.csv (README.md, Provenance).

# ---- birds -------------------------------------------------------------------
adat <- read.csv(file.path(wd_source, 'BirdFuncDat.txt'), header = TRUE, sep = '\t')
taxon_tax <- adat[, c('Scientific', 'IOCOrder', 'BLFamilyLatin')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Scientific), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$IOCOrder),     to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$BLFamilyLatin), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Scientific', 'BodyMass.Value', 'BodyMass.Source',
                 'BodyMass.SpecLevel', 'BodyMass.Comment')]
colnames(adat)[1:2] <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
# Genus/family typical values (BodyMass-Source 'GenAvg', BodyMass-SpecLevel 0)
# and values copied from another species are not species-specific; records
# flagged 'DataFromSplit' in Record-Comment are kept pending issue #5.
adat <- DropImputed(adat,
                    adat$BodyMass.Source == 'GenAvg' | adat$BodyMass.SpecLevel %in% 0 |
                      grepl('^Copied', adat$BodyMass.Comment),
                    'Wilman_etal_2014',
                    'GenAvg genus/family average or value copied from another species')
# 'PrimScale' values are EltonTraits' own estimates, scaled from a length
# through a family-level mass-length relationship fitted to congeners, not
# measured masses of the species (owner decision 2026-10-04, #65).
adat <- DropImputed(adat, adat$BodyMass.Source == 'PrimScale', 'Wilman_etal_2014',
                    'PrimScale: value scaled by EltonTraits from congeners (BodyMass-Source PrimScale)')
# The source word is the native key of the bird half (one word per row; the
# HBW volume number is part of the word).
adat$ref_keys <- SplitRefKeys(adat$BodyMass.Source, ',')
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
adat$class <- 'Aves'
birds <- adat

# ---- mammals (#65) -----------------------------------------------------------
mdat <- read.csv(file.path(wd_source, 'MamFuncDat.txt'), header = TRUE, sep = '\t',
                 stringsAsFactors = FALSE)
mdat <- mdat[, c('Scientific', 'BodyMass.Value', 'BodyMass.Source', 'BodyMass.SpecLevel',
                 'MSWFamilyLatin')]
colnames(mdat)[1:2] <- c('taxon', 'mass_g')
mdat$mass_g <- suppressWarnings(as.numeric(mdat$mass_g))
# three trailing rows of the file carry no name, source or mass
mdat <- mdat[!is.na(mdat$mass_g) & nzchar(trimws(mdat$taxon)), ]
# Genus Average / Family Average (Ref_2 and Ref_3 in BodyMass-Source,
# BodyMass-SpecLevel 0): a typical value of the genus or family, not of the
# species (scope rule of issue #8).
mdat <- DropImputed(mdat,
                    mdat$BodyMass.SpecLevel %in% 0 |
                      grepl('\\bRef_(2|3)\\b', mdat$BodyMass.Source, perl = TRUE),
                    'Wilman_etal_2014',
                    'Ref_2/Ref_3 Genus Average or Family Average (BodyMass-SpecLevel 0)')
# Ref_178 (BodyMass-SpecLevel 2): masses of data-deficient species imputed from
# phylogeny, range and environment (Jetz & Freckleton); not measured values.
mdat <- DropImputed(mdat,
                    mdat$BodyMass.SpecLevel %in% 2 |
                      grepl('\\bRef_178\\b', mdat$BodyMass.Source, perl = TRUE),
                    'Wilman_etal_2014',
                    'Ref_178 phylogenetically imputed value (BodyMass-SpecLevel 2)')
# The two Ref_165 rows (Fooden 1963, Lagothrix lugens 6.0 and L. cana 6.4) are
# kilograms entered as grams (woolly monkeys weigh 5-10 kg; the Ref_117 row of
# L. lagotricha reads 6,299.99 g): converted to grams for that reference only
# (owner decision 2026-10-04, #65; README.md).
ref165 <- grepl('\\bRef_165\\b', mdat$BodyMass.Source, perl = TRUE)
mdat$mass_g[ref165] <- mdat$mass_g[ref165] * 1000
# The Ref_ codes (comma-separated when a value rests on two works) are the
# native keys of MamFuncDatSources.txt (references.csv).
mdat$ref_keys <- SplitRefKeys(mdat$BodyMass.Source, ',')
mdat$family <- iconv(as.character(mdat$MSWFamilyLatin), to = 'ASCII//TRANSLIT')
mdat$family[!is.na(mdat$family) & !nzchar(mdat$family)] <- NA_character_
mdat$order <- NA_character_          # MamFuncDat.txt carries the MSW family only
mdat$class <- 'Mammalia'
mammals <- mdat[, c('taxon', 'mass_g', 'ref_keys', 'order', 'family', 'class')]

# ---- the frame ---------------------------------------------------------------
adat <- rbind(birds[, names(mammals)], mammals)
adat$n <- 1
adat$source_mass <- 'Wilman_etal_2014'
if (anyNA(adat$ref_keys))
  warning('Wilman_etal_2014: ', sum(is.na(adat$ref_keys)), ' record(s) without a BodyMass-Source key')
WI <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                 source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                 class = adat$class, order = adat$order, family = adat$family,
                 stringsAsFactors = FALSE)
save(WI, file = file.path(wd_rdata, 'BodyMass_Wilman_etal_2014.Rdata'))
