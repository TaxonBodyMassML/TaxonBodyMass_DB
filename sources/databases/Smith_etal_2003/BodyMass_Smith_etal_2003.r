# MOM v10.2 (Smith et al. 2003, updated), read from MOM_v10.2_masses.csv, the
# minimal extract of the workbook's data sheet 'MOM v10.0' (all rows, the eight
# columns the pipeline uses, cell values verbatim; the workbook itself is no
# longer tracked, issue #4; build_references.r records how the extract was
# written). Its 'Status' column (extant / extinct / historical / introduction)
# is the filter: only extant (incl. introduced) species are kept so that Late
# Quaternary and historically extinct mammals do not enter the database.
adat <- read.csv(file.path(wd_source, 'MOM_v10.2_masses.csv'), stringsAsFactors = FALSE,
                 check.names = FALSE, na.strings = '', encoding = 'UTF-8')
names(adat) <- trimws(names(adat))
adat <- adat[!is.na(adat$Genus) & tolower(trimws(adat$Status)) %in% c('extant', 'introduction', 'introduced'), ]
names(adat)[names(adat) == 'Combined.Mass (g)'] <- 'Combined.Mass..g.'
taxon_tax <- adat[, c('Genus', 'Species', 'Order', 'FAMILY')]
taxon_tax$taxon  <- paste(taxon_tax$Genus, taxon_tax$Species, sep = '_')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$FAMILY), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), c('taxon', 'order', 'family')]
# Primary-source attribution (issue #1): 'Mass Reference' holds the numbers of
# the REFERENCES sheet, several joined by '_ ' ('60_ 129'), on 113 kept rows a
# text alias, a URL or a mix ('60_ walkers online'), and '-999' for none. The
# cell is split at '_' followed by a blank (the underscores inside URLs are not
# followed by one); integer tokens are keys as they stand; every text token,
# lower-cased with blank runs squeezed, is looked up in text_keys.csv, which
# maps it to the numbered entry it names (161, 174, 196, 73), to an alias key
# with its own row in references.csv (WalkersOnline, Goheen,
# web.vienna.sorex.asper, ...; built by build_references.r) or to no key (the
# fragments 'pers com.'); a text token the table lacks stops the run.
text_keys <- read.csv(file.path(wd_source, 'text_keys.csv'), stringsAsFactors = FALSE,
                      colClasses = 'character', na.strings = character(0), encoding = 'UTF-8')
raw_ref <- trimws(as.character(adat[['Mass Reference']]))
raw_ref[!is.na(raw_ref) & raw_ref == '-999'] <- NA
adat$ref_keys <- vapply(SplitRefKeys(raw_ref, '_[[:space:]]+'), function(k) {
  if (is.na(k)) return(NA_character_)
  toks <- trimws(strsplit(k, ';', fixed = TRUE)[[1]])
  # '60130' (6 rows) is '60_ 130' run together: read as 60 and 130 (owner decision 2026-10-05)
  if ('60130' %in% toks) toks <- unique(c(toks[toks != '60130'], '60', '130'))
  num  <- grepl('^[0-9]+$', toks)
  low  <- tolower(trimws(gsub('[[:space:]]+', ' ', toks[!num])))
  miss <- setdiff(low, text_keys$text)
  if (length(miss) > 0)
    stop('Smith_etal_2003: Mass Reference text not in text_keys.csv: ', paste(miss, collapse = ' | '))
  keys <- c(toks[num], text_keys$key[match(low, text_keys$text)])
  keys <- unique(keys[nzchar(keys)])
  if (length(keys) == 0) NA_character_ else paste(keys, collapse = '; ')
}, character(1), USE.NAMES = FALSE)
adat <- adat[, c('Genus', 'Species', 'Combined.Mass..g.', 'ref_keys')]
adat$taxon <- paste(adat$Genus, adat$Species, sep = '_')
colnames(adat)[3] <- 'mass_g'
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat <- adat[which(adat$mass_g != -999), ]
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Smith_2003'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
MM <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'order', 'family', 'ref_keys')]
save(MM, file = file.path(wd_rdata, 'BodyMass_Smith_2003.Rdata'))
