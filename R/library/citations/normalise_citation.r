# Citation tooling (issue #1): string normalisation, the regex parse of a
# citation string into query fields, and title similarity.
#
# NormaliseCitationString() folds a citation or title to lowercase ASCII words
# (the diacritic and dash treatment of NormaliseSourceLabel(), helpers.r), used
# for hashing in-row citations (parse_reflists.r) and for similarity.
# ParseCitationString() extracts parsed_author1, parsed_year, parsed_title,
# parsed_container, parsed_volume, parsed_pages and an embedded DOI from a
# reference-list entry by regular expressions (author-year styles; through
# ParseNatureStyle() the Nature style and the initials-first PNAS style whose
# year closes the entry). The parsed fields are query
# inputs only: they never reach a bib entry or the Sheet (section F).
# TitleSimilarity() is the mean of the Jaro-Winkler similarity (stringdist) and
# the token-set Jaccard index of the two normalised titles, in [0, 1].
# Everything is offline; stringdist is the only package used.

# ---- folding ----------------------------------------------------------------------
FoldASCII <- function(x) {
  is_na <- is.na(x)
  x <- enc2utf8(as.character(x))
  x <- gsub('\u00a0', ' ', x, fixed = TRUE)
  x <- gsub('[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]', '-', x, perl = TRUE)
  x <- gsub('[\u2018\u2019\u201a\u201b]', "'", x, perl = TRUE)
  x <- gsub('[\u201c\u201d\u201e\u201f]', '"', x, perl = TRUE)
  x <- gsub('\u00f8', 'o', x, fixed = TRUE); x <- gsub('\u00d8', 'O', x, fixed = TRUE)
  x <- gsub('\u00df', 'ss', x, fixed = TRUE)
  x <- gsub('\u00e6', 'ae', x, fixed = TRUE); x <- gsub('\u00c6', 'AE', x, fixed = TRUE)
  x <- gsub('\u0153', 'oe', x, fixed = TRUE); x <- gsub('\u0152', 'OE', x, fixed = TRUE)
  x <- gsub('\u0142', 'l', x, fixed = TRUE);  x <- gsub('\u0141', 'L', x, fixed = TRUE)
  x <- gsub('\u0111', 'd', x, fixed = TRUE);  x <- gsub('\u0110', 'D', x, fixed = TRUE)
  # Only the non-ASCII characters go through iconv's TRANSLIT, one by one, so
  # that the stray accent marks macOS's TRANSLIT emits ("Cervig'on", '?' for an
  # untransliterable character) can be dropped without touching a legitimate
  # '?' or quote of the text ('adaptation or stability?').
  y <- x
  for (i in which(!is_na)) {
    cp <- utf8ToInt(x[i])
    if (!any(cp > 127L)) next
    chars <- strsplit(x[i], '', fixed = TRUE)[[1]]
    non <- cp > 127L
    tr <- iconv(chars[non], from = 'UTF-8', to = 'ASCII//TRANSLIT')
    tr[is.na(tr)] <- ''
    tr <- gsub("[?'`^~\"]", '', tr)
    chars[non] <- tr
    y[i] <- paste(chars, collapse = '')
  }
  y[is_na] <- NA_character_
  y
}

# Lowercase ASCII words separated by single blanks; punctuation removed, LaTeX
# braces and HTML tags dropped. NA stays NA.
NormaliseCitationString <- function(x) {
  is_na <- is.na(x)
  x <- FoldASCII(x)
  x <- gsub('<[^>]+>', ' ', x, perl = TRUE)
  x <- gsub('&amp;', ' and ', x, fixed = TRUE)
  x <- gsub('[{}\\\\]', '', x, perl = TRUE)
  x <- tolower(x)
  x <- gsub('[^a-z0-9]+', ' ', x, perl = TRUE)
  x <- trimws(gsub('\\s+', ' ', x, perl = TRUE))
  x[is_na] <- NA_character_
  x
}

# A short stable key for an in-row citation: 'h:' and the first eight hex digits
# of the sha1 of the normalised string (issue #1, 1.1).
CitationHashKey <- function(x) {
  n <- NormaliseCitationString(x)
  vapply(n, function(s) if (is.na(s)) NA_character_ else
    paste0('h:', substr(digest::digest(s, algo = 'sha1', serialize = FALSE), 1, 8)), character(1),
    USE.NAMES = FALSE)
}

# A DOI embedded in free text (with or without the resolver prefix), lowercase,
# trailing punctuation removed; NA when none. Parentheses are part of many
# older DOIs ('10.1016/0300-9629(77)90123-4'), so a closing bracket is only
# dropped when the DOI has no opening one for it (the citation's own bracket);
# angle brackets belong to SICI DOIs ('10.1644/1545-1542(2000)081<0578:TBAMOT>2.0.CO;2'),
# so the match stops only at whitespace, a quote or a square bracket.
ExtractDOI <- function(x) {
  x <- as.character(x)
  pos <- regexpr('10\\.[0-9]{4,9}/[^\\s"\\]]+', x, perl = TRUE)
  out <- rep(NA_character_, length(x))
  hit <- !is.na(pos) & pos > 0
  if (any(hit)) out[hit] <- substring(x[hit], pos[hit], pos[hit] + attr(pos, 'match.length')[hit] - 1L)
  repeat {
    out <- sub('[.,;:]+$', '', out)
    unbalanced <- !is.na(out) & grepl('\\)$', out) &
      nchar(gsub('[^(]', '', out)) < nchar(gsub('[^)]', '', out))
    if (!any(unbalanced)) break
    out[unbalanced] <- sub('\\)$', '', out[unbalanced])
  }
  tolower(out)
}

# A DOI as a bare, lowercase identifier ('https://doi.org/' and 'doi:' removed).
CleanDOI <- function(x) {
  x <- trimws(as.character(x))
  x <- sub('^(https?://)?(dx\\.)?doi\\.org/', '', x, ignore.case = TRUE)
  x <- sub('^doi:\\s*', '', x, ignore.case = TRUE)
  x <- sub('[.,;:]+$', '', x)
  x[!is.na(x) & !nzchar(x)] <- NA_character_
  tolower(x)
}

# ---- the regex parse ----------------------------------------------------------------
year_regex <- '\\b(1[6-9][0-9]{2}|20[0-9]{2})[a-z]?\\b'

# The author block of a reference-list entry: the text before the first year
# marker ("Doyle, T. K., ... 2007." or "Doyle TK et al. (2007)"), without the
# trailing punctuation. NA when the entry carries no year.
AuthorBlock <- function(x) {
  pos <- regexpr(year_regex, x, perl = TRUE)
  out <- ifelse(pos > 0, substr(x, 1, pos - 1), NA_character_)
  out <- sub('[\\s.,;:(\\[]+$', '', out, perl = TRUE)
  out[!is.na(out) & !nzchar(out)] <- NA_character_
  out
}

# The first author's surname from an author block: "Falk-Petersen, S." ->
# "Falk-Petersen"; "Doyle TK, Houghton JDR" -> "Doyle"; "van der Meer J" ->
# "van der Meer"; "ARUDPRAGASAM, K. D., AND E." -> "Arudpragasam".
FirstSurname <- function(block) {
  block <- trimws(as.character(block))
  block <- sub('^(and|&)\\s+', '', block, ignore.case = TRUE)
  out <- rep(NA_character_, length(block))
  for (i in seq_along(block)) {
    b <- block[i]
    if (is.na(b) || !nzchar(b)) next
    s <- if (grepl(',', b, fixed = TRUE)) sub(',.*$', '', b) else b
    # 'Doyle TK' / 'Doyle T.K.' (surname followed by initials) -> the surname tokens
    toks <- strsplit(trimws(s), '\\s+', perl = TRUE)[[1]]
    is_init <- grepl('^([A-Z]\\.?[-]?){1,3}$', toks) | grepl('^(and|&|et|al\\.?)$', toks, ignore.case = TRUE)
    keep <- toks[!is_init]
    if (length(keep) == 0) keep <- toks[1]
    # particles (van, von, de, della) stay with the surname; otherwise the first run of tokens
    s <- paste(keep, collapse = ' ')
    s <- gsub('[^A-Za-z\u00c0-\u024f\u1e00-\u1eff\'’ -]', '', s)
    s <- trimws(s)
    if (s == toupper(s) && nchar(s) > 1)         # ALL CAPS entries
      s <- paste(sapply(strsplit(s, ' ')[[1]], function(w) paste0(substr(w, 1, 1), tolower(substring(w, 2)))), collapse = ' ')
    out[i] <- if (nzchar(s)) s else NA_character_
  }
  out
}

# Split the text that follows the year into title, container, volume and pages.
# A sentence boundary is a period preceded by at least two word characters or a
# closing bracket (so that initials and 'I.' / 'II.' do not split) and followed
# by blank(s) and an upper-case letter or a digit; 'T. raschii (M. Sars)' and 'winter-I. Furcilia'
# stay inside the title, '1983-1984. Polar Biol.' splits. The volume/pages
# pattern is searched at the end ("343: 239-252", "45(3), 123-145", "22: 1-97",
# "202 (20): 2739-2748", "pp. 1-97") and removed before the split.
SplitBody <- function(body) {
  body <- trimws(body)
  volume <- pages <- NA_character_
  # volume(issue): pages / volume, pages / volume: page
  vp <- regexpr('(\\d+)\\s*(\\([^)]*\\))?\\s*[,:]\\s*(pp?\\.\\s*)?(e?\\d+[A-Za-z]?)(\\s*[-]+\\s*(e?\\d+[A-Za-z]?))?\\.?\\s*$', body, perl = TRUE)
  if (vp > 0) {
    m <- regmatches(body, vp)
    parts <- regmatches(m, regexec('(\\d+)\\s*(\\([^)]*\\))?\\s*[,:]\\s*(pp?\\.\\s*)?(e?\\d+[A-Za-z]?)(\\s*[-]+\\s*(e?\\d+[A-Za-z]?))?', m, perl = TRUE))[[1]]
    volume <- parts[2]
    pages  <- if (nzchar(parts[7])) paste0(parts[5], '-', parts[7]) else parts[5]
    body   <- trimws(substr(body, 1, vp - 1))
    body   <- sub('[,;:]\\s*$', '', body)
  } else {
    # pages only: 'pp. 12-34' / '123 pp.' / 'p. 7'
    pp <- regexpr('\\b(pp?\\.\\s*(\\d+)(\\s*[-]+\\s*(\\d+))?|(\\d+)\\s*pp?\\.)\\s*$', body, perl = TRUE)
    if (pp > 0) {
      m <- regmatches(body, pp)
      d <- regmatches(m, gregexpr('\\d+', m))[[1]]
      if (length(d) >= 1 && !grepl('^\\d+\\s*pp?\\.', m)) pages <- paste(d, collapse = '-')
      body <- trimws(substr(body, 1, pp - 1))
      body <- sub('[,;:.]\\s*$', '', body)
    }
  }
  # the first sentence boundary separates title and container
  sb <- regexpr('(?<=\\w\\w|\\)|\\])[.?!]\\s+(?=[A-Z0-9(])', body, perl = TRUE)
  if (sb > 0) {
    title     <- trimws(substr(body, 1, sb - 1))
    container <- trimws(substr(body, sb + 1, nchar(body)))
    # a title ending in '?' or '!' keeps its mark
    if (substr(body, sb, sb) %in% c('?', '!')) title <- paste0(title, substr(body, sb, sb))
  } else {
    title <- body; container <- NA_character_
  }
  container <- sub('[.,;:]+\\s*$', '', container)
  # 'In: Editor (ed.) Book title. Publisher' and 'Journal 12' leftovers
  container <- sub('^(In|in):?\\s+', '', container)
  if (!is.na(container) && !nzchar(container)) container <- NA_character_
  title <- sub('[.,;:]+$', '', title)
  if (!nzchar(title)) title <- NA_character_
  list(title = title, container = container, volume = volume, pages = pages)
}

# The Nature reference style, "May, M. L. Energy metabolism of dragonflies
# (Odonata: Anisoptera) at rest and during endothermic warm-up. Journal of
# Experimental Biology 83, 79-94 (1979).": the entry ends with "volume, pages
# (year)" and the author block is a run of "Surname, I. I." items joined by
# commas and '&' / 'and'; the pages may be absent ("Experimental Biology
# Online 3 (1998)."). The PNAS / Science style writes the same tail after an
# initials-first author block, "A. M. Makarieva et al., Title. Proc. Natl.
# Acad. Sci. U.S.A. 105, 16994-16999 (2008)." (Hoehler_etal_2023; #114 item
# 2): items "I. I. Surname" (particles 'de', 'van' allowed, 'et al.,' closing
# the block) separated by commas, the title following the last comma; the
# volume may be glued to the journal ("Science206, 649-654 (1979)"). Returns
# NULL when the string does not end that way or opens with neither block;
# otherwise the fields, with the title and the container separated by
# SplitTitleContainer() at the last sentence boundary of the text between the
# authors and the volume, the container extended backwards over an
# abbreviated journal name ("Proc. Natl. Acad. Sci. U.S.A.").
nature_author_block <- '^(?:[A-Z][^,.]*?,\\s(?:[A-Z]\\.-?\\s?)+(?:,\\s|&\\s|and\\s|et al\\.\\s)?)+'
initials_first_item  <- "(?:[A-Z]\\.(?:-[A-Z]\\.)?\\s?)+(?:(?:de|da|del|der|den|di|du|la|le|van|von|y)\\s)*[A-Z][A-Za-z'’-]+(?:\\s[A-Z][A-Za-z'’-]+)?"
initials_first_block <- paste0('^(?:', initials_first_item, '(?:,\\s(?:and\\s|&\\s)?|\\s(?:and|&)\\s|\\set al\\.,\\s))+')
ParseNatureStyle <- function(s) {
  tail_re <- '(?:\\s|(?<=[A-Za-z.]))(\\d+[A-Za-z]?)\\s*(\\([^)]*\\))?(?:,\\s*(e?\\d+[A-Za-z]?)(\\s*[-]+\\s*(e?\\d+[A-Za-z]?))?)?\\s*\\(((1[6-9]|20)\\d{2})[a-z]?\\)\\.?\\s*$'
  tp <- regexpr(tail_re, s, perl = TRUE)
  if (tp <= 0) return(NULL)
  m <- regmatches(s, regexec(tail_re, s, perl = TRUE))[[1]]
  head <- trimws(substr(s, 1, tp - 1))
  # the author block: "Surname, I. I.[, Surname, I.][ & Surname, I.]" or
  # "I. I. Surname, I. Surname, " / "I. I. Surname et al., "
  ab <- regexpr(nature_author_block, head, perl = TRUE)
  if (ab <= 0) ab <- regexpr(initials_first_block, head, perl = TRUE)
  if (ab <= 0) return(NULL)
  authors <- trimws(regmatches(head, ab))
  body <- trimws(substr(head, ab + attr(ab, 'match.length'), nchar(head)))
  if (!nzchar(body)) return(NULL)
  tc <- SplitTitleContainer(body)
  list(tail_start = tp, year = as.integer(m[7]), author1 = FirstSurname(sub('\\s*(,|et al\\.,?)\\s*$', '', authors, perl = TRUE)),
       title = tc$title, container = tc$container,
       volume = m[2], pages = if (nzchar(m[6])) paste0(m[4], '-', m[6]) else if (nzchar(m[4])) m[4] else NA_character_)
}

# Title and container of the text between an author block and the volume
# ("Title. Journal", Nature and PNAS styles): the container starts at the last
# sentence boundary ('.', '?.' or '!.' before a blank and a capital or digit)
# and is extended backwards over the sentences before it that read as parts
# of an abbreviated journal name -- a capitalised word or dotted abbreviation
# of one to fifteen letters, or several such tokens each ending in a period
# but the last ("Proc. Natl. Acad. Sci. U.S.A.", "Ann. N.Y. Acad. Sci.") --
# so that the journal keeps all its tokens. A title ending in '?' or '!' keeps
# its mark. Returns list(title, container), NA when absent.
SplitTitleContainer <- function(body) {
  body <- trimws(body)
  sb <- gregexpr('(?<=\\w\\w|\\)|\\])(?:[.?!]|[?!]\\.)\\s+(?=[A-Z0-9(])', body, perl = TRUE)[[1]]
  if (sb[1] <= 0) {
    title <- sub('[.,;:]+$', '', body)
    return(list(title = if (nzchar(title)) title else NA_character_, container = NA_character_))
  }
  lens <- attr(sb, 'match.length')
  JournalLike <- function(x) {
    toks <- strsplit(trimws(x), '\\s+', perl = TRUE)[[1]]
    if (length(toks) == 0 || length(toks) > 6) return(FALSE)
    word <- grepl("^[A-Z][A-Za-z]{0,14}$", toks, perl = TRUE) | grepl('^(?:[A-Z]\\.)+[A-Z]?$', toks, perl = TRUE)
    dotted <- grepl('\\.$', toks)
    all(word) && all(dotted[-length(toks)])
  }
  k <- length(sb)
  # sentences before the last boundary: the one ending at boundary j spans (end of j-1, start of j)
  while (k > 1) {
    prev_end <- sb[k - 1] + lens[k - 1]
    sentence <- substr(body, prev_end, sb[k] - 1)
    if (substr(body, sb[k], sb[k]) != '.' || !JournalLike(sentence)) break
    k <- k - 1
  }
  cut <- sb[k]
  title <- trimws(substr(body, 1, cut - 1))
  mark <- substr(body, cut, cut)
  if (mark %in% c('?', '!')) title <- paste0(title, mark)
  container <- trimws(substr(body, cut + lens[k], nchar(body)))
  title <- sub('[.,;:]+$', '', title)
  container <- sub('[.,;:]+\\s*$', '', container)
  list(title = if (nzchar(title)) title else NA_character_, container = if (nzchar(container)) container else NA_character_)
}

# The author block and the body of an entry whose year closes it in brackets
# (the Nature / Scientific Data reference style, "Authors. Title. Container
# vol(issue), pages, (year)."; ReptTraits, Oskyrko_2024): there is no year
# marker between the authors and the title, so the author block ends at the
# first capitalised word of the title, the first token that carries no comma,
# is not an initial ('J.', 'J.-P.', 'B.,'), a connector ('and', '&', 'et',
# 'al.') or a name particle, and is not followed by an initial (a given name
# written out, 'Christine P. B.', is followed by one). NA body when no such
# token is found.
author_connectors <- c('and', '&', 'et', 'al.', 'al', 'de', 'da', 'del', 'der', 'den', 'di',
                       'du', 'la', 'le', 'van', 'von', 'y', 'jr.', 'jr.,', 'jr', 'sr.', '(eds.)',
                       '(ed.)', 'eds.', 'ed.')
SplitAuthorsFromTitle <- function(head) {
  toks <- strsplit(trimws(head), '\\s+', perl = TRUE)[[1]]
  # dotted initials ('J.', 'J.-P.', 'J.B.,'), bare capitals with a comma ('P,',
  # 'TK,') or two to three bare capitals ('TK'); a lone 'A' is a title word
  is_initial <- grepl('^([A-Z]\\.-?){1,3}[A-Z]?,?$|^[A-Z]{1,3},$|^[A-Z]{2,3}$', toks, perl = TRUE)
  is_conn    <- tolower(toks) %in% author_connectors
  has_comma  <- grepl(',$', toks)
  is_cap     <- grepl('^["\'(]?[A-Z0-9]', toks, perl = TRUE)
  start <- NA_integer_
  for (j in seq_along(toks)) {
    if (!is_cap[j] || has_comma[j] || is_initial[j] || is_conn[j]) next
    if (j < length(toks) && is_initial[j + 1]) next
    start <- j; break
  }
  if (is.na(start) || start == 1L)
    return(list(authors = head, body = NA_character_))
  list(authors = sub('[\\s.,;:]+$', '', paste(toks[seq_len(start - 1L)], collapse = ' '), perl = TRUE),
       body    = paste(toks[start:length(toks)], collapse = ' '))
}

# Parse one citation string per element into a data frame of query fields:
# parsed_author1, parsed_year, parsed_title, parsed_container, parsed_volume,
# parsed_pages, parsed_doi. Robust to the common styles ("Author, A. B., and
# C. D. Other. 2007. Title. Journal 12: 1-10.", "Author AB, Other CD (2007)
# Title. Journal 12:1-10", "Author, A. (2007). Title. Journal, 12(3), 1-10.
# doi:10...."). Fields that cannot be found are NA; nothing here is an error.
ParseCitationString <- function(x) {
  x <- as.character(x)
  n <- length(x)
  out <- data.frame(parsed_author1 = rep(NA_character_, n), parsed_year = rep(NA_integer_, n),
                    parsed_title = NA_character_, parsed_container = NA_character_,
                    parsed_volume = NA_character_, parsed_pages = NA_character_,
                    parsed_doi = NA_character_, stringsAsFactors = FALSE)
  for (i in seq_len(n)) {
    s <- x[i]
    if (is.na(s) || !nzchar(trimws(s))) next
    s <- gsub('\\s+', ' ', trimws(FoldASCII(s)), perl = TRUE)
    out$parsed_doi[i] <- ExtractDOI(s)
    # remove a DOI / URL tail so it does not pollute pages or container
    s <- sub('\\s*(doi:?\\s*|https?://(dx\\.)?doi\\.org/)10\\.[0-9]{4,9}/\\S+\\s*$', '', s, ignore.case = TRUE, perl = TRUE)
    s <- sub('\\s*https?://\\S+\\s*$', '', s, perl = TRUE)
    pos <- regexpr(year_regex, s, perl = TRUE)
    nat <- ParseNatureStyle(s)
    if (!is.null(nat)) {
      # "Authors. Title. Journal volume, pages (year)." (Nature style): the year
      # stands at the end, so the generic path below would read everything
      # before it as the author block (or stop at a year inside the title,
      # "Atta sexdens rubropilosa (Forel, 1908)")
      out$parsed_year[i]      <- nat$year
      out$parsed_author1[i]   <- nat$author1
      out$parsed_title[i]     <- nat$title
      out$parsed_container[i] <- nat$container
      out$parsed_volume[i]    <- nat$volume
      out$parsed_pages[i]     <- nat$pages
      next
    }
    # a bracketed year closing the entry with a comma before it or no volume
    # ("71 (12), 2448-61, (1993).", "University of Chicago Press, (2018).":
    # the Scientific Data style of ReptTraits, Oskyrko_2024), which
    # ParseNatureStyle() does not cover
    tail <- regexpr('\\(\\s*(1[6-9][0-9]{2}|20[0-9]{2})[a-z]?\\s*\\)\\s*[.,;:]?\\s*$', s, perl = TRUE)
    if (tail > 0) {
      # the year closes the entry in brackets (Nature / Scientific Data style):
      # a year earlier in the string is part of the title or the volume
      ym <- regmatches(s, tail)
      out$parsed_year[i] <- as.integer(regmatches(ym, regexpr('[0-9]{4}', ym)))
      head <- sub('[\\s,;:]+$', '', trimws(substr(s, 1, tail - 1)), perl = TRUE)
      split <- SplitAuthorsFromTitle(head)
      out$parsed_author1[i] <- FirstSurname(split$authors)
      rest <- if (is.na(split$body)) '' else split$body
    } else if (pos > 0) {
      ym <- regmatches(s, pos)
      out$parsed_year[i]    <- as.integer(substr(ym, 1, 4))
      out$parsed_author1[i] <- FirstSurname(AuthorBlock(s))
      rest <- substr(s, pos + attr(pos, 'match.length'), nchar(s))
      rest <- sub('^\\s*[)\\].:,;]*\\s*', '', rest, perl = TRUE)   # ') . ' after the year
    } else {
      rest <- s
      out$parsed_author1[i] <- FirstSurname(sub('[.:].*$', '', s))
      # an undated entry in the Nature style ("Klok, C. J. & Chown, S. L. Title.
      # Journal (in press).") still opens with the author block
      ab <- regexpr(nature_author_block, s, perl = TRUE)
      if (ab > 0 && attr(ab, 'match.length') < nchar(s)) {
        out$parsed_author1[i] <- FirstSurname(regmatches(s, ab))
        rest <- trimws(substr(s, ab + attr(ab, 'match.length'), nchar(s)))
      }
    }
    sp <- SplitBody(rest)
    out$parsed_title[i]     <- sp$title
    out$parsed_container[i] <- sp$container
    out$parsed_volume[i]    <- sp$volume
    out$parsed_pages[i]     <- sp$pages
  }
  out
}

# ---- similarity ---------------------------------------------------------------------
title_stopwords <- c('the', 'of', 'and', 'in', 'a', 'an', 'on', 'for', 'to', 'from', 'with',
                     'by', 'at', 'its', 'their', 'de', 'la', 'le', 'des', 'der', 'die', 'und')

TitleTokens <- function(x) {
  n <- NormaliseCitationString(x)
  if (length(n) == 0 || is.na(n) || !nzchar(n)) return(character(0))
  t <- strsplit(n, ' ', fixed = TRUE)[[1]]
  t <- t[nzchar(t) & !t %in% title_stopwords]
  unique(t)
}

# Mean of the Jaro-Winkler similarity and the token-set Jaccard index of two
# normalised titles; 0 when either is missing. Vectorised over `b` (candidate
# titles) for one `a`, or elementwise when both have the same length.
TitleSimilarity <- function(a, b) {
  if (length(a) == 1L && length(b) > 1L) a <- rep(a, length(b))
  stopifnot(length(a) == length(b))
  na <- NormaliseCitationString(a); nb <- NormaliseCitationString(b)
  out <- numeric(length(a))
  for (i in seq_along(a)) {
    if (is.na(na[i]) || is.na(nb[i]) || !nzchar(na[i]) || !nzchar(nb[i])) { out[i] <- 0; next }
    jw <- 1 - stringdist::stringdist(na[i], nb[i], method = 'jw', p = 0.1)
    ta <- TitleTokens(a[i]); tb <- TitleTokens(b[i])
    jac <- if (length(union(ta, tb)) == 0) 0 else length(intersect(ta, tb)) / length(union(ta, tb))
    out[i] <- round((jw + jac) / 2, 4)
  }
  out
}

# Surnames compared folded; a particle-less surname may be contained in the
# other ('Meer' in 'van der Meer') when at least four characters long.
AuthorMatch <- function(a, b) {
  fa <- NormaliseCitationString(a); fb <- NormaliseCitationString(b)
  if (is.na(fa) || is.na(fb) || !nzchar(fa) || !nzchar(fb)) return(FALSE)
  if (fa == fb) return(TRUE)
  fa2 <- gsub(' ', '', fa); fb2 <- gsub(' ', '', fb)
  if (fa2 == fb2) return(TRUE)
  short <- if (nchar(fa2) <= nchar(fb2)) fa2 else fb2
  long  <- if (nchar(fa2) <= nchar(fb2)) fb2 else fa2
  nchar(short) >= 4 && grepl(short, long, fixed = TRUE)
}

# Journal names compared abbreviation-aware: every token of the shorter name
# (stopwords removed) must be a prefix of a token of the longer one, in order
# ('J. Exp. Mar. Biol. Ecol.' matches 'Journal of Experimental Marine Biology
# and Ecology'; 'Limnol. Oceanogr.' matches 'Limnology and Oceanography').
ContainerMatch <- function(a, b) {
  ta <- TitleTokens(a); tb <- TitleTokens(b)
  if (length(ta) == 0 || length(tb) == 0) return(FALSE)
  short <- if (length(ta) <= length(tb)) ta else tb
  long  <- if (length(ta) <= length(tb)) tb else ta
  j <- 1L
  for (s in short) {
    found <- FALSE
    while (j <= length(long)) {
      if (startsWith(long[j], s) || startsWith(s, long[j])) { found <- TRUE; j <- j + 1L; break }
      j <- j + 1L
    }
    if (!found) return(FALSE)
  }
  TRUE
}

VolumeMatch <- function(a, b) {
  da <- gsub('\\D', '', as.character(a)); db <- gsub('\\D', '', as.character(b))
  !is.na(a) && !is.na(b) && nzchar(da) && nzchar(db) && da == db
}

# First pages compared ('239-252' vs '239' or '239-252'; 'e12345' article numbers as given).
PagesMatch <- function(a, b) {
  fa <- sub('\\s*[-].*$', '', tolower(trimws(as.character(a))))
  fb <- sub('\\s*[-].*$', '', tolower(trimws(as.character(b))))
  !is.na(a) && !is.na(b) && nzchar(fa) && nzchar(fb) && sub('^0+', '', fa) == sub('^0+', '', fb)
}
