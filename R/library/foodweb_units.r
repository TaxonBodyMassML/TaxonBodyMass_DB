# Per-web and per-study unit handling for the two food-web compilations,
# Brose_etal_2018 (GATEWAy) and Brose_2005 (issue #14; owner decisions of
# 2026-10-03 recorded in the issue).
#
# The decisions are data, not code: sources/databases/Brose_etal_2018/
# foodweb_units.csv (one row per GATEWAy food web) and sources/databases/
# DataRetriever/brose2005_units.csv (one row per Brose 2005 study) carry the
# column `action` (keep | drop | convert_dry) with `log_reason` for the drops,
# next to the evidence columns of the Phase A analysis. The taxon-level
# conversion groups (foodweb_units_groups.csv, brose2005_units_groups.csv:
# mass_group, whole, shell_group and a `convert` flag per taxon of the
# convert_dry webs) are written by the analysis scripts from the enrichment
# cache with MassGroupFromRanks() below. RunMe.r sources this file before the
# parse loop; the parsers call
#   StackGateway() / StackBrose2005()  stack consumer and resource rows with the
#                                       adult-or-unspecified life-stage filter
#   DropPlaceholders()                   drop group-level placeholder values
#   ApplyUnitActions()                   drop webs or convert dry mass per table
#   WebReferenceKeys()                   the reference key(s) of a web's citation (#64)
# Nothing here is specific to RunMe.r; the analysis scripts reuse the same
# functions so that evidence and parser see identical rows.

# Life stages kept: unspecified (NA, '', -999), or anything starting with
# 'adult' ('adults', 'adults; juveniles', 'adults / larvae'), 'female', 'male'.
# Juveniles, larvae, nymphs, nauplii, pupae, eggs and 'mature'/'immature' (not
# matched by the pattern) are dropped. Same pattern since 2026-09-24 in the
# GATEWAy parser; Brose_2005 mirrors it (#14).
AdultOrUnspecified <- function(stage) {
  stage <- trimws(as.character(stage))
  is.na(stage) | stage %in% c('', '-999') | grepl('^adult|female|male', stage, ignore.case = TRUE)
}

# Matching key for a taxon string as it appears in a source file: latin-1
# bytes (the retriever's copy of Brose 2005) to UTF-8, diacritics
# transliterated, lower case, blanks squeezed, so that the groups tables
# written by the analysis scripts match the strings the parsers read.
# Latin1ToUtf8() is defined in fix_formatting.r, shared with FixFormatting()
# (#37); RunMe.r and unit_audit.r source both files.
TaxonKey <- function(x) {
  x <- Latin1ToUtf8(x)
  x <- iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT', sub = '')
  x <- gsub("[?'`^~\"]", '', x)
  tolower(gsub('\\s+', ' ', trimws(x)))
}

# GATEWAy: one row per consumer and per resource of every trophic link that
# passes the life-stage filter and has a positive mean mass. `extra` names
# further per-side columns to keep (suffix after 'con.' / 'res.', e.g.
# 'size.method', 'length.mean.cm.').
StackGateway <- function(raw, extra = character(0)) {
  one <- function(side) {
    g    <- function(col) raw[[paste0(side, '.', col)]]
    keep <- AdultOrUnspecified(g('lifestage'))
    out  <- data.frame(foodweb.name  = as.character(raw$foodweb.name[keep]),
                       link.citation = trimws(as.character(raw$link.citation[keep])),
                       role          = side,
                       taxon         = as.character(g('taxonomy')[keep]),
                       metab         = as.character(g('metabolic.type')[keep]),
                       mass_g        = suppressWarnings(as.numeric(g('mass.mean.g.')[keep])),
                       stringsAsFactors = FALSE)
    for (col in extra) out[[col]] <- g(col)[keep]
    out
  }
  dat <- rbind(one('con'), one('res'))
  dat <- dat[!is.na(dat$mass_g) & dat$mass_g > 0, ]
  dat$n <- 1
  dat$source_mass <- 'Brose_etal_2018'
  dat
}

# Brose 2005 (Data Retriever table predator-prey-body-ratio, columns as the
# retriever names them): the same stacking and life-stage filter; rows without
# a taxonomy entry are dropped; the page-range typos of the Warren (1989)
# reference are one study.
StackBrose2005 <- function(ppb, extra = character(0)) {
  for (col in grep('^(link_reference|taxonomy_|lifestage_|metabolic_category_)', names(ppb), value = TRUE))
    ppb[[col]] <- Latin1ToUtf8(ppb[[col]])
  one <- function(side) {
    keep <- AdultOrUnspecified(ppb[[paste0('lifestage_', side)]])
    out  <- data.frame(study  = trimws(as.character(ppb$link_reference[keep])),
                       role   = side,
                       taxon  = as.character(ppb[[paste0('taxonomy_', side)]][keep]),
                       metab  = as.character(ppb[[paste0('metabolic_category_', side)]][keep]),
                       mass_g = suppressWarnings(as.numeric(ppb[[paste0('mean_mass_g_', side)]][keep])),
                       stringsAsFactors = FALSE)
    for (col in extra) out[[col]] <- ppb[[col]][keep]
    out
  }
  dat <- rbind(one('consumer'), one('resource'))
  dat <- dat[!is.na(dat$taxon) & !trimws(dat$taxon) %in% c('', '-999') &
             !is.na(dat$mass_g) & dat$mass_g > 0, ]
  dat$study[grepl('^Warren, P\\. H\\. 1989', dat$study)] <- 'Warren (1989)'
  dat$n <- 1
  dat$source_mass <- 'Brose_2005'
  dat
}

# Group-level placeholder values: within one study (a GATEWAy link.citation or
# a Brose 2005 study) a mean mass carried by >= min_taxa distinct species-level
# names is a default assigned to a group of taxa, not a measurement of any of
# them (0.01 g on 115 tide-pool species; 4.01e-5 g on 37 Chesapeake species;
# ...). Species-level names are two-word names that are not family/order
# labels or 'sp.' placeholders; every row carrying a flagged value is removed,
# whatever its own name's rank. Returns TRUE for those rows.
SpeciesLikeName <- function(taxon) {
  x <- trimws(as.character(taxon))
  grepl('^\\S+\\s+\\S+', x) & !grepl('^(family|order|class|phylum)\\b', x, ignore.case = TRUE) &
    !grepl('\\b(sp|spp|indet|cf|nr|unk|spec)\\.?(\\s|$)', x, ignore.case = TRUE)
}
PlaceholderRows <- function(dat, study, min_taxa = 5, digits = 4) {
  key  <- paste(study, signif(dat$mass_g, digits))
  spl  <- SpeciesLikeName(dat$taxon)
  n_sp <- tapply(TaxonKey(dat$taxon[spl]), key[spl], function(x) length(unique(x)))
  flag <- n_sp[key] >= min_taxa
  flag[is.na(flag)] <- FALSE
  unname(flag)
}

# Drop the placeholder rows with one DropImputed() log entry per study.
DropPlaceholders <- function(dat, study_col, label, min_taxa = 5) {
  flag <- PlaceholderRows(dat, dat[[study_col]], min_taxa)
  for (s in unique(dat[[study_col]][flag])) {
    drop <- flag & dat[[study_col]] == s
    dat  <- DropImputed(dat, drop, label,
                        sprintf('group-level placeholder: mass value shared by >= %d taxa within %s (#14)',
                                min_taxa, s))
    flag <- flag[!drop]
  }
  dat
}

# Gastropods without a shell: slugs (terrestrial families) and sea slugs
# (orders), which take the shell-free tissue factor only (whole = FALSE).
shellless_gastropod_families <- c('Arionidae', 'Agriolimacidae', 'Limacidae', 'Milacidae', 'Boettgerillidae',
                                  'Philomycidae', 'Testacellidae', 'Veronicellidae', 'Onchidiidae',
                                  'Vitrinidae', 'Daudebardiidae')
shellless_gastropod_orders   <- c('Nudibranchia', 'Aplysiida', 'Pleurobranchida', 'Systellommatophora')
ShellLessGastropod <- function(family, order)
  family %in% shellless_gastropod_families | order %in% shellless_gastropod_orders

# Conversion group for ToWetMass(from = 'dry') from the enrichment ranks
# (R/library/mass_conversion.r groups). Fish classes -> 'fish'; hexapods
# (Insecta, Collembola, Entognatha, Protura, Diplura) -> 'insect' (the
# Studier & Sevick water content; springtails by analogy); Mollusca ->
# 'mollusc', shelled classes with whole = TRUE and the Brey 2010 shell ratio of
# their class (bivalve, gastropod, polyplacophoran) so that they enter as whole
# wet mass like Eklof_etal_2017 and McCoy_2008, except the shell-less gastropods
# of ShellLessGastropod() (slugs, sea slugs: tissue factor only); Annelida ->
# 'annelid'; Echinodermata -> 'echinoderm'; Chaetognatha -> 'chaetognath';
# Cnidaria and Ctenophora -> 'gelatinous_zooplankton'; tetrapod classes ->
# 'vertebrate'; everything else (crustaceans, arachnids, myriapods, nematodes,
# ...) -> 'invertebrate'. NA ranks fall to 'invertebrate'.
MassGroupFromRanks <- function(phylum, class, family = NA_character_, order = NA_character_) {
  n <- max(length(phylum), length(class)); family <- rep_len(family, n); order <- rep_len(order, n)
  fish    <- c('Actinopterygii', 'Actinopteri', 'Teleostei', 'Chondrichthyes', 'Elasmobranchii',
               'Holocephali', 'Myxini', 'Petromyzonti', 'Cephalaspidomorphi')
  hexapod <- c('Insecta', 'Collembola', 'Entognatha', 'Protura', 'Diplura')
  tetrapod <- c('Aves', 'Mammalia', 'Amphibia', 'Reptilia', 'Squamata', 'Testudines', 'Crocodylia')
  group <- ifelse(class %in% fish, 'fish',
           ifelse(class %in% hexapod, 'insect',
           ifelse(phylum %in% 'Mollusca', 'mollusc',
           ifelse(phylum %in% 'Annelida', 'annelid',
           ifelse(phylum %in% 'Echinodermata', 'echinoderm',
           ifelse(phylum %in% 'Chaetognatha', 'chaetognath',
           ifelse(phylum %in% c('Cnidaria', 'Ctenophora'), 'gelatinous_zooplankton',
           ifelse(class %in% tetrapod, 'vertebrate', 'invertebrate'))))))))
  shell <- ifelse(class %in% 'Bivalvia', 'bivalve',
           ifelse(class %in% 'Gastropoda' & !ShellLessGastropod(family, order), 'gastropod',
           ifelse(class %in% 'Polyplacophora', 'polyplacophoran', NA_character_)))
  data.frame(mass_group  = group,
             whole       = !is.na(shell),
             shell_group = ifelse(is.na(shell), group, shell),
             stringsAsFactors = FALSE)
}

# Web-level primary references (issue #64): the records of a food web cite the
# web's own citation (GATEWAy link.citation, Brose 2005 Link reference), since
# the web's authors measured, regressed or compiled the masses of their web.
# `refs` is the source's references table (Brose_etal_2018/references.csv,
# DataRetriever/brose2005_references.csv): one row per cited work with its
# `key` (first author's surname and year, 'Kroll_unpublished' for an
# unpublished contribution) and the citation string of the data file in
# `citation_col`; a string naming two works ('Gray et al. (2015), Thompson et
# al. (2017)') has two rows and gives both keys, so that every web of a citation
# shares the same key(s). Every string in `x` must be in the table. Returns the
# '; '-joined keys of SplitRefKeys() (R/library/citations/parse_reflists.r).
WebReferenceKeys <- function(x, refs, citation_col, label) {
  for (col in c('key', citation_col))
    if (col %!in% names(refs)) stop(label, ': references table lacks column ', col)
  cit    <- trimws(as.character(x))
  keymap <- tapply(refs$key, trimws(refs[[citation_col]]), paste, collapse = ';')
  miss   <- setdiff(unique(cit), names(keymap))
  if (length(miss) > 0)
    stop(label, ': ', length(miss), ' citation(s) without a reference key in the references table: ',
         paste(head(miss, 5), collapse = ' | '))
  keys <- SplitRefKeys(keymap, ';')
  names(keys) <- names(keymap)
  unname(keys[cit])
}

# The value-providing source names of the Amniote database's per-cell
# reference strings (Myhrvold et al. 2015, Amniote_Database_References csv;
# issue #1 Stage 2). A cell reads "<name>", "<name> from median of n(<name>,
# ...)" (the stored value is the median of n raw values and equals the one
# <name> reported) or "mean of <name> & <name> from median of n(...)" (an even
# n: the mean of the two middle values; '&' or 'and'); a name may carry the
# batch prefix "BC Birds - " / "BC mammals - " / "BC Reptiles - ", which is not
# part of the reference. The names before "from median of" are the sources of
# the value and become its keys; the names in the brackets are not. `refs` is
# the references table of the source (columns `key` and `reference_name`, the
# vocabulary that lets a cell be split: a name itself holds ', ' and ' and ').
# Returns the '; '-joined keys per cell, NA for a missing cell (-999, empty);
# stops on a cell that the vocabulary cannot split.
AmnioteValueSources <- function(x, refs, label = 'Myhrvold_2015') {
  for (col in c('key', 'reference_name'))
    if (col %!in% names(refs)) stop(label, ': references table lacks column ', col)
  x   <- trimws(as.character(x))
  out <- rep(NA_character_, length(x))
  todo <- which(!is.na(x) & !x %in% c('', '-999'))
  if (length(todo) == 0) return(out)
  nm   <- trimws(refs$reference_name)
  keys <- setNames(trimws(refs$key), nm)
  esc  <- gsub('([][{}()+*^$|\\\\?.])', '\\\\\\1', nm[order(-nchar(nm))])
  alt  <- paste(esc, collapse = '|')
  pfx  <- '(?:BC (?:Birds|mammals|Reptiles) - )?'
  head <- sub(' from median of [0-9]+\\(.*\\)$', '', x[todo], perl = TRUE)
  is_mean <- startsWith(head, 'mean of ')
  body <- ifelse(is_mean, substring(head, 9), head)
  one  <- sprintf('^%s(%s)$', pfx, alt)
  # 'mean of  & Iverson, ..., 1993' (one cell writes an empty first name)
  two  <- sprintf('^%s(%s)? (?:&|and) %s(%s)$', pfx, alt, pfx, alt)
  m1 <- regmatches(body, regexec(one, body, perl = TRUE))
  m2 <- regmatches(body, regexec(two, body, perl = TRUE))
  res <- vapply(seq_along(body), function(i) {
    found <- if (is_mean[i]) m2[[i]][-1] else m1[[i]][-1]
    found <- found[nzchar(found)]
    if (length(found) == 0) return(NA_character_)
    paste(unique(keys[found]), collapse = '; ')
  }, character(1))
  bad <- is.na(res)
  if (any(bad))
    stop(label, ': ', sum(bad), ' reference cell(s) that the references table cannot split: ',
         paste(head(x[todo][bad], 3), collapse = ' | '))
  out[todo] <- res
  out
}

# Apply the per-web (or per-study) actions of a units table to stacked rows.
# `units` has the column `key` (foodweb.name / study), `action` and
# `log_reason`; every value of dat[[key]] must be in the table. Drops are
# logged with DropImputed(), one entry per log_reason. convert_dry rows are
# matched to `groups` by (group_key, TaxonKey(taxon)); rows whose group has
# convert = FALSE stay as they are (trout in the Layer webs, earthworms in the
# Mulder webs, owner decision 2026-10-03); the others become whole wet grams
# through ToWetMass(from = 'dry') and carry the conversion CiteIDs in
# source_mass through LabelWithConversion().
ApplyUnitActions <- function(dat, units, key, groups, group_key, label) {
  for (col in c(key, 'action', 'log_reason'))
    if (col %!in% names(units)) stop(label, ': units table lacks column ', col)
  i <- match(trimws(dat[[key]]), trimws(units[[key]]))
  if (anyNA(i))
    stop(label, ': ', length(unique(dat[[key]][is.na(i)])), ' value(s) of ', key,
         ' missing from the units table: ', paste(head(unique(dat[[key]][is.na(i)]), 5), collapse = '; '))
  action <- units$action[i]
  action[is.na(action) | action == ''] <- 'keep'
  reason <- units$log_reason[i]
  bad <- setdiff(unique(action), c('keep', 'drop', 'convert_dry'))
  if (length(bad) > 0) stop(label, ': unknown action(s) in the units table: ', paste(bad, collapse = ', '))
  for (r in unique(reason[action == 'drop'])) {
    drop   <- action == 'drop' & reason %in% r
    dat    <- DropImputed(dat, drop, label, r)
    action <- action[!drop]; reason <- reason[!drop]
  }
  cv <- which(action == 'convert_dry')
  if (length(cv) > 0) {
    for (col in c(group_key, 'taxon_key', 'mass_group', 'whole', 'shell_group', 'convert'))
      if (col %!in% names(groups)) stop(label, ': groups table lacks column ', col)
    j <- match(paste(trimws(dat[[group_key]][cv]), TaxonKey(dat$taxon[cv])),
               paste(trimws(groups[[group_key]]), groups$taxon_key))
    if (anyNA(j))
      stop(label, ': ', sum(is.na(j)), ' row(s) of convert_dry webs have no conversion group ',
           '(regenerate the groups table); e.g. ', paste(head(unique(dat$taxon[cv][is.na(j)]), 5), collapse = '; '))
    g    <- groups[j, ]
    conv <- cv[g$convert %in% TRUE]
    g    <- g[g$convert %in% TRUE, ]
    if (length(conv) > 0) {
      dat$mass_g[conv]      <- ToWetMass(dat$mass_g[conv], from = 'dry', group = g$mass_group,
                                         whole = g$whole, shell_group = g$shell_group)
      dat$source_mass[conv] <- LabelWithConversion(label, g$mass_group, g$shell_group)
    }
  }
  dat
}
