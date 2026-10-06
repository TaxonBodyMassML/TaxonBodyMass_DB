# Citation tooling (issue #1): the offline part RunMe.r sources (after
# citations_config.r).
#
#   LoadPrimaryReferences(wd_db)         every sources/databases/*/primary_references.csv
#                                        (or primary_references_<Label>.csv in a folder
#                                        several labels share), unique on (source_label,
#                                        native_key)
#   LoadProvenanceClasses(path, labels)  Bib/source_provenance_classes.csv; stops on a
#                                        source label the registry does not know
#   SplitSourceMass(source_mass)         label (first token) and the conversion CiteIDs
#                                        LabelWithConversion() appended after ';'
#   BuildProvenance(records, ...)        TaxonBodyMass_Provenance.csv.gz: one row per
#                                        species x source label x reference (hop,
#                                        provenance_type, primary_*; match_status
#                                        'unmatched_key' for a key the reference list
#                                        lacks, 'uningested' for a source without a
#                                        primary_references.csv), hop-2 rows through a
#                                        reference that is itself a database source
#                                        (MatchIntermediateLabel(), IntermediateReferences()),
#                                        the length-source (measurement) and equation rows
#                                        of a derived source's keyed records,
#                                        conversion-factor rows and lab-Sheet rows
#   CheckCitations(...)                  every primary_bibcite has a bib entry, every CiteID
#                                        a Sheet row, every accepted row a DOI or an
#                                        approval; per-source coverage
#   WriteCitationsReport(path, checks)   reports/warnings_citations.md
# Base R only, no network.

# ---- loaders -----------------------------------------------------------------------------
LoadPrimaryReferences <- function(wd_db) {
  files <- list.files(wd_db, pattern = '^primary_references(_[A-Za-z0-9_-]+)?\\.csv$', recursive = TRUE, full.names = TRUE)
  if (length(files) == 0) return(EmptyPrimaryReferences())
  prim <- do.call(rbind, lapply(files, function(f) {
    d <- ReadPrimaryReferences(f)
    folder <- basename(dirname(f))
    if (any(is.na(d$source_label) | !nzchar(d$source_label)))
      stop(f, ': every row needs a source_label', call. = FALSE)
    d
  }))
  rownames(prim) <- NULL
  key <- paste(prim$source_label, prim$native_key)
  if (anyDuplicated(key))
    stop('primary_references.csv: duplicated (source_label, native_key): ',
         paste(unique(key[duplicated(key)]), collapse = ', '), call. = FALSE)
  bad_status <- setdiff(na.omit(prim$match_status), match_statuses)
  if (length(bad_status) > 0)
    stop('primary_references.csv: unknown match_status ', paste(bad_status, collapse = ', '), call. = FALSE)
  bad_role <- setdiff(na.omit(prim$role), reference_roles)
  if (length(bad_role) > 0)
    stop('primary_references.csv: unknown role ', paste(bad_role, collapse = ', '), call. = FALSE)
  no_doi <- prim$match_status %in% c('certain', 'approved') & is.na(prim$doi) & is.na(prim$bibcite)
  if (any(no_doi))
    stop('primary_references.csv: certain/approved row(s) without a DOI or a manual bibcite: ',
         paste(key[no_doi], collapse = ', '), call. = FALSE)
  prim
}

# The registry of source classes. `known_labels`: SourceLabel() of every record
# of the source frames (the lab Sheet's labels are not source labels). Stops on
# an unregistered label, a bad vocabulary value or a duplicate; a registered
# label absent from the frames is reported, not fatal (a source may be
# switched off by a download flag).
LoadProvenanceClasses <- function(path, known_labels) {
  if (!file.exists(path)) stop('source provenance registry not found: ', path, call. = FALSE)
  d <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                check.names = FALSE, strip.white = TRUE, encoding = 'UTF-8')
  miss <- setdiff(provenance_class_columns, names(d))
  if (length(miss) > 0) stop(basename(path), ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  d <- d[, provenance_class_columns]
  problems <- character(0)
  if (any(is.na(d$source_label))) problems <- c(problems, 'empty source_label')
  if (anyDuplicated(d$source_label)) problems <- c(problems, paste('duplicated label(s)', paste(unique(d$source_label[duplicated(d$source_label)]), collapse = ', ')))
  bad <- setdiff(unique(d$class), provenance_classes)
  if (length(bad) > 0) problems <- c(problems, sprintf('unknown class %s (allowed: %s)', paste(bad, collapse = ', '), paste(provenance_classes, collapse = ', ')))
  bad <- setdiff(unique(d$default_provenance_type), provenance_types)
  if (length(bad) > 0) problems <- c(problems, sprintf('unknown default_provenance_type %s (allowed: %s)', paste(bad, collapse = ', '), paste(provenance_types, collapse = ', ')))
  # value_tier (#34): 1, 2 or 3 in every row (exclude_discordant.r)
  tier <- suppressWarnings(as.integer(d$value_tier))
  bad_tier <- is.na(tier) | !tier %in% 1:3 | tier != suppressWarnings(as.numeric(d$value_tier))
  if (any(bad_tier)) problems <- c(problems, sprintf('value_tier must be 1, 2 or 3 in every row (bad: %s)', paste(d$source_label[bad_tier], collapse = ', ')))
  if (length(problems) > 0) stop(basename(path), ': ', paste(problems, collapse = '; '), call. = FALSE)
  d$value_tier <- tier
  eq <- d$default_provenance_type %in% 'derived_allometry' & is.na(d$equation_bibcite)
  if (any(eq))
    message(sprintf('  %s: derived source(s) without an equation_bibcite yet (their rows carry no equation reference): %s',
                    basename(path), paste(d$source_label[eq], collapse = ', ')))
  known_labels <- unique(na.omit(as.character(known_labels)))
  unregistered <- setdiff(known_labels, d$source_label)
  if (length(unregistered) > 0)
    stop(length(unregistered), ' source label(s) not registered in ', basename(path),
         ' (add a row with class, default_provenance_type, equation_bibcite, notes): ',
         paste(unregistered, collapse = ', '), call. = FALSE)
  absent <- setdiff(d$source_label, known_labels)
  if (length(absent) > 0)
    message(sprintf('  %s: %d registered label(s) not in the source frames of this run: %s',
                    basename(path), length(absent), paste(absent, collapse = ', ')))
  rownames(d) <- NULL
  d
}

# source_mass -> list(label, conversion): the first token is the source label,
# the rest are the conversion CiteIDs LabelWithConversion() appended
# ('Kiorboe_2013; Brey_2010'). Every non-first token must be a known conversion
# CiteID (`known`: MassConversionFactors$cite_id split); others are reported
# with a warning and kept.
SplitSourceMass <- function(source_mass, known = NULL) {
  x <- as.character(source_mass)
  parts <- strsplit(x, ';', fixed = TRUE)
  label <- vapply(parts, function(p) if (length(p) == 0) NA_character_ else trimws(p[1]), character(1))
  conv  <- vapply(parts, function(p) if (length(p) <= 1) NA_character_ else paste(unique(trimws(p[-1])), collapse = '; '), character(1))
  if (!is.null(known)) {
    toks <- unique(trimws(unlist(strsplit(na.omit(conv), ';', fixed = TRUE))))
    bad <- setdiff(toks, known)
    if (length(bad) > 0)
      warning('source_mass token(s) after the label are not conversion CiteIDs of MassConversionFactors: ',
              paste(bad, collapse = ', '), call. = FALSE, immediate. = TRUE)
  }
  list(label = label, conversion = conv)
}

KnownConversionCiteIDs <- function() {
  if (!exists('MassConversionFactors')) return(character())
  unique(trimws(unlist(strsplit(MassConversionFactors$cite_id, ';', fixed = TRUE))))
}

# ---- hop 2: references that are themselves database sources ---------------------------------
# The source label a resolved reference stands for, or NA: its CiteID is a
# registered label, or its bib key / DOI is that of a label's curated entry
# (`labels`, `label_bib`, `label_doi`: the registry's labels with their Bibcite
# and DOI from the CiteIDs frame). Matching by DOI needs the label's curated
# bib entry to carry its `doi` field.
MatchIntermediateLabel <- function(cite_id, bibcite, doi, labels, label_bib, label_doi) {
  out <- rep(NA_character_, length(cite_id))
  m <- match(cite_id, labels); ok <- !is.na(cite_id) & !is.na(m); out[ok] <- labels[m[ok]]
  m <- match(bibcite, label_bib); ok <- is.na(out) & !is.na(bibcite) & !is.na(m); out[ok] <- labels[m[ok]]
  m <- match(tolower(doi), tolower(label_doi)); ok <- is.na(out) & !is.na(doi) & !is.na(m); out[ok] <- labels[m[ok]]
  out
}

# The resolved references of the intermediate labels' own records, one row per
# species x label x reference (`i_*`: the reference's role, status, CiteID,
# bib key and DOI), from the pipeline records (`pipe`: the same frame
# BuildProvenance() works on) and the primary references. Only accepted
# statuses and self references count; a pending or unmatched key of the
# intermediate gives no row (the record is then terminal at the intermediate).
IntermediateReferences <- function(pipe, prim, labels) {
  empty <- data.frame(genus = character(), species = character(), label = character(), i_role = character(),
                      i_status = character(), i_cite_id = character(), i_bibcite = character(), i_doi = character(),
                      stringsAsFactors = FALSE)
  ip <- pipe[pipe$source_label %in% labels & !is.na(pipe$ref_keys), , drop = FALSE]
  if (nrow(ip) == 0) return(empty)
  ex <- ExplodeRefKeys(ip$ref_keys)
  il <- unique(data.frame(genus = ip$genus[ex$record], species = ip$species[ex$record], label = ip$source_label[ex$record],
                          native_key = ex$native_key, stringsAsFactors = FALSE))
  pj <- match(paste(il$label, il$native_key), paste(prim$source_label, prim$native_key))
  keep <- !is.na(pj) & prim$match_status[pj] %in% c('certain', 'approved', 'nodoi_approved', 'self')
  il <- il[keep, , drop = FALSE]; pj <- pj[keep]
  if (nrow(il) == 0) return(empty)
  out <- data.frame(genus = il$genus, species = il$species, label = il$label, i_role = prim$role[pj],
                    i_status = prim$match_status[pj], i_cite_id = prim$cite_id[pj], i_bibcite = prim$bibcite[pj],
                    i_doi = prim$doi[pj], stringsAsFactors = FALSE)
  out <- unique(out)
  rownames(out) <- NULL
  out
}

# ---- the provenance table ------------------------------------------------------------------
EmptyProvenance <- function() {
  out <- as.data.frame(setNames(rep(list(character()), length(provenance_columns)), provenance_columns), stringsAsFactors = FALSE)
  out$hop <- integer(); out$n_records <- integer()
  out[, provenance_columns]
}

# `records`: the per-record frame (genus, species, taxon, source_label, origin;
# optional conversion_ids, ref_keys, prov_type), restricted here to the
# (genus, species) pairs of `accepted`. `prim`: LoadPrimaryReferences();
# `classes`: LoadProvenanceClasses(); `citeids`: a frame with CiteID and
# Bibcite (and doi) mapping labels and conversion CiteIDs to bib keys.
# `statuses` (#34): a frame (genus, species, source_group, record_status) of
# the Pass-1 values, from ExcludeDiscordantValues(); a row's record_status is
# that of its species x source group ('kept', or 'excluded_<rule>' for a value
# the record-level range rule left out of the mean), 'kept' for lab-Sheet rows
# and when no status is given.
BuildProvenance <- function(records, prim, classes, citeids, accepted, statuses = NULL) {
  need <- c('genus', 'species', 'taxon', 'source_label', 'origin')
  miss <- setdiff(need, names(records))
  if (length(miss) > 0) stop('BuildProvenance(): records lack column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  for (col in c('conversion_ids', 'ref_keys', 'prov_type')) if (!col %in% names(records)) records[[col]] <- NA_character_
  rec <- records[!is.na(records$species) & paste(records$genus, records$species) %in% paste(accepted$genus, accepted$species), , drop = FALSE]
  if (nrow(rec) == 0) return(EmptyProvenance())
  cite_key <- if (exists('NormaliseSourceLabel')) NormaliseSourceLabel(citeids$CiteID) else citeids$CiteID
  bib_of  <- setNames(citeids$Bibcite, cite_key)[!duplicated(cite_key)]
  doi_of  <- if ('doi' %in% names(citeids)) setNames(citeids$doi, cite_key)[!duplicated(cite_key)] else character()
  cite_of_bib <- setNames(citeids$CiteID, citeids$Bibcite)[!duplicated(citeids$Bibcite)]
  Bib <- function(id) unname(ifelse(id %in% names(bib_of), bib_of[id], NA_character_))
  Doi <- function(id) if (length(doi_of) == 0) rep(NA_character_, length(id)) else unname(ifelse(id %in% names(doi_of), doi_of[id], NA_character_))
  cls_of  <- setNames(classes$class, classes$source_label)
  type_of <- setNames(classes$default_provenance_type, classes$source_label)
  eq_of   <- setNames(classes$equation_bibcite, classes$source_label)
  labels  <- classes$source_label
  IntermediateLabel <- function(cite_id, bibcite, doi)
    MatchIntermediateLabel(cite_id, bibcite, doi, labels, Bib(labels), Doi(labels))
  Row <- function(g, type, n, ref_role = NA_character_, primary_cite_id = NA_character_, primary_bibcite = NA_character_,
                  primary_doi = NA_character_, match_status = NA_character_, hop = NULL, via = NA_character_) {
    data.frame(genus = g$genus, species = g$species, taxon = g$taxon, source_mass = g$source_label,
               source_bibcite = Bib(g$source_label), origin = g$origin,
               hop = if (is.null(hop)) unname(provenance_type_hop[type]) else hop, via_cite_id = via,
               ref_role = ref_role, provenance_type = type, primary_cite_id = primary_cite_id,
               primary_bibcite = primary_bibcite, primary_doi = primary_doi, match_status = match_status,
               n_records = as.integer(n), stringsAsFactors = FALSE)
  }
  out <- list()
  # the lab Sheet: measured in the cited source, hop 0
  sheet <- rec[rec$origin == 'BM_data', , drop = FALSE]
  if (nrow(sheet) > 0) {
    k <- paste(sheet$genus, sheet$species, sheet$source_label, sep = '\r')
    g <- sheet[!duplicated(k), c('genus', 'species', 'taxon', 'source_label', 'origin')]
    out$sheet <- Row(g, 'measured_in_source', as.integer(table(k)[k[!duplicated(k)]]))
  }
  pipe <- rec[rec$origin != 'BM_data', , drop = FALSE]
  if (nrow(pipe) > 0) {
    grp <- paste(pipe$genus, pipe$species, pipe$source_label, sep = '\r')
    # (a) records with native keys
    has <- !is.na(pipe$ref_keys)
    if (any(has)) {
      ex <- ExplodeRefKeys(pipe$ref_keys[has])
      idx <- which(has)[ex$record]
      long <- data.frame(grp = grp[idx], genus = pipe$genus[idx], species = pipe$species[idx], taxon = pipe$taxon[idx],
                         source_label = pipe$source_label[idx], origin = pipe$origin[idx], prov_type = pipe$prov_type[idx],
                         native_key = ex$native_key, stringsAsFactors = FALSE)
      lk <- paste(long$grp, long$native_key, long$prov_type, sep = '\r')
      g  <- long[!duplicated(lk), , drop = FALSE]
      n  <- as.integer(table(lk)[lk[!duplicated(lk)]])
      pi <- match(paste(g$source_label, g$native_key), paste(prim$source_label, prim$native_key))
      role   <- prim$role[pi]
      type   <- unname(role_provenance_type[role])
      type[is.na(pi)] <- 'unknown'
      ov <- !is.na(g$prov_type) & g$prov_type %in% provenance_types
      type[ov] <- g$prov_type[ov]
      # a derived source (registry default derived_allometry; Meiri_2018): its
      # measurement references are the length sources of the computed value,
      # so their rows are derived_allometry too, and the equation row is
      # written beside them (below); a self reference (the compiler's own
      # length measurements) is derived_allometry citing the source itself. A
      # pending or unmatched key keeps the generic treatment (no primary
      # citation; 'unknown' for an unmatched key).
      derived <- unname(type_of[g$source_label]) %in% 'derived_allometry' & role %in% c('measurement', 'self') & !ov
      type[derived] <- 'derived_allometry'
      status <- prim$match_status[pi]
      status[is.na(pi)] <- ifelse(g$source_label[is.na(pi)] %in% prim$source_label, 'unmatched_key', 'uningested')
      resolved <- !is.na(pi) & prim$match_status[pi] %in% c('certain', 'approved', 'nodoi_approved')
      keyed <- Row(g, type, n, ref_role = role,
                   primary_cite_id = ifelse(resolved, prim$cite_id[pi], NA_character_),
                   primary_bibcite = ifelse(resolved, prim$bibcite[pi], NA_character_),
                   primary_doi     = ifelse(resolved, prim$doi[pi], NA_character_),
                   match_status = status)
      # a self reference is the source itself
      self <- !is.na(pi) & prim$role[pi] %in% 'self'
      if (any(self)) {
        keyed$primary_cite_id[self] <- g$source_label[self]
        keyed$primary_bibcite[self] <- Bib(g$source_label[self])
        keyed$primary_doi[self]     <- Doi(g$source_label[self])
        keyed$match_status[self]    <- 'self'
      }
      # hop 2 (issue #1, 1.3): a resolved reference that is itself a source
      # label of the database (matched by CiteID, bib key or DOI; Herberstein
      # -> Chown_etal_2007) is an intermediate compilation. Where the
      # intermediate's own records of the same species resolve to primary
      # references, the record is attributed through it: one row per such
      # reference, hop 2, compiled_via_compilation, via_cite_id the
      # intermediate's CiteID, primary_* the intermediate's reference (no third
      # hop: a reference of the intermediate that is itself a label stays as it
      # is). An intermediate record that is its own measurement (role self)
      # gives compiled_from citing the intermediate at hop 1. Without a
      # resolved intermediate reference for the species (the intermediate has
      # no primary_references.csv yet, or its record is keyless or pending) the
      # intermediate is the terminal citation: compilation_terminal at hop 1
      # (owner decision 2026-10-04); such rows turn into hop-2 rows by
      # themselves once the intermediate is ingested. A record-level prov_type
      # override is left alone.
      inter <- IntermediateLabel(ifelse(resolved, prim$cite_id[pi], NA), ifelse(resolved, prim$bibcite[pi], NA),
                                 ifelse(resolved, prim$doi[pi], NA))
      inter[!is.na(inter) & (inter == g$source_label | ov | derived)] <- NA_character_
      h2 <- which(!is.na(inter))
      if (length(h2) > 0) {
        il <- IntermediateReferences(pipe, prim, unique(inter[h2]))
        cand <- data.frame(k = h2, genus = g$genus[h2], species = g$species[h2], inter = inter[h2], stringsAsFactors = FALSE)
        m <- merge(cand, il, by.x = c('genus', 'species', 'inter'), by.y = c('genus', 'species', 'label'), all.x = TRUE, sort = FALSE)
        found <- !is.na(m$i_status)
        i_self <- found & m$i_role %in% 'self'
        via_type <- ifelse(!found, 'compilation_terminal', ifelse(i_self, 'compiled_from', 'compiled_via_compilation'))
        gm <- g[m$k, , drop = FALSE]
        hop2 <- Row(gm, via_type, n[m$k],
                    ref_role = ifelse(!found, 'compilation', ifelse(i_self, 'measurement', m$i_role)),
                    primary_cite_id = ifelse(found & !i_self, m$i_cite_id, m$inter),
                    primary_bibcite = ifelse(found & !i_self, m$i_bibcite, Bib(m$inter)),
                    primary_doi     = ifelse(found & !i_self, m$i_doi, Doi(m$inter)),
                    match_status    = ifelse(found & !i_self, m$i_status, keyed$match_status[m$k]),
                    via = ifelse(found & !i_self, m$inter, NA_character_))
        keyed <- rbind(keyed[-h2, , drop = FALSE], hop2)
      }
      out$keyed <- keyed
      # the equation row of a derived source's keyed records (issue #1, Stage
      # 2): one row per species x label beside the measurement rows, role
      # equation, the registry's equation_bibcite, counting the records; a
      # record with a prov_type override gets none (as in (b))
      eqk <- unname(eq_of[pipe$source_label[has]])
      is_eqk <- unname(type_of[pipe$source_label[has]]) %in% 'derived_allometry' & !is.na(eqk) &
        !(!is.na(pipe$prov_type[has]) & pipe$prov_type[has] %in% provenance_types)
      if (any(is_eqk)) {
        kg <- grp[has][is_eqk]
        ge <- pipe[which(has)[is_eqk][!duplicated(kg)], c('genus', 'species', 'taxon', 'source_label', 'origin')]
        ne <- as.integer(table(kg)[kg[!duplicated(kg)]])
        eqb <- eqk[is_eqk][!duplicated(kg)]
        out$equation <- Row(ge, 'derived_allometry', ne, ref_role = 'equation',
                            primary_cite_id = unname(ifelse(eqb %in% names(cite_of_bib), cite_of_bib[eqb], NA_character_)),
                            primary_bibcite = eqb)
      }
    }
    # (b) records without a key: the registry's default for the label's class
    none <- pipe[!has, , drop = FALSE]
    if (nrow(none) > 0) {
      nk <- paste(grp[!has], none$prov_type, sep = '\r')
      g  <- none[!duplicated(nk), c('genus', 'species', 'taxon', 'source_label', 'origin', 'prov_type')]
      n  <- as.integer(table(nk)[nk[!duplicated(nk)]])
      type <- unname(type_of[g$source_label]); type[is.na(type)] <- 'unknown'
      ov <- !is.na(g$prov_type) & g$prov_type %in% provenance_types
      type[ov] <- g$prov_type[ov]
      eq <- unname(eq_of[g$source_label])
      is_eq <- type == 'derived_allometry' & !is.na(eq)
      primary_bib <- ifelse(is_eq, eq, NA_character_)
      primary_cite <- unname(ifelse(is_eq & eq %in% names(cite_of_bib), cite_of_bib[eq], NA_character_))
      self_type <- type == 'measured_in_source'
      out$default <- Row(g, type, n, ref_role = ifelse(is_eq, 'equation', ifelse(self_type, 'self', NA_character_)),
                         primary_cite_id = ifelse(self_type, g$source_label, primary_cite),
                         primary_bibcite = ifelse(self_type, Bib(g$source_label), primary_bib),
                         primary_doi     = ifelse(self_type, Doi(g$source_label), NA_character_),
                         match_status    = ifelse(self_type, 'self', NA_character_))
    }
    # (c) conversion factors: one row per CiteID appended to source_mass
    hc <- !is.na(pipe$conversion_ids)
    if (any(hc)) {
      cx <- ExplodeRefKeys(pipe$conversion_ids[hc])
      idx <- which(hc)[cx$record]
      ck <- paste(grp[idx], cx$native_key, sep = '\r')
      g  <- pipe[idx[!duplicated(ck)], c('genus', 'species', 'taxon', 'source_label', 'origin')]
      n  <- as.integer(table(ck)[ck[!duplicated(ck)]])
      tok <- cx$native_key[!duplicated(ck)]
      out$conversion <- Row(g, 'conversion_factor', n, ref_role = 'conversion', primary_cite_id = tok,
                            primary_bibcite = Bib(tok), primary_doi = Doi(tok))
    }
  }
  out <- do.call(rbind, out)
  out$record_status <- rep('kept', nrow(out))
  if (!is.null(statuses) && nrow(statuses) > 0) {
    grp <- if (exists('SourceGroup')) SourceGroup(out$source_mass) else out$source_mass
    m <- match(paste(out$genus, out$species, grp, sep = '\r'),
               paste(statuses$genus, statuses$species, statuses$source_group, sep = '\r'))
    hit <- out$origin != 'BM_data' & !is.na(m)
    out$record_status[hit] <- statuses$record_status[m[hit]]
  }
  out <- out[order(out$genus, out$species, out$source_mass, out$origin, out$hop, out$provenance_type,
                   out$primary_cite_id, out$ref_role, method = 'radix'), provenance_columns]
  rownames(out) <- NULL
  out
}

# ---- checks -----------------------------------------------------------------------------------
# `bib`: ReadBibEntries() of both files bound with a `file` column; `citeids`:
# the CiteIDs frame (CiteID, Bibcite); `prim`: LoadPrimaryReferences();
# `sheet_rows`: the BM_primary_citations rows (Bibcite). Returns
# list(problems, coverage, counts).
CheckCitations <- function(provenance, bib, citeids, prim, sheet_bibcites = character()) {
  problems <- character(0)
  pb <- unique(na.omit(provenance$primary_bibcite))
  missing_bib <- setdiff(pb, bib$key)
  if (length(missing_bib) > 0)
    problems <- c(problems, sprintf('%d primary_bibcite key(s) in no bib file: %s', length(missing_bib), paste(missing_bib, collapse = ', ')))
  pc <- unique(na.omit(provenance$primary_cite_id))
  missing_cite <- setdiff(pc, citeids$CiteID)
  if (length(missing_cite) > 0)
    problems <- c(problems, sprintf('%d primary_cite_id(s) without a CiteID row (Sheet tabs / snapshots): %s', length(missing_cite), paste(missing_cite, collapse = ', ')))
  sb <- unique(provenance$source_mass[is.na(provenance$source_bibcite)])
  if (length(sb) > 0)
    problems <- c(problems, sprintf('%d source label(s) without a Bibcite: %s', length(sb), paste(sb, collapse = ', ')))
  acc <- prim[prim$match_status %in% c('certain', 'approved'), , drop = FALSE]
  bad <- acc[is.na(acc$doi) & !(acc$match_reason %in% 'manual_bib'), , drop = FALSE]
  if (nrow(bad) > 0)
    problems <- c(problems, sprintf('%d certain/approved reference(s) without a DOI: %s', nrow(bad), paste(bad$source_label, bad$native_key, collapse = ', ')))
  ok_rows <- prim[prim$match_status %in% c('certain', 'approved', 'nodoi_approved'), , drop = FALSE]
  if (nrow(ok_rows) > 0) {
    nb <- ok_rows[is.na(ok_rows$bibcite) | !ok_rows$bibcite %in% bib$key, , drop = FALSE]
    if (nrow(nb) > 0)
      problems <- c(problems, sprintf('%d accepted reference(s) without a bib entry (run --bib): %s', nrow(nb), paste(nb$source_label, nb$native_key, collapse = ', ')))
    if (length(sheet_bibcites) > 0 || nrow(ok_rows) > 0) {
      ns <- ok_rows$bibcite[!is.na(ok_rows$bibcite) & !ok_rows$bibcite %in% sheet_bibcites & !ok_rows$bibcite %in% citeids$Bibcite]
      if (length(ns) > 0)
        problems <- c(problems, sprintf('%d accepted bibcite(s) with no CiteID row yet (run --sheet): %s', length(ns), paste(unique(ns), collapse = ', ')))
    }
  }
  # per-source coverage over the pipeline rows
  pipe <- provenance[provenance$origin != 'BM_data', , drop = FALSE]
  labs <- sort(unique(pipe$source_mass), method = 'radix')
  cov <- do.call(rbind, lapply(labs, function(l) {
    p <- pipe[pipe$source_mass == l & pipe$provenance_type != 'conversion_factor', , drop = FALSE]
    n_rec <- sum(p$n_records)
    resolved <- sum(p$n_records[p$hop >= 1 & !is.na(p$primary_cite_id)])
    pr <- prim[prim$source_label == l, , drop = FALSE]
    data.frame(source_label = l, class = NA_character_, n_species = length(unique(paste(p$genus, p$species))),
               n_record_links = n_rec,
               pct_resolved = if (n_rec > 0) round(100 * resolved / n_rec, 1) else NA_real_,
               refs_total = nrow(pr), refs_resolved = sum(pr$match_status %in% c('certain', 'approved', 'nodoi_approved')),
               refs_pending = sum(pr$match_status %in% 'pending'), refs_not_found = sum(pr$match_status %in% 'not_found'),
               refs_self = sum(pr$match_status %in% 'self'), refs_rejected = sum(pr$match_status %in% 'rejected'),
               refs_unverified = sum(is.na(pr$match_status)),
               unmatched_key_links = sum(p$n_records[p$match_status %in% 'unmatched_key']),
               uningested_links    = sum(p$n_records[p$match_status %in% 'uningested']),
               stringsAsFactors = FALSE)
  }))
  if (is.null(cov)) cov <- data.frame()
  list(problems = problems, coverage = cov,
       counts = c(rows = nrow(provenance), species = length(unique(paste(provenance$genus, provenance$species))),
                  primary_refs = length(pc), unresolved_refs = sum(prim$match_status %in% c('pending', 'not_found')),
                  unverified_refs = sum(is.na(prim$match_status))))
}

WriteCitationsReport <- function(path, checks, classes = NULL, unmapped_sheet = character(),
                                 uncited_labels = character()) {
  cov <- checks$coverage
  if (!is.null(classes) && nrow(cov) > 0) cov$class <- classes$class[match(cov$source_label, classes$source_label)]
  lines <- c(sprintf('# Citation and provenance warnings -- %s', format(Sys.time(), '%Y-%m-%d %H:%M:%S')), '',
             paste('Checks of RunMe.r section 8 (issue #1): bib keys of both files, CiteID rows of both Sheet tabs,',
                   'the accepted primary references and the per-source coverage of TaxonBodyMass_Provenance.csv.gz.'), '',
             '## Totals', '',
             sprintf('- provenance rows: %d (%d species); distinct primary CiteIDs: %d; unresolved references (pending / not_found): %d; unverified references: %d',
                     checks$counts[['rows']], checks$counts[['species']], checks$counts[['primary_refs']],
                     checks$counts[['unresolved_refs']], checks$counts[['unverified_refs']]), '',
             '## Problems', '')
  lines <- c(lines, if (length(checks$problems) == 0) '(none)' else paste0('- ', checks$problems), '',
             '## Sheet rows whose Bibcite is in neither bib file', '',
             if (length(unmapped_sheet) == 0) '(none)' else paste0('- ', unmapped_sheet), '',
             '## Labels in TaxonBodyMass.csv without a CiteID row', '',
             if (length(uncited_labels) == 0) '(none)' else paste0('- ', uncited_labels), '',
             '## Per-source coverage', '',
             'One row per source label: species and record links (species x source x reference rows weighted by records), the share of record links resolved to a primary reference (hop >= 1 with a CiteID), and the reference counts of primary_references.csv by status.', '')
  lines <- c(lines, if (nrow(cov) == 0) '(none)' else MarkdownTable(cov))
  writeLines(lines, path)
  invisible(path)
}
