firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

# Convert the elements of a character vector that are not valid UTF-8 from
# Latin-1 (the retriever's copy of Brose 2005 arrives so) and leave valid
# UTF-8, which every other frame is, untouched. Converting every element from
# Latin-1, as FixFormatting() did before issue #37, double-encoded the UTF-8
# names: 'Nausithoë rubra' became 'NausithoÃ« rubra' and the two Makarieva_2008
# 'Tetrao urogallus ♀' records became NA. Shared with TaxonKey() in
# foodweb_units.r.
Latin1ToUtf8 <- function(x) {
  x <- as.character(x)
  bad <- !is.na(x) & !validUTF8(x)
  x[bad] <- iconv(x[bad], from = 'latin1', to = 'UTF-8')
  x
}

##########################################################################
# Raw-name rules (#38)
##########################################################################
# Every raw taxon name is reduced to 'Genus_species' or 'Genus' by explicit
# rules; nothing is folded away silently. The lexical rules live in the
# tracked vocabulary audit/raw_name_patterns.csv (loaded once per run by
# LoadRawNamePatterns(); FixFormatting() takes it as `patterns`). Its columns:
#   pattern  a Perl regex
#   scope    what the regex is matched against:
#            'epithet'     the second token of the name (case-insensitively):
#                          placeholders (sp., spp., sp2, 'lassp8', indet.) and
#                          identification qualifiers (cf., aff., nr.);
#            'annotation'  the content of a (), [] or {} group, or a token after
#                          the binomial (first the whole trailing text, then
#                          token by token);
#            'name'        the whole raw name, underscores read as spaces and
#                          runs of blanks collapsed.
#   class    subgenus | sex | form_strain_region | size_class | synonym |
#            authority | trinomial (removed, record kept) and life_stage |
#            placeholder | qualifier | hybrid | ambiguous | other_drop (record
#            dropped)
#   action   strip  remove the matched annotation, keep the record;
#            drop   remove the record: placeholder and qualifier records leave
#                   FixFormatting() as a marker, Genus_<word> with the matched
#                   word where RemoveNonTaxa() or a rename rule knows it (sp,
#                   spp, spec, indet, unk, type; cf, nr, aff) and Genus_sp /
#                   Genus_cf otherwise ('Lithobius sp2 {l}' -> Lithobius_sp,
#                   'Lagopus spec.' -> Lagopus_spec), which RemoveNonTaxa()
#                   removes (their historical path); the other drop classes
#                   are removed here through DropImputed() and logged to
#                   audit/imputed_rows.csv;
#            fold   (name scope) keep the first two tokens of the name.
#   note, added   the evidence and the date the row was added.
# Rows are tried in file order; the first match wins.
#
# The structural rules are code: the encoding step (Latin1ToUtf8(), then
# transliteration of diacritics to ASCII; class 'encoding'), the sex signs
# U+2640/U+2642 (class 'sex', stripped, #37), a subgenus is a bracket group
# matching the subgenus row that sits between a capitalised first token and a
# lowercase epithet, a genus written twice ('Castor Castor canadensis') loses
# the repeat (class 'subgenus'), a lowercase trailing token that no row claims
# is an infraspecific epithet and folds into the species ('Acanthiza pusilla
# apicalis' -> Acanthiza_pusilla; class 'trinomial'), and characters that
# cannot occur in a Latin name (punctuation, quotes, asterisks, hyphens, digits
# in trailing tokens) are removed (class 'symbols'). A bracket group or a
# non-lowercase trailing token that no row covers is an error: the name keeps
# its brackets, so it cannot pass for a binomial, and CheckRawNames()
# (check_taxon_names.r) stops the run with the list, so that a new pattern is
# seen and classified, never absorbed. Every classified or changed name is
# appended to `raw_name_log`, which WriteRawNameReport() turns into
# reports/warnings_raw_names.md.
#
# The output format for a name none of this touches is unchanged: blanks and
# underscores become one underscore, the genus is capitalised, the first letter
# of the epithet lowercased (test_raw_name_rules.R pins ~50 ordinary names).

raw_name_pattern_columns <- c('pattern', 'scope', 'class', 'action', 'note', 'added')
raw_name_scopes          <- c('epithet', 'annotation', 'name')
raw_name_actions         <- c('strip', 'drop', 'fold')
raw_name_strip_classes   <- c('subgenus', 'sex', 'form_strain_region', 'size_class',
                              'synonym', 'authority', 'trinomial')
raw_name_drop_classes    <- c('life_stage', 'placeholder', 'qualifier', 'hybrid',
                              'ambiguous', 'other_drop')
raw_name_classes         <- c(raw_name_strip_classes, raw_name_drop_classes)
# drop classes that leave a marker for RemoveNonTaxa() instead of dropping here:
# the matched word itself when RemoveNonTaxa() (or a rename rule) knows it,
# else the class default ('Lithobius sp2' -> Lithobius_sp, 'Lagopus spec.' ->
# Lagopus_spec, 'Zercon cf gurensis' -> Zercon_cf, 'Procapritermes nr.' ->
# Procapritermes_nr)
raw_name_markers         <- c(placeholder = 'sp', qualifier = 'cf')
raw_name_marker_words    <- list(placeholder = c('sp', 'spp', 'spec', 'indet', 'unk', 'type'),
                                 qualifier   = c('cf', 'nr', 'aff'))
# the reasons DropImputed() logs for the classes dropped here
raw_name_drop_reasons <- c(
  life_stage = 'life-stage annotation in the raw name: not an adult record (audit/raw_name_patterns.csv, #8, #38)',
  hybrid     = 'hybrid or intergrade between two taxa in the raw name (audit/raw_name_patterns.csv, #38)',
  ambiguous  = 'two or more alternative taxa in one raw name (audit/raw_name_patterns.csv, #38)',
  other_drop = 'raw name matched an other_drop rule of audit/raw_name_patterns.csv (#38)')
# classes assigned by code, not by the vocabulary
raw_name_code_classes    <- c('encoding', 'symbols', 'error')
# the class a name is filed under in the report when several apply
raw_name_class_order     <- c('error', raw_name_drop_classes, 'subgenus', 'sex',
                              'form_strain_region', 'size_class', 'synonym', 'authority',
                              'trinomial', 'encoding', 'symbols')

# One entry per FixFormatting() call: the names it classified or changed, with
# their class, action, result, source label and row count.
raw_name_log <- list()

# Read and validate audit/raw_name_patterns.csv.
LoadRawNamePatterns <- function(path) {
  if (!file.exists(path))
    stop('raw-name vocabulary not found: ', path, call. = FALSE)
  p <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character',
                encoding = 'UTF-8', na.strings = character(0))
  missing <- setdiff(raw_name_pattern_columns, names(p))
  if (length(missing) > 0)
    stop(basename(path), ' lacks the column(s) ', paste(missing, collapse = ', '), call. = FALSE)
  bad <- character(0)
  Bad <- function(ok, what) if (any(!ok)) bad <<- c(bad, sprintf('%s: row(s) %s', what, paste(which(!ok), collapse = ', ')))
  Bad(nzchar(trimws(p$pattern)), 'empty pattern')
  Bad(p$scope  %in% raw_name_scopes,  paste('scope not one of', paste(raw_name_scopes, collapse = '|')))
  Bad(p$class  %in% raw_name_classes, paste('class not one of', paste(raw_name_classes, collapse = '|')))
  Bad(p$action %in% raw_name_actions, paste('action not one of', paste(raw_name_actions, collapse = '|')))
  Bad(p$scope != 'epithet' | (p$class %in% names(raw_name_markers) & p$action == 'drop'),
      "an epithet-scope row must be class placeholder or qualifier with action drop")
  Bad(p$scope != 'annotation' | p$action != 'fold', "an annotation-scope row cannot fold")
  Bad(p$scope != 'name' | p$action != 'strip', "a name-scope row cannot strip (use fold or drop)")
  Bad(p$action != 'strip' | p$class %in% raw_name_strip_classes, 'action strip with a drop class')
  Bad(p$action != 'drop'  | p$class %in% raw_name_drop_classes,  'action drop with a strip class')
  compiles <- vapply(p$pattern, function(re)
    !inherits(tryCatch(suppressWarnings(grepl(re, 'x', perl = TRUE)), error = function(e) e), 'error'), logical(1))
  Bad(compiles, 'pattern is not a valid Perl regex')
  if (length(bad) > 0)
    stop(basename(path), ' is malformed:\n', paste0('  ', bad, collapse = '\n'), call. = FALSE)
  p
}

# ---- helpers of the parser ------------------------------------------------------
# A name with underscores read as spaces and runs of blanks collapsed.
NormaliseBlanks <- function(x) gsub('[ _]+', ' ', trimws(gsub('_', ' ', x)))
# Only letters survive in a token of the cleaned name.
LettersOnly <- function(x) gsub('[^A-Za-z]', '', x)
LowerFirst  <- function(x) paste0(tolower(substr(x, 1, 1)), substr(x, 2, nchar(x)))
# Genus_species (or Genus) from a genus token and an optional epithet token.
Assemble <- function(genus, epithet = '') {
  g <- LettersOnly(genus); e <- LettersOnly(epithet)
  if (!nzchar(g)) return('')
  if (nzchar(e)) paste0(firstup(g), '_', LowerFirst(e)) else firstup(g)
}
bracket_re <- '\\(([^()]*)\\)?|\\[([^][]*)\\]?|\\{([^{}]*)\\}?'   # a group, closed or open-ended

# The first vocabulary row (of the given scope and allowed classes) matching `s`.
MatchRow <- function(s, rows, ignore_case = FALSE) {
  for (i in seq_len(nrow(rows)))
    if (grepl(rows$pattern[i], s, perl = TRUE, ignore.case = ignore_case)) return(rows[i, ])
  NULL
}

# Parse one raw name (already ASCII). Returns a list: cleaned (the name,
# '' when nothing is left, NA when the record is dropped here), classes, action
# ('none' | 'strip' | 'drop' | 'fold' | 'error'), dropped, drop_class, error.
ParseOneRawName <- function(x, pat) {
  classes <- character(0)
  Add <- function(cl) classes <<- c(classes, cl)
  Done <- function(cleaned, action, dropped = FALSE, drop_class = NA_character_, error = FALSE)
    list(cleaned = cleaned, classes = unique(classes), action = action, dropped = dropped,
         drop_class = drop_class, error = error)
  ep_rows  <- pat[pat$scope == 'epithet', ]
  nm_rows  <- pat[pat$scope == 'name', ]
  an_rows  <- pat[pat$scope == 'annotation', ]
  norm     <- NormaliseBlanks(x)
  # A drop by class: a marker for RemoveNonTaxa() or a dropped record.
  Drop <- function(cl, genus, word = '') {
    Add(cl)
    if (cl %in% names(raw_name_markers)) {
      g <- LettersOnly(genus)
      w <- tolower(LettersOnly(word))
      marker <- if (w %in% raw_name_marker_words[[cl]]) w else raw_name_markers[[cl]]
      return(Done(if (nzchar(g)) paste0(firstup(g), '_', marker) else '', 'drop'))
    }
    Done(NA_character_, 'drop', dropped = TRUE, drop_class = cl)
  }

  # bracket groups and the tokens outside them
  m        <- gregexpr(bracket_re, x, perl = TRUE)[[1]]
  groups   <- if (m[1] > 0) regmatches(x, list(m))[[1]] else character(0)
  contents <- trimws(sub('^[([{]', '', sub('[])}]$', '', groups, perl = TRUE), perl = TRUE))
  outside  <- x
  if (length(groups) > 0) regmatches(outside, list(m)) <- list(rep(' ', length(groups)))
  tokens   <- strsplit(NormaliseBlanks(outside), ' ', fixed = TRUE)[[1]]
  tokens   <- tokens[nzchar(tokens)]
  if (length(tokens) == 0) return(Done('', 'none'))
  # the subgenus position: a group right after a capitalised first token,
  # followed by a lowercase epithet outside the brackets
  subgenus_pos <- FALSE
  if (length(groups) > 0) {
    before <- strsplit(NormaliseBlanks(substr(x, 1, m[1] - 1)), ' ', fixed = TRUE)[[1]]
    after  <- strsplit(NormaliseBlanks(substr(x, m[1] + attr(m, 'match.length')[1], nchar(x))), ' ', fixed = TRUE)[[1]]
    before <- before[nzchar(before)]; after <- after[nzchar(after)]
    subgenus_pos <- length(before) == 1 && grepl('^[A-Z]', before) &&
      length(after) >= 1 && grepl('^[a-z]+$', after[1])
  }

  # 1. the epithet position: placeholders and identification qualifiers
  if (length(tokens) >= 2) {
    r <- MatchRow(tokens[2], ep_rows, ignore_case = TRUE)
    if (!is.null(r)) return(Drop(r$class, tokens[1], tokens[2]))
  }
  # 2. whole-name rules
  r <- MatchRow(norm, nm_rows)
  if (!is.null(r)) {
    if (r$action == 'drop') return(Drop(r$class, tokens[1]))
    Add(r$class)                                        # fold: the first two tokens
    kept <- strsplit(NormaliseBlanks(gsub('[][(){}]', ' ', x)), ' ', fixed = TRUE)[[1]]
    kept <- kept[nzchar(kept)]
    return(Done(Assemble(kept[1], if (length(kept) >= 2) kept[2] else ''), 'fold'))
  }
  # 3. a genus written twice
  if (length(tokens) >= 2 && grepl('^[A-Z]', tokens[2]) &&
      tolower(LettersOnly(tokens[2])) == tolower(LettersOnly(tokens[1]))) {
    tokens <- tokens[-2]
    Add('subgenus')
  }
  # 4. bracket groups
  error <- FALSE
  for (i in seq_along(groups)) {
    if (!nzchar(contents[i])) { Add('symbols'); next }
    rows <- if (i == 1 && subgenus_pos) an_rows else an_rows[an_rows$class != 'subgenus', ]
    r <- MatchRow(contents[i], rows)
    if (is.null(r)) { Add('error'); error <- TRUE; next }
    if (r$action == 'drop') return(Drop(r$class, tokens[1]))
    Add(r$class)
  }
  # 5. tokens after the binomial
  if (length(tokens) > 2) {
    tail <- tokens[-(1:2)]
    rows <- an_rows[an_rows$class != 'subgenus', ]
    r <- MatchRow(paste(tail, collapse = ' '), rows)
    if (!is.null(r)) {
      if (r$action == 'drop') return(Drop(r$class, tokens[1]))
      Add(r$class)
    } else {
      for (tok in tail) {
        if (!grepl('[A-Za-z0-9]', tok)) { Add('symbols'); next }
        r <- MatchRow(tok, rows)
        if (!is.null(r)) {
          if (r$action == 'drop') return(Drop(r$class, tokens[1], tok))
          Add(r$class)
        } else if (grepl('^[a-z]', tok) && grepl('^[a-z]+$', LettersOnly(tok))) {
          Add('trinomial')                              # an infraspecific epithet
          if (LettersOnly(tok) != tok) Add('symbols')
        } else {
          Add('error'); error <- TRUE
        }
      }
    }
  }
  if (error) return(Done(gsub(' ', '_', norm, fixed = TRUE), 'error', error = TRUE))
  # 6. the binomial itself
  epithet <- if (length(tokens) >= 2) tokens[2] else ''
  if (LettersOnly(tokens[1]) != tokens[1] || LettersOnly(epithet) != epithet) Add('symbols')
  Done(Assemble(tokens[1], epithet), if (length(classes) > 0) 'strip' else 'none')
}

# Parse a vector of distinct ASCII names. Names of one or two alphabetic tokens
# that no epithet-scope or name-scope row claims take a vectorised shortcut;
# everything else goes through ParseOneRawName().
ParseRawNames <- function(x, pat) {
  norm   <- NormaliseBlanks(x)
  simple <- grepl('^[A-Za-z]+( [A-Za-z]+)?$', norm)
  tok1   <- sub(' .*$', '', norm)
  tok2   <- ifelse(grepl(' ', norm, fixed = TRUE), sub('^[^ ]+ ', '', norm), '')
  hit    <- rep(FALSE, length(x))
  for (i in which(pat$scope == 'epithet'))
    hit <- hit | (nzchar(tok2) & grepl(pat$pattern[i], tok2, perl = TRUE, ignore.case = TRUE))
  for (i in which(pat$scope == 'name'))
    hit <- hit | grepl(pat$pattern[i], norm, perl = TRUE)
  fast <- simple & !hit
  out <- data.frame(raw = x, cleaned = NA_character_, classes = '', action = 'none',
                    dropped = FALSE, drop_class = NA_character_, error = FALSE,
                    stringsAsFactors = FALSE)
  out$cleaned[fast] <- ifelse(nzchar(tok2[fast]),
                              paste0(firstup(tok1[fast]), '_', LowerFirst(tok2[fast])),
                              firstup(tok1[fast]))
  for (i in which(!fast)) {
    p <- ParseOneRawName(x[i], pat)
    out$cleaned[i]    <- p$cleaned
    out$classes[i]    <- paste(p$classes, collapse = '+')
    out$action[i]     <- p$action
    out$dropped[i]    <- p$dropped
    out$drop_class[i] <- p$drop_class
    out$error[i]      <- p$error
  }
  out
}

# The class a name is filed under in the report: the first of
# raw_name_class_order among its classes.
PrimaryClass <- function(classes) {
  vapply(strsplit(classes, '+', fixed = TRUE), function(cl) {
    cl <- cl[nzchar(cl)]
    if (length(cl) == 0) return('')
    pos <- match(cl, raw_name_class_order)
    if (all(is.na(pos))) cl[1] else raw_name_class_order[min(pos, na.rm = TRUE)]
  }, character(1))
}

FixFormatting <- function(dat, patterns = raw_name_patterns) {
  if (!is.data.frame(patterns) || !all(raw_name_pattern_columns %in% names(patterns)))
    stop('FixFormatting() needs the vocabulary of audit/raw_name_patterns.csv: ',
         'raw_name_patterns <- LoadRawNamePatterns(path)', call. = FALSE)
  raw <- as.character(dat$taxon)
  labels <- if ('source_mass' %in% names(dat))
    trimws(sub(';.*$', '', as.character(dat$source_mass))) else rep('unknown', nrow(dat))
  labels[is.na(labels) | !nzchar(labels)] <- 'unknown'

  # Normalise encoding: only strings that are not valid UTF-8 are converted
  # from Latin-1 (#37); then the sex signs are dropped and the record kept
  # (owner decision, #37; this must precede the transliteration: macOS iconv
  # has no ASCII rendering of U+2640 and U+2642 and, without `sub`, returns NA
  # for the whole name). Diacritics are transliterated to ASCII base
  # characters (ë→e, ü→u, ñ→n, etc.; macOS iconv writes them as "e, "u, ~n,
  # glibc as e, u, n), residual non-ASCII bytes and the '?' glibc inserts for
  # untransliterable characters are removed; `sub = ''` drops a character that
  # has no transliteration instead of turning the whole name into NA.
  x <- Latin1ToUtf8(raw)
  raw <- x                               # the log shows the name as valid UTF-8
  has_sign  <- !is.na(x) & grepl('[\u2640\u2642]', x)
  x <- gsub('[\u2640\u2642]', '', x)
  non_ascii <- !is.na(x) & grepl('[^\x01-\x7F]', x)
  x <- iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT', sub = '')
  x <- gsub('[^\x01-\x7F]', '', x)
  # The stray marks macOS TRANSLIT leaves ("o for ö, 'e for é, ~n for ñ) and
  # the '?' glibc inserts cannot occur in a name, so they go before the parse
  # (as in NormaliseSourceLabel()); raw quotes and apostrophes go with them.
  x <- gsub("[?'`^~\"]", '', x)

  # Parse each distinct name once.
  u      <- unique(x[!is.na(x)])
  parsed <- ParseRawNames(u, patterns)
  idx    <- match(x, parsed$raw)
  cleaned    <- parsed$cleaned[idx]
  dropped    <- !is.na(idx) & parsed$dropped[idx]
  drop_class <- parsed$drop_class[idx]
  classes    <- parsed$classes[idx]
  classes    <- ifelse(non_ascii, paste0('encoding+', classes), classes)
  classes    <- ifelse(has_sign,  paste0('sex+', classes), classes)
  classes    <- gsub('\\+$', '', classes)
  changed    <- !is.na(idx) & (dropped | parsed$error[idx] |
                  tolower(cleaned) != tolower(gsub(' ', '_', NormaliseBlanks(raw), fixed = TRUE)))
  classes    <- ifelse(changed & !nzchar(classes), 'symbols', classes)

  # The log: one line per raw name and source label.
  sel <- !is.na(idx) & (changed | nzchar(classes))
  if (any(sel)) {
    key <- paste(raw[sel], labels[sel], sep = '\r')
    first <- !duplicated(key)
    entry <- data.frame(
      raw     = raw[sel][first],
      cleaned = cleaned[sel][first],
      class   = PrimaryClass(classes[sel][first]),
      classes = classes[sel][first],
      action  = ifelse(dropped[sel][first], 'drop', parsed$action[idx[sel]][first]),
      source  = labels[sel][first],
      rows    = as.integer(table(key)[key[first]]),
      dropped = dropped[sel][first],
      error   = parsed$error[idx[sel]][first],
      stringsAsFactors = FALSE)
    raw_name_log[[length(raw_name_log) + 1L]] <<- entry
  }

  # Records dropped here (life stages, hybrids, ambiguous names) are logged
  # through DropImputed(), one entry per class and source label.
  for (cl in unique(drop_class[dropped])) {
    for (lab in unique(labels[dropped & drop_class %in% cl])) {
      in_lab <- which(labels == lab)
      DropImputed(dat[in_lab, , drop = FALSE], dropped[in_lab] & drop_class[in_lab] %in% cl,
                  lab, raw_name_drop_reasons[[cl]])
    }
  }

  dat$taxon <- cleaned
  # Drop the records removed above and rows with an empty or missing taxon
  # after all normalisation (an NA in the logical index would keep a row of
  # NAs instead of dropping it).
  dat <- dat[!dropped & !is.na(dat$taxon) & dat$taxon != '', , drop = FALSE]
  return(dat)
}

# Bind the raw-name log into one data frame (empty with the right columns when
# nothing was logged).
RawNameLogTable <- function(log = raw_name_log) {
  if (length(log) == 0)
    return(data.frame(raw = character(0), cleaned = character(0), class = character(0),
                      classes = character(0), action = character(0), source = character(0),
                      rows = integer(0), dropped = logical(0), error = logical(0),
                      stringsAsFactors = FALSE))
  do.call(rbind, log)
}

# What each class means, for the report.
raw_name_class_text <- c(
  error              = 'A bracket group or a trailing token that no row of audit/raw_name_patterns.csv covers. The name keeps its brackets and CheckRawNames() stops the run: add a row to the vocabulary (or fix the source) so that the pattern is classified, never absorbed.',
  life_stage         = 'A life-stage annotation (stage code, nauplius, copepodite, larva, megalops, juvenile, immature, egg, pupa, ...): the record is not an adult and is dropped through DropImputed() (scope rule of #8), one entry per source in audit/imputed_rows.csv.',
  placeholder        = "No species-level identification (sp., spp., spec., indet., morphospecies codes, 'species A', 'Unidentified'): the record leaves FixFormatting() as the marker Genus_sp (or Genus_spp, Genus_spec, Genus_indet, Genus_unk, Genus_type as written) and RemoveNonTaxa() removes it, unless a rename rule maps the marker to a genus-level record (six Brose_etal_2018 'Genus spec.' names, fix_misspellings.r).",
  qualifier          = 'An identification qualifier (cf., aff., nr., a species group or aggregate): the record leaves FixFormatting() as the marker Genus_cf (or Genus_nr, Genus_aff as written) and RemoveNonTaxa() removes it. A bare genus with its epithet in brackets (VertNet) folds to the binomial instead.',
  hybrid             = 'A hybrid or intergrade between two taxa (names joined by x): a record of neither parent, dropped through DropImputed().',
  ambiguous          = 'Two or more alternative taxa in one name (joined by /, a comma, a semicolon or "and"): dropped through DropImputed().',
  other_drop         = 'Dropped by an other_drop rule of the vocabulary.',
  subgenus           = 'A subgenus in brackets between the genus and the epithet, or the genus written twice, is removed; the binomial is kept.',
  sex                = "A sex mark (F, M, female(s), male(s), the signs U+2640/U+2642) is removed; the record is kept as the species' value (owner decision, #37).",
  form_strain_region = 'A form, strain, culture or population annotation is removed; the record is kept.',
  size_class         = 'A size-class tag ({s}, {m}, {l}, {xl}, large, small) is removed; every class feeds the species mean (not a life stage; owner to decide).',
  synonym            = 'An alternative name, epithet or common name in brackets after the binomial is removed.',
  authority          = 'An author or author-and-year citation is removed.',
  trinomial          = 'A third, lowercase token (a subspecies or variety epithet, with or without a rank marker such as var. or ssp.) folds into the species.',
  encoding           = 'Non-ASCII characters: Latin-1 input converted to UTF-8, diacritics transliterated to their base letters, anything else removed.',
  symbols            = 'Characters that cannot occur in a Latin name (punctuation, quotes, asterisks, question marks, hyphens, digits) removed.')

# reports/warnings_raw_names.md: every raw name FixFormatting() classified or
# changed beyond blank -> underscore, by class and source.
WriteRawNameReport <- function(path, log = raw_name_log, max_examples = 60L) {
  tab <- RawNameLogTable(log)
  now <- format(Sys.time(), '%Y-%m-%d %H:%M:%S')
  fmt <- function(n) format(n, big.mark = ',', trim = TRUE)
  Code <- function(s) paste0('`', gsub('`', "'", s), '`')
  out <- c(sprintf('# TaxonBodyMass_DB Raw Name Report -- %s', now), '',
           paste('Every raw taxon name that `FixFormatting()` (`R/library/fix_formatting.r`) changed',
                 'beyond blank -> underscore or that matched a rule of `audit/raw_name_patterns.csv`,',
                 'grouped by the class of the rule that decided its fate and by source. Row counts are',
                 'records in the cached frames before any later filter. A dropped record shows `(dropped)`;',
                 'a `Genus_sp` or `Genus_cf` result is a marker that `RemoveNonTaxa()` removes.'), '')
  if (nrow(tab) == 0) {
    writeLines(c(out, 'No raw name was changed or classified.'), path)
    return(invisible(tab))
  }
  tab$class[!nzchar(tab$class)] <- 'symbols'
  classes <- raw_name_class_order[raw_name_class_order %in% tab$class]
  n_err <- length(unique(tab$raw[tab$error]))
  out <- c(out, '## Summary', '',
           sprintf('%s distinct raw names (%s rows) in %d class(es). Names not covered by any rule (class `error`): %d%s.',
                   fmt(length(unique(tab$raw))), fmt(sum(tab$rows)), length(classes), n_err,
                   if (n_err > 0) ' -- THE RUN STOPS; see below' else ''), '',
           '| class | names | rows | records dropped | sources |', '|---|---:|---:|---:|---|')
  for (cl in classes) {
    s <- tab[tab$class == cl, ]
    src <- sort(table(s$source), decreasing = TRUE)
    out <- c(out, sprintf('| %s | %s | %s | %s | %s |', cl, fmt(length(unique(s$raw))), fmt(sum(s$rows)),
                          fmt(sum(s$rows[s$dropped])),
                          paste(sprintf('%s (%d)', names(src), as.integer(src)), collapse = ', ')))
  }
  for (cl in classes) {
    s <- tab[tab$class == cl, ]
    s <- s[order(-s$rows, s$raw), ]
    by_src <- aggregate(cbind(rows = s$rows, names = 1L), by = list(source = s$source), FUN = sum)
    by_src <- by_src[order(-by_src$rows), ]
    out <- c(out, '', sprintf('## %s (%s names, %s rows)', cl, fmt(length(unique(s$raw))), fmt(sum(s$rows))), '',
             raw_name_class_text[[cl]], '',
             paste0('By source: ', paste(sprintf('%s (%d names, %s rows)', by_src$source, by_src$names, fmt(by_src$rows)),
                                         collapse = '; '), '.'), '')
    shown <- if (cl == 'error') s else head(s, max_examples)
    if (nrow(shown) < nrow(s))
      out <- c(out, sprintf('The %d names with most records (of %d):', nrow(shown), nrow(s)), '')
    out <- c(out, '| raw name | result | classes | rows | source |', '|---|---|---|---:|---|',
             sprintf('| %s | %s | %s | %s | %s |', Code(shown$raw),
                     ifelse(shown$dropped, '(dropped)', Code(shown$cleaned)),
                     shown$classes, fmt(shown$rows), shown$source))
  }
  writeLines(out, path)
  invisible(tab)
}
