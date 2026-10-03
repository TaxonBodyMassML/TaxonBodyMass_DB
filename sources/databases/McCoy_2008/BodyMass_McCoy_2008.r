# McCoy & Gillooly (2008) Ecology Letters 11:710-716, Appendix S1 (Wiley
# supplementary file ELE_1190_sm_AppendixS1, 'Temperature, Body Mass, and
# Mortality data with Sources'): 2,117 rows of Group | Species | Dry mass (g) |
# Temp. C | *Mortality (y-1) | Ref. for birds (779), fish (234), invertebrates
# (198), mammals (524), multicellular plants (348) and phytoplankton (34), each
# row keyed to one or more of the 29 numbered data references listed at the end
# of the appendix. The appendix is parsed by parse_mcg_appendixS1.py (pdftotext
# -layout) into McCoy_2008_appendixS1.csv, which is read here; the publisher's
# file itself is not redistributed (README.md gives the download link).
# Brown, Hall & Sibly (2018, Nature Ecology & Evolution 2:262-268) Supplementary
# Table 1 reproduces this appendix row for row but without the reference column
# (2,021 of its 2,041 rows match the parse on group, genus, epithet, dry mass and
# temperature; the remainder are Brown's malformed, respelled or dropped rows, see
# README.md). The table therefore enters the database here, from the appendix,
# and no longer through Brown_etal_2018 (issue #7).
# Mass type: the appendix header states "Dry mass was calculated as 1/4*wet
# mass". The Bird, Mammal and Fish rows come from wet-mass compilations (Carey &
# Judge 2000, Dunning 1993, Ricklefs 1998 and Smith et al. 2003 for birds and
# mammals; Pauly's 1980 asymptotic weights and the other fish references), so wet
# mass is recovered exactly by inverting the source's own ratio,
# mass_g = dry_mass_g / 0.25 (Accipiter gentilis 256.1 g x 4 = 1,024.4 g, the mean
# of the male and female masses in Dunning; within this database the ratio of
# other sources to these values is 3.999 for birds and 4.000 for mammals; fish
# values are stock asymptotic weights, about 2x mean adult mass). No external
# conversion factor is involved, so no conversion CiteID is appended (precedent:
# Cohen_2014 and Mulder_2011, which likewise invert the source's own ratio).
# For the Invertebrate rows the unit depends on the reference (25 = Brey's data
# bank, probably kJ; 4 = Gillooly et al. 2001 laboratory zooplankton; 6 and 26 =
# Mauchline's krill and mysids; 15-24 and 27 = deep-sea growth papers) and a
# per-reference rule is pending; until it is decided every Invertebrate row is
# excluded below and the exclusion is logged with DropImputed(). Multicellular
# plant and Phytoplankton rows are autotrophs and are excluded at parse time
# (filter_autotrophs.r would remove them anyway).
# Names are taken as printed (species_printed) with minimal cleaning: a
# parenthetical synonym ('Sula (= Morus) bassanus'), single-letter tokens (the
# abbreviated middle names of 'Accipiter n. nisus' and 'Cygnus c. columbianus',
# the 'f' of 'Bovallia gigantea f', the broken 's' of 'Pseudopleuronecte s
# americanus'), and 'ssp.' and 'var. ...' suffixes are removed. Trinomials are
# truncated by the pipeline's FixFormatting and the appendix's misspellings and
# abbreviations ('Strongylocentr. droeb.', 'Acipsnser fulvescens', 'Aechmophorus
# accidentalis', 'Pseudopleuronecte americanus') by FixMisspellings, which
# already holds the rules written for the Brown_etal_2018 copy of the table.
# The Ref codes are carried per record as ref_keys ('1; 2' for the printed '1,2')
# and resolved in appendixS1_references.csv.
adat <- read.csv(file.path(wd_source, 'McCoy_2008_appendixS1.csv'), stringsAsFactors = FALSE,
                 colClasses = c(ref = 'character'), na.strings = character(0))
groups <- c('Bird', 'Fish', 'Invertebrate', 'Mammal', 'Multicellular plant', 'Phytoplankton')
unknown <- setdiff(unique(adat$group), groups)
if (length(unknown) > 0) stop('McCoy_2008: unexpected group(s): ', paste(unknown, collapse = ', '))
adat <- adat[adat$group %in% c('Bird', 'Fish', 'Invertebrate', 'Mammal'), ]   # autotrophs out

tx <- trimws(adat$species_printed)
tx <- gsub('\\s*\\([^)]*\\)', '', tx)                              # 'Sula (= Morus) bassanus'
tx <- gsub('(^|\\s)[A-Za-z]\\.?(?=\\s|$)', ' ', tx, perl = TRUE)    # 'n.', 'c.', 'f', broken 's'
tx <- sub('\\s+ssp\\.?$', '', tx)                                  # 'Colaptes auratus ssp.'
tx <- sub('\\s+var\\..*$', '', tx)                                 # 'Echinus acutus var. norvegicus'
adat$taxon <- trimws(gsub('\\s+', ' ', tx))

adat$dry_mass_g <- as.numeric(adat$dry_mass_g)
adat <- adat[!is.na(adat$dry_mass_g) & adat$dry_mass_g > 0, ]
vert <- adat$group %in% c('Bird', 'Fish', 'Mammal')
adat$mass_g <- NA_real_
adat$mass_g[vert] <- adat$dry_mass_g[vert] / 0.25   # invert the source's dry = wet / 4

# ---- Invertebrate rows: unit decision pending (issue #7) ---------------------
# The invertebrate masses come from references with different units (see the
# header comment); until the per-reference rule is decided, all Invertebrate
# rows are excluded here and logged to reports/imputed_rows.csv.
adat <- DropImputed(adat, adat$group == 'Invertebrate', 'McCoy_2008',
                    'invertebrate rows pending unit decision')
# -----------------------------------------------------------------------------

adat$n <- 1
adat$source_mass <- 'McCoy_2008'
adat$ref_keys <- ifelse(nzchar(trimws(adat$ref)), gsub(',', '; ', trimws(adat$ref)), NA_character_)
if (anyNA(adat$ref_keys)) warning('McCoy_2008: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference code')
MCG <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(MCG, file = file.path(wd_rdata, 'BodyMass_McCoy_2008.Rdata'))
