# Citation tooling (issue #1): CiteIDs, the labels of the Sheet tabs that map
# to bib keys ('Doyle_2007', 'Martinez-Palacios_1992').
#
#   CiteIDFor(surname, year, doi, bibcite, known)   'Surname_YYYY' with suffixes b, c, ...;
#                                                   reused when the DOI or the Bibcite already
#                                                   has a CiteID; never '_etal_'
# `known` is a data frame with CiteID, Bibcite and (optionally) doi: the union
# of Bib/TaxonBodyMass_CitationCiteIDs.csv and the rows about to be added.
# Offline.

FoldSurnameForCiteID <- function(surname) {
  s <- FoldASCII(trimws(surname))
  s <- gsub('[^A-Za-z0-9-]', '', s)      # blanks and apostrophes removed, hyphens kept
  s
}

CiteIDFor <- function(surname, year, doi = NA_character_, bibcite = NA_character_, known = NULL) {
  if (!is.null(known) && nrow(known) > 0) {
    if (!is.na(bibcite)) {
      hit <- known$CiteID[!is.na(known$Bibcite) & known$Bibcite == bibcite & !is.na(known$CiteID)]
      if (length(hit) > 0) return(hit[1])
    }
    doi <- CleanDOI(doi)
    if (!is.na(doi) && 'doi' %in% names(known)) {
      hit <- known$CiteID[!is.na(known$doi) & CleanDOI(known$doi) == doi & !is.na(known$CiteID)]
      if (length(hit) > 0) return(hit[1])
    }
  }
  base <- FoldSurnameForCiteID(surname)
  if (is.na(base) || !nzchar(base)) base <- 'Anon'
  year <- if (is.na(year)) 'nd' else as.character(year)
  taken <- if (is.null(known)) character() else known$CiteID
  for (suf in c('', letters[-1])) {
    id <- paste0(base, '_', year, suf)
    if (!id %in% taken) return(id)
  }
  stop('CiteIDFor(): no free suffix for ', base, '_', year, call. = FALSE)
}
