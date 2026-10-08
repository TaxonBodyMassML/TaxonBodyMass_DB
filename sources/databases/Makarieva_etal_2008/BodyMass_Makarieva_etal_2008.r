# Makarieva et al. (2008) PNAS 105:16994, Supporting Information (pnas08SI.pdf,
# 212 pages; mirror http://www.bioticregulation.ru/common/pdf/pnas08/pnas08SI.pdf).
# The S*.csv tables are the dataset tables of the SI as transcribed in 2026-08:
# S1a prokaryotes (cell mass from linear dimensions), S2b protozoa (the per-species
# minima of Table S2a), S3 insects (Chown et al. 2007 Appendix S2 plus ten rows
# added by the authors, printed in green in the SI), S4 aquatic invertebrates,
# S5a amphibians and S5b reptiles (after White et al. 2006), S5c fishes (FishBase
# minima), S6a birds (McKechnie & Wolf 2004 pooled with V. Gavrilov's
# measurements of Table S6b), S6b Gavrilov's bird measurements, S7 cyanobacteria.
# Masses are wet masses in grams (mass_g; cell masses converted from pg).
#
# Provenance (issue #1, Stage 2): every record cites its source in a different
# way per table (the Source column of S1a, S4 and S7 with the cell-size source
# in brackets; the S2a row the S2b minimum comes from; the superscript numbers of
# S3; whole-table sources for S5a-c and the MW rows of S6a; the Gavrilov papers
# of S6b). parse_makarieva_si.py reads them from the SI PDF into record_refs.csv
# (one row per row of each table, in table order, with the species as a check)
# and the reference lists into references.csv; the keys are joined here by
# position and kept as `ref_keys` (SplitRefKeys()).
# S1a and S7 (owner item Makarieva_2008-2, 2026-10-08): a row whose Source
# cell names the respiration study and, in brackets, the cell-size source
# ('De Ley & Schell 1959 [BM, ...]' -> 'S1a:De Ley & Schell 1959; S1a:Holt
# 1984') keeps only the size source(s), since the database value is the mass
# the size source gives; record_refs.csv keeps both keys as the SI prints
# them (the Source column's key first, the bracket's after it), and the first
# key is dropped here on every row of those two tables that carries two or
# more. A row with one key (no citable size source) keeps it.
refs <- read.csv(file.path(wd_source, 'record_refs.csv'), stringsAsFactors = FALSE,
                 colClasses = 'character', na.strings = character(0), encoding = 'UTF-8')
SizeSourceOnly <- function(keys) {
  vapply(keys, function(s) {
    toks <- trimws(strsplit(s, ';', fixed = TRUE)[[1]])
    toks <- toks[nzchar(toks)]
    if (length(toks) >= 2) paste(toks[-1], collapse = '; ') else s
  }, character(1), USE.NAMES = FALSE)
}
KeysFor <- function(table, species) {
  r <- refs[refs$table == table, , drop = FALSE]
  r <- r[order(as.integer(r$row)), , drop = FALSE]
  if (nrow(r) != length(species) || !all(enc2utf8(r$species) == enc2utf8(as.character(species))))
    stop('Makarieva_2008: record_refs.csv does not match table ', table, ' row for row')
  keys <- if (table %in% c('S1a', 'S7')) SizeSourceOnly(r$ref_keys) else r$ref_keys
  SplitRefKeys(keys, ';')
}
adat1  <- read.csv(file.path(wd_source, 'S1a.csv'), header = TRUE)
adat2  <- read.csv(file.path(wd_source, 'S2b.csv'), header = TRUE)
adat3  <- read.csv(file.path(wd_source, 'S3.csv'),  header = TRUE)
tax_s3 <- adat3[, c('species', 'family', 'order')]
tax_s3$family <- iconv(as.character(tax_s3$family), to = 'ASCII//TRANSLIT')
tax_s3$order  <- iconv(as.character(tax_s3$order),  to = 'ASCII//TRANSLIT')
tax_s3$order[!is.na(suppressWarnings(as.numeric(tax_s3$order)))] <- NA_character_
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

adat1$ref_keys  <- KeysFor('S1a', adat1$valid_name)
adat2$ref_keys  <- KeysFor('S2b', adat2$species)
adat3$ref_keys  <- KeysFor('S3',  adat3$species)
adat4$ref_keys  <- KeysFor('S4',  adat4$Species)
adat5$ref_keys  <- KeysFor('S5a', adat5$Species)
adat6$ref_keys  <- KeysFor('S5b', adat6$Species)
adat7$ref_keys  <- KeysFor('S5c', adat7$Species)
adat8$ref_keys  <- KeysFor('S6a', adat8$Species)
adat9$ref_keys  <- KeysFor('S6b', adat9$Species)
adat10$ref_keys <- KeysFor('S7',  adat10$species)

adat1  <- adat1[,  c('valid_name', 'mass_g', 'ref_keys')]
adat2  <- adat2[,  c('species',    'mass_g', 'ref_keys')]
adat3  <- adat3[,  c('species',    'mass_g', 'ref_keys')]
adat4  <- adat4[,  c('Species',    'mass_g', 'ref_keys')]
adat5  <- adat5[,  c('Species',    'mass_g', 'ref_keys')]
adat6  <- adat6[,  c('Species',    'mass_g', 'ref_keys')]
adat7  <- adat7[,  c('Species',    'mass_g', 'ref_keys')]
adat8  <- adat8[,  c('Species',    'mass_g', 'ref_keys')]
adat9  <- adat9[,  c('Species',    'mass_g', 'ref_keys')]
adat10 <- adat10[, c('species',    'mass_g', 'ref_keys')]

colnames(adat1) <- colnames(adat2) <- colnames(adat3) <- colnames(adat4) <-
  colnames(adat5) <- colnames(adat6) <- colnames(adat7) <- colnames(adat8) <-
  colnames(adat9) <- colnames(adat10) <- c('taxon', 'mass_g', 'ref_keys')

adat <- rbind(adat1, adat2, adat3, adat4, adat5, adat6, adat7, adat8, adat9, adat10)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- subset(adat, taxon != 'Unknown_genus')
adat <- subset(adat, taxon != 'Unknown_species')
adat <- subset(adat, taxon != 'Unidentified')
adat$n <- 1
adat$source_mass <- 'Makarieva_2008'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
if (anyNA(adat$ref_keys)) warning('Makarieva_2008: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference key')
MA <- adat
save(MA, file = file.path(wd_rdata, 'BodyMass_Makarieva_2008.Rdata'))
