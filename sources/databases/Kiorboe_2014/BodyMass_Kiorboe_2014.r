# Kiørboe & Hirst (2014) American Naturalist 183:E118-E130. Compilation of body
# masses (as carbon) with respiration, growth and feeding rates of marine pelagic
# heterotrophs, PANGAEA datasets 819850 (respiration), 819855 (growth) and 819856
# (feeding), CC BY 3.0, downloaded 2026-09-27 as tab-delimited text.
# 'Biom C/ind [µg/#]' is carbon mass per individual; converted to wet grams with the
# group-specific carbon:wet-mass ratios in R/library/mass_conversion.r. Groups come
# from taxon_groups.csv (WoRMS classification of the AphiaIDs given in the files,
# plus manual assignment of the freshwater/soil protists that lack an AphiaID).
# Names flagged uncertain ('?') or identified only to genus are dropped.
ReadPangaea <- function(f) {
  lines <- readLines(file.path(wd_source, f), encoding = 'UTF-8')
  start <- grep('^\\*/', lines)[1] + 1
  d <- read.delim(text = lines[start:length(lines)], sep = '\t', header = TRUE,
                  quote = '', check.names = FALSE, stringsAsFactors = FALSE)
  mass_col <- grep('^Biom C/ind', names(d), value = TRUE)[1]
  data.frame(taxon = trimws(d$Taxa),
             mass_g = suppressWarnings(as.numeric(d[[mass_col]])) * 1e-6,  # µg C -> g C
             stringsAsFactors = FALSE)
}
adat <- do.call(rbind, lapply(c('PANGAEA_819850_respiration.txt',
                                'PANGAEA_819855_growth.txt',
                                'PANGAEA_819856_feeding.txt'), ReadPangaea))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# Join to the group table on the raw PANGAEA name (which may carry a stage/sex
# suffix such as 'Acartia grani, nauplii' or 'Calanus finmarchicus CV').
grp <- read.csv(file.path(wd_source, 'taxon_groups.csv'), stringsAsFactors = FALSE)
grp <- grp[, c('taxon', 'worms_name', 'mass_group', 'kingdom', 'phylum', 'class', 'order', 'family')]
adat <- merge(adat, grp, by = 'taxon', all.x = TRUE)
if (any(is.na(adat$mass_group) | adat$mass_group == ''))
  stop('Kiorboe_2014: taxa without mass_group: ',
       paste(unique(adat$taxon[is.na(adat$mass_group) | adat$mass_group == '']), collapse = '; '))
adat <- adat[!(adat$mass_group %in% 'DROP'), ]   # larval-stage labels and abbreviated names
# Fish records in this compilation are larval stages (body carbon of micrograms):
# exclude them rather than attribute larval masses to adult species.
adat <- adat[adat$mass_group != 'fish', ]
# Drop juvenile stages (nauplii, copepodites 'C1'-'C6'/'CV', larvae); keep adults,
# sexes and salp aggregate/solitary forms.
juv <- grepl('nauplii?|copepodite|juvenile|larva|zoea|megalopa|mysis', adat$taxon, ignore.case = TRUE) |
       grepl(' (C[1-6]|C?[IV]+|N[1-6])$', adat$taxon)
adat <- adat[!juv, ]
# Clean taxon: prefer the WoRMS-resolved name, else strip the suffix.
clean <- sub(',.*$', '', adat$taxon)
clean <- sub(' (C[1-6]|C?[IV]+|N[1-6])$', '', clean)
clean <- sub('^Sytrombidium ', 'Strombidium ', clean)                 # typo in source
wn <- sub(' \\(.*$', '', adat$worms_name)                            # drop parenthetical notes
adat$taxon <- ifelse(!is.na(wn) & wn != '' & grepl(' ', wn), wn, clean)
adat <- adat[!grepl('\\?', adat$taxon) & !grepl('\\b(sp|spp|cf|aff|indet)\\b\\.?', adat$taxon), ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+', adat$taxon), ]   # binomials only
for (col in c('kingdom', 'phylum', 'class', 'order', 'family'))
  adat[[col]] <- ifelse(adat[[col]] == '', NA_character_, adat[[col]])
adat$mass_g <- ToWetMass(adat$mass_g, from = 'carbon', group = adat$mass_group)
adat$n <- 1
adat$source_mass <- 'Kiorboe_2014'
KIO <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'kingdom', 'phylum', 'class',
                'order', 'family')]
save(KIO, file = file.path(wd_rdata, 'BodyMass_Kiorboe_2014.Rdata'))
