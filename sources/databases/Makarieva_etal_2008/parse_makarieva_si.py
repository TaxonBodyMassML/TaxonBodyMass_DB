#!/usr/bin/env python3
"""Reference lists and record-level source marks of the Makarieva et al. (2008)
PNAS Supporting Information (pnas08SI.pdf, 212 pages; issue #1, Stage 2).

The SI holds one dataset per taxonomic group (Datasets S1-S11), each with its
own reference list, and cites the source of a record in a different way in
every table. This script reads the PDF with PyMuPDF (`fitz`) and writes, next
to the committed S*.csv tables the parse script ingests:

  references.csv    key, citation (verbatim), note, owner_review: every entry of
                    the lists of Tables S1a, S2a, S3 (the numbered list 1-115,
                    which is Chown et al. 2007's Appendix S2 list), S4, S6b and
                    S7, plus the works the dataset notes name as the source of
                    whole tables (White et al. 2006 for S5a/S5b, FishBase for
                    S5c, McKechnie & Wolf 2004 for the MW rows of S6a, Chown et
                    al. 2007 for S3). Keys are '<table>:<author-year>' built from
                    the entry's author block ('S1a:Abu-Amero et al. 1996',
                    'S4:Ikeda & Skjoldal 1989', 'S6b:Gavrilov 1980a'), the S3
                    numbers 'S3:1'-'S3:115'.
  record_refs.csv   table, row (the 1-based row of the committed S*.csv), species,
                    ref_keys ('; '-joined keys of references.csv), source_text
                    (the source cell, superscript or joined reference as printed):
                    the reference key(s) of every row of S1a, S2b, S3, S4, S5a-c,
                    S6a, S6b and S7, read by BodyMass_Makarieva_etal_2008.r.
  S2a_parsed.csv, S3_parsed.csv, S6b_parsed.csv
                    the three tables that had to be read from the PDF (S2b is
                    joined to S2a by species, qWkg and Mpg; S3's reference
                    marks are superscripts; S6b's reference cells wrap).

How each table cites its sources (SI notes, and what is keyed):
  S1a  'Source' column, author-year text of the respiration study, followed in
       brackets by the cell-size source ('[BM, ...]' = Bergey's Manual of
       Systematic Bacteriology, 'BM9' the Determinative 9th ed., or an
       author-year citation): both keyed when they resolve in the S1a list.
  S2b  the per-species minima of Table S2a, whose 'Reference' column names the
       study (and 'Source' the entry number of the Vladimirova & Zotin 1983
       data base, or OTHER): the S2a row with the species' qWkg and Mpg.
  S3   Chown et al. (2007) Appendix S2 reproduced with its superscript numbers
       (and the asterisk of the Chown-lab rows): every row keyed to the
       compilation 'S3:Chown et al. 2007' (hop 2 through Chown_etal_2007); the
       numbers are kept in source_text and S3_parsed.csv.
  S4   'Source' column, author-year text, sometimes with '(data of X YYYY)':
       the cited study, plus the data-of study when it is in the S4 list.
  S5a/b  'after White et al. 2006': one key 'S5:White et al. 2006'.
  S5c  FishBase: 'S5c:FishBase' (a database; owner_review).
  S6a  'Src' G = V. Gavrilov's measurements of Table S6b (the row of that
       species with the minimum night-time rate; its Gavrilov references),
       MW = McKechnie & Wolf (2004): 'S6:McKechnie & Wolf 2004'.
  S6b  'References' column, 'Gavrilov, 1980abc, 1982ab' style: one key per
       cited Gavrilov paper of the S6b list.
  S7   'Source' column as S1a (the bracket is a culture-collection image or a
       citation).

Usage: parse_makarieva_si.py [PDF]   (default: pnas08SI.pdf next to this script:
       the publisher's SI, tracked since 2026-10-06 (owner rule, issue #124),
       copyright (2008) National Academy of Sciences; also at the authors' mirror
       http://www.bioticregulation.ru/common/pdf/pnas08/pnas08SI.pdf)
Counts and every anomaly go to stderr; the script exits non-zero when a table
row cannot be joined to its committed CSV row, a cited key matches no or
several list entries (other than those listed in UNRESOLVED_OK), or a list
heading is not found.
"""
import csv
import os
import re
import sys
import unicodedata
from difflib import SequenceMatcher
from collections import Counter, OrderedDict, defaultdict

try:
    import fitz  # PyMuPDF
except ImportError:  # pragma: no cover
    sys.exit('parse_makarieva_si.py needs PyMuPDF (pip install pymupdf)')

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, 'pnas08SI.pdf')
OUT_REFS = os.path.join(HERE, 'references.csv')
OUT_RECS = os.path.join(HERE, 'record_refs.csv')
OUT_S2A = os.path.join(HERE, 'S2a_parsed.csv')
OUT_S3 = os.path.join(HERE, 'S3_parsed.csv')
OUT_S6B = os.path.join(HERE, 'S6b_parsed.csv')

# 1-based page ranges of the PDF (fixed layout of the 2008 SI)
PAGES = {
    'S1a_table': (12, 46), 'S1a_refs': (47, 59),
    'S2a_table': (65, 70), 'S2a_refs': (70, 77),
    'S3_table': (79, 104), 'S3_refs': (105, 110),
    'S4_table': (112, 127), 'S4_refs': (127, 132),
    'S5_notes': (133, 133),
    'S6_notes': (142, 142),
    'S6b_table': (149, 153), 'S6b_refs': (153, 154),
    'S7_table': (156, 163), 'S7_refs': (163, 166),
}
ROW_TOL = 2.5      # pt: lines whose row coordinate differs by less share a table row
SUP_SIZE = 8.0     # pt: a span smaller than this inside a 10 pt species cell is a reference mark
YEAR_RE = r'(1[89][0-9]{2}|20[0-9]{2})'

errors = []


def log(msg):
    print(msg, file=sys.stderr)


def err(msg):
    errors.append(msg)
    log('ERROR ' + msg)


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


def fold(s):
    """Lowercase ASCII without diacritics, single blanks (for key comparison)."""
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(c for c in s if not unicodedata.combining(c))
    s = s.replace('’', "'").replace('–', '-').replace('—', '-')
    return norm(re.sub(r'[^a-z0-9&.\- ]+', ' ', s.lower()))


# ---- page geometry -------------------------------------------------------------------
# A landscape page of the SI is a portrait page rotated by 90 degrees: its text
# runs upwards, so the row of a line is its x0 and the text starts at y1 and
# ends at y0. Every line and span is reduced to (row, s, e, text) with s < e the
# start and end of the text along the reading direction.
class Span:
    __slots__ = ('s', 'e', 'size', 'text', 'color')

    def __init__(self, s, e, size, text, color=0):
        self.s, self.e, self.size, self.text, self.color = s, e, size, text, color


class Line:
    __slots__ = ('page', 'row', 's', 'e', 'spans')

    def __init__(self, page, row, s, e, spans):
        self.page, self.row, self.s, self.e, self.spans = page, row, s, e, spans

    @property
    def text(self):
        return norm(''.join(sp.text for sp in self.spans))

    @property
    def body(self):
        return norm(''.join(sp.text for sp in self.spans if sp.size >= SUP_SIZE))

    @property
    def sup(self):
        return norm(''.join(sp.text for sp in self.spans if sp.size < SUP_SIZE))


def page_lines(doc, pno):
    page = doc[pno - 1]
    rot = page.rotation == 90
    out = []
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            x0, y0, x1, y1 = line['bbox']
            spans = []
            for sp in line['spans']:
                b = sp['bbox']
                if rot:
                    spans.append(Span(-b[3], -b[1], sp['size'], sp['text'], sp.get('color', 0)))
                else:
                    spans.append(Span(b[0], b[2], sp['size'], sp['text'], sp.get('color', 0)))
            if rot:
                out.append(Line(pno, x0, -y1, -y0, spans))
            else:
                out.append(Line(pno, y0, x0, x1, spans))
    out.sort(key=lambda l: (l.row, l.s))
    return out


def lines_of(doc, first, last):
    out = []
    for pno in range(first, last + 1):
        out.extend(page_lines(doc, pno))
    return out


def group_rows(lines):
    rows = []
    for l in sorted(lines, key=lambda l: (l.page, l.row, l.s)):
        if rows and rows[-1][0].page == l.page and abs(l.row - rows[-1][0].row) <= ROW_TOL:
            rows[-1].append(l)
        else:
            rows.append([l])
    return [sorted(r, key=lambda l: l.s) for r in rows]


class Columns:
    """The columns of a table from its header row. mode 'start': the headers sit at
    the left edges of left-aligned columns, a cell belongs to the column whose
    [start_k, start_k+1) holds the cell's start (the justified Source cells of
    S1a push single words to the right edge of their column, so the start is
    the only safe coordinate); mode 'centre': the headers are centred over their
    columns (S3), a cell belongs to the header centre nearest to its own."""

    def __init__(self, header_lines, names, mode='start', tol=3.0):
        # the header row: the row group holding most of the names
        rows = group_rows(header_lines)
        best = max(rows, key=lambda r: sum(1 for l in r if self._name_of(l.text, names)))
        hdr_rows = [r for r in rows if abs(r[0].row - best[0].row) <= 3 * ROW_TOL]
        cells = {}
        for r in hdr_rows:
            for l in r:
                n = self._name_of(l.text, names)
                if n and n not in cells:
                    cells[n] = l
        for n in names:
            if n not in cells:          # a header printed below the row ('References' of S6b)
                for l in header_lines:
                    if self._name_of(l.text, names) == n:
                        cells[n] = l
                        break
        missing = [n for n in names if n not in cells]
        if missing:
            raise ValueError(f'header name(s) {missing} not found in the header row')
        self.mode, self.tol = mode, tol
        order = sorted(names, key=lambda n: cells[n].s)
        self.names = order
        self.starts = [cells[n].s for n in order]
        self.centres = [(cells[n].s + cells[n].e) / 2 for n in order]

    @staticmethod
    def _name_of(text, names):
        t = re.sub(r'^\d{1,2}\.\s+', '', text).rstrip(',')
        for n in names:
            if t == n or t.startswith(n + ' '):
                return n
        return None

    def of(self, s, e):
        if self.mode == 'start':
            idx = 0
            for i, st in enumerate(self.starts):
                if s >= st - self.tol:
                    idx = i
            return self.names[idx]
        c = (s + e) / 2
        return self.names[min(range(len(self.centres)), key=lambda i: abs(self.centres[i] - c))]


def column_intervals(header_lines, names, mode='start'):
    return Columns(header_lines, names, mode)


def column_of(line_or_s, iv, e=None):
    if isinstance(line_or_s, (Line, Span)):
        return iv.of(line_or_s.s, line_or_s.e)
    return iv.of(line_or_s, e if e is not None else line_or_s)


def join_lines(parts):
    """Join wrapped lines: no blank after a hyphen that breaks a number range
    (Chown convention), one blank otherwise; whitespace collapsed."""
    text = ''
    for part in parts:
        part = norm(part)
        if not part:
            continue
        if not text:
            text = part
        elif text.endswith('-') and part[:1].isdigit():
            text += part
        else:
            text += ' ' + part
    return text


def dehyphenate(text):
    """Hyphenation artefacts of a wrapped cell ('Vish- niac', 'Coo- per') for
    the keys only: a hyphen followed by a blank and a lowercase letter is a
    line break inside a word."""
    return re.sub(r'(\w)- ([a-z])', r'\1\2', text)


# ---- reference lists -----------------------------------------------------------------
ENTRY_START = {
    # what the first line of an entry looks like, by list style (a justified
    # continuation line may sit at the margin: 'Russian)' closing '(in Russian)')
    'paren': re.compile(r"^.{0,160}?\((1[89]|20)\d\d[a-z]?(,\s*\d{4})*\)"),
    'dot': re.compile(r"^.{0,120}?\s(1[89]|20)\d\d[a-z]?\.\s"),
    'russian': re.compile(r"^(?:(?:van|von|de|der|den|du|la|le|Van|De|Le|La)\s+)*[A-ZÀ-ɏ][\wÀ-ɏ'’\-]*(?:\s+[A-ZÀ-ɏ][\wÀ-ɏ'’\-]*)?,?\s+(?:[A-ZÀ-ɏ]\.\s?-?){1,4}"),
}


def parse_list(lines, heading_re, stop_re=None, style='paren', margin_tol=4.0):
    """Entries of a reference list: a line starting at the left margin of its page
    and reading like the start of an entry opens one, every other line continues
    the current entry. Lines before the heading and from the stop line on are
    ignored. Returns the verbatim entries (wrapped lines joined)."""
    started, entries, cur = False, [], None
    body = []
    for l in lines:
        t = l.text
        if not started:
            if re.match(heading_re, t):
                started = True
            continue
        if stop_re and re.match(stop_re, t):
            break
        if re.fullmatch(r'\d{1,3}', t):      # a page number
            continue
        body.append(l)
    if not started:
        raise ValueError(f'list heading {heading_re!r} not found')
    margin = {}
    for l in body:
        margin[l.page] = min(margin.get(l.page, 1e9), l.s)
    starts_entry = ENTRY_START[style]
    for l in body:
        t = l.text
        at_margin = l.s <= margin[l.page] + margin_tol
        if at_margin and (starts_entry.match(clean_for_parse(t)) or style == 'paren' and starts_entry.match(clean_for_parse(t + ' ' ))):
            cur = [t]
            entries.append(cur)
        elif at_margin and cur is not None and ENTRY_START['russian'].match(clean_for_parse(t)) and style != 'dot' \
                and not re.match(r'^(Russian|English|German|French)\)', t):
            # an entry without a year ('Cartwright N.J., Cain R.B. Bacterial degradation ...')
            cur = [t]
            entries.append(cur)
        elif cur is not None:
            if at_margin:
                log(f'  page {l.page}: margin line read as a continuation: {t[:60]!r}')
            cur.append(t)
        else:
            raise ValueError(f'page {l.page}: indented line before the first entry: {t!r}')
    return [join_lines(e) for e in entries]


def parse_numbered_list(lines, heading_re, stop_re=None):
    """The S3 list: 'N.' in the number column opens entry N, the text lines follow."""
    started, entries, cur = False, [], None
    for l in lines:
        t = l.text
        if not started:
            if re.match(heading_re, t):
                started = True
            continue
        if stop_re and re.match(stop_re, t):
            break
        if re.fullmatch(r'\d{1,3}', t):
            continue
        m = re.fullmatch(r'(\d{1,3})\.', t)
        if m:
            cur = {'key': m.group(1), 'lines': []}
            entries.append(cur)
        elif cur is not None:
            cur['lines'].append(t)
        else:
            raise ValueError(f'page {l.page}: text before the first number: {t!r}')
    out = []
    for e in entries:
        text = ''
        for part in e['lines']:
            if not text:
                text = part
            elif text.endswith('-') and part[:1].isdigit():
                text += part
            else:
                text += ' ' + part
        out.append((e['key'], norm(text)))
    nums = [int(k) for k, _ in out]
    if nums != list(range(1, len(nums) + 1)):
        raise ValueError(f'numbered list: {len(nums)} entries, numbers {nums[:3]}...{nums[-3:]}')
    return out


# ---- author-year keys of list entries ------------------------------------------------
PARTICLES = ('van', 'von', 'de', 'der', 'den', 'du', 'la', 'le', 'Van', 'De', 'Le', 'La')
# 'J.', 'K.K.', 'H.-P.', 'Yu.B.', 'JJ'; not 'De' (a particle) nor 'APHA' (an organisation)
INITIAL_RE = re.compile(r"^(?:[A-ZÀ-ɏ](?:[a-z]\.|\.)-?){1,4}$|^[A-ZÀ-ɏ]{1,2}$|^[A-Z]\.?[A-Z]\.?-[A-Z]\.?$")

SUFFIX_RE = re.compile(r'^(Jr\.?|Sr\.?|II|III)$')
# 'Surname I.I.' (particles allowed, a two-word surname allowed) at the start of a token
AUTHOR_TOKEN_RE = re.compile(
    r"^((?:(?:" + '|'.join(PARTICLES) + r")\s+)*[A-ZÀ-ɏ][\wÀ-ɏ'’\-]*(?:\s+[A-ZÀ-ɏ][\wÀ-ɏ'’\-]*)?),?\s+((?:[A-ZÀ-ɏ]\.\s?-?){1,4})(?:\s*(Jr\.?))?(.*)$")
CYRILLIC = str.maketrans('АВСЕНКМОРТХаеорсух', 'ABCEHKMOPTXaeopcyx')


def clean_for_parse(c):
    """A parsing copy of a citation: Cyrillic look-alike letters in initials and
    the 'I941' misprints of the S2a list; raw_citation stays verbatim."""
    c = c.translate(CYRILLIC)
    return re.sub(r'\bI(9\d\d)\b', r'1\1', c)


def author_tokens(block):
    """Surnames of an author block 'Abu-Amero K.K., Halablab M.A., Miles R.J.',
    'Gavrilov, V.M., Dolnik, V.R.', 'Gavrilov V.M., A.B. Kerimov, T.B. Golubeva'."""
    block = re.sub(r'\([^)]*\)', '', block)          # '(ed.)', '(eds.)', the expansion of 'APHA (American ...)'
    block = block.replace(' and ', ', ').replace(' & ', ', ')
    names = []
    for tok in re.split(r',\s*', block):
        words = [w for w in tok.split()
                 if not (INITIAL_RE.match(w) or INITIAL_RE.match(w.rstrip('.'))) and not SUFFIX_RE.match(w)]
        words = [w.rstrip('.') for w in words]
        if len(words) > 1 and all(re.match(r'^[A-ZÀ-ɏ]', w) for w in words) and not words[0].lower() in PARTICLES:
            # authors printed without initials and without commas ('Kjelleberg Humphrey Marshall'):
            # one surname per capitalised word
            names.extend(words)
        elif words:
            names.append(' '.join(words))
    return names


def leading_authors(text):
    """The surnames of the 'Surname I.I., Surname I.I. Title ...' author block
    that opens an entry (the Russian style of the S2a list, or an entry without
    a year); None when the text does not start with one."""
    names = []
    for tok in re.split(r',\s*', text):
        m = AUTHOR_TOKEN_RE.match(tok)
        if not m:
            break
        names.append(m.group(1))
        if m.group(4).strip():
            break
    return names or None


def key_from_names(names, year):
    if not names:
        return None
    if len(names) == 1:
        head = names[0]
    elif len(names) == 2:
        head = f'{names[0]} & {names[1]}'
    else:
        head = f'{names[0]} et al.'
    return f'{head} {year}'


def entry_key(citation, style):
    """The author-year key of a list entry.
    style 'paren':  'Authors (YYYYa) Title...'            (S1a, S4, S7 lists; also the OTHER entries of S2a)
    style 'dot':    'Authors YYYYa. Title...'              (S6b list)
    style 'russian': 'Authors Title. - Journal, YYYY, v.N' (S2a list: the year after the journal)
    An entry without a year gets the year 'n.d.' (resolved by its authors)."""
    c = clean_for_parse(citation)
    m = re.match(r'^(.*?)\s*\((' + YEAR_RE + r'[a-z]?)(?:,\s*' + YEAR_RE + r')*\)', c)
    if m and (style == 'paren' or len(m.group(1)) < 120):
        return key_from_names(author_tokens(m.group(1)), m.group(2))
    if style == 'dot':
        m = re.match(r'^(.*?)\s+(' + YEAR_RE + r'[a-z]?)\.\s', c)
        if m:
            return key_from_names(author_tokens(m.group(1)), m.group(2))
    names = leading_authors(c)
    if not names:
        return None
    block_end = 0
    for tok in re.finditer(r"(?:[A-ZÀ-ɏ]\.\s?-?){1,4}", c):
        block_end = tok.end()
        if len(names) == 1 or c[:tok.end()].count(',') >= len(names) - 1:
            break
    ym = re.search(r'(?<!\d)(' + YEAR_RE + r')([a-z]?)(?!\d)', c[block_end:])
    year = (ym.group(1) + ym.group(3)) if ym else 'n.d.'
    return key_from_names(names, year)


# ---- data keys (the source cells) -----------------------------------------------------
AUTHOR_YEAR_RE = re.compile(r'^(.+?)\s+(' + YEAR_RE + r'[a-z]?)$')


def normalise_data_key(k):
    k = norm(dehyphenate(k))
    k = k.replace(' and ', ' & ')
    k = re.sub(r'\s*,\s*(Fig|Table|Tab|p)\.?.*$', '', k)       # 'Doolittle & Singer 1974, Fig. 6'
    k = re.sub(r'\s+et\s+al\.?,?\s+', ' et al. ', k)
    k = re.sub(r',\s*(' + YEAR_RE + ')', r' \1', k)             # 'Gavrilov, 1981'
    return k.strip(' ,;.')


CITE_IN_TEXT_RE = re.compile(
    r"((?:(?:van|von|de|der|den|du|la|le|Van|De|Le|La|Mc)\s)?[A-ZÀ-ÖØ-ɏ][\wÀ-ÖØ-ɏ'’\-]+"
    r"(?:\s&\s(?:van|von|de|der|den|du|la|le|Van|De|Le|La)?\s?[A-ZÀ-ɏ][\wÀ-ɏ'’\-]+|\set\sal\.?)?"
    r"\s(1[89]\d\d|20\d\d)[a-z]?)(?!\d)")


LOOSE_CITE_RE = re.compile(
    r"([A-ZÀ-ÖØ-ɏ][\wÀ-ÖØ-ɏ'’\-]+(?:\s&\s[A-ZÀ-ÖØ-ɏ][\wÀ-ÖØ-ɏ'’\-]+|\set\sal\.?)?)\s[^A-Za-z\[\]]*?\b(1[89]\d\d|20\d\d)\b")
MONTH_RE = re.compile(r'^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\b')


def split_source_cell(text):
    """A Source cell -> (cited keys, size-source / data-of keys).
    'Byzova 1973 (data of Müller 1943)' -> (['Byzova 1973'], ['Müller 1943'])
    'De Ley & Schell 1959 [BM, ellipsoid ...]' -> (['De Ley & Schell 1959'], ['BM'])
    'Jurtshuk & McQuitty 1976 [Kubitschek 1969, Coulter counter]' -> (..., ['Kubitschek 1969'])
    'Rubin et al. 1977 [estimated from images at UTEX ...]' -> (['Rubin et al. 1977'], [])
    The bracket of S1a / S7 is the cell-size source: 'BM' / 'BM9' (Bergey's
    Manual) and every author-year citation it contains are keys; a shape or an
    image is none."""
    text = norm(dehyphenate(text))
    main, _, rest = text.partition('[')
    extra = []
    m = re.match(r'^(.*?)\s*\((?:data of|after|from|cited in)\s+(.*?)\)?\s*$', main)
    if m:
        main = m.group(1)
        for part in re.split(r';\s*', m.group(2)):
            part = normalise_data_key(part)
            if AUTHOR_YEAR_RE.match(part):
                extra.append(part)
    mains = []
    prev_head = None
    for part in re.split(r';\s*', main):
        part = normalise_data_key(part)
        if not part:
            continue
        if re.fullmatch(YEAR_RE + r'[a-z]?', part) and prev_head:
            part = f'{prev_head} {part}'                        # 'Ryley 1951; 1953'
        m2 = re.match(r'^(.*?)\s(' + YEAR_RE + r'[a-z]?)((?:,?\s' + YEAR_RE + r'[a-z]?)+)$', part)
        if m2:                                                   # 'Wieser 1963, 1965'
            prev_head = m2.group(1)
            mains.append(f'{m2.group(1)} {m2.group(2)}')
            mains.extend(f'{m2.group(1)} {y}' for y in re.findall(YEAR_RE + r'[a-z]?', m2.group(4)))
            continue
        if AUTHOR_YEAR_RE.match(part):
            prev_head = AUTHOR_YEAR_RE.match(part).group(1)
            mains.append(part)
        else:
            found = [normalise_data_key(c.group(1)) for c in CITE_IN_TEXT_RE.finditer(part)
                     if not MONTH_RE.match(c.group(1))]
            if found:
                mains.extend(found)
                log(f'  source cell: citation(s) {found} taken from {part!r}')
            elif re.fullmatch(r"[A-ZÀ-ɏ][\wÀ-ɏ'’\-]+(?: & [A-ZÀ-ɏ][\wÀ-ɏ'’\-]+| et al\.)?", part):
                mains.append(part)      # the year lost in the wrap ('Silverthorn'): resolved by the authors
                log(f'  source cell: author(s) without a year {part!r}')
            else:
                log(f'  source cell: no author-year citation in {part!r}')
    if rest:
        for tok in re.finditer(r'\bBM9?\b', rest):
            extra.append(tok.group(0))
        found = [normalise_data_key(c.group(1)) for c in CITE_IN_TEXT_RE.finditer(rest) if not MONTH_RE.match(c.group(1))]
        if not found:
            # justified cell text pushes the dimensions between the authors and the year:
            # '[Groupé et al. 0.5×2-3 1954, μm]'
            for c in LOOSE_CITE_RE.finditer(rest):
                if not MONTH_RE.match(c.group(1)):
                    found.append(normalise_data_key(f'{c.group(1)} {c.group(2)}'))
                    log(f'  source cell: size source {found[-1]!r} read from the scrambled bracket {rest[:60]!r}')
        extra.extend(found)
    seen = []
    for k in mains + extra:
        if k not in seen:
            seen.append(k)
    return [k for k in seen if k in mains], [k for k in seen if k not in mains]


def expand_year_letters(text):
    """'Gavrilov, 1980abc, 1982ab, 1997, 1999ab' -> ['Gavrilov 1980a', ..., 'Gavrilov 1999b'];
    'Gavrilov, Dolnik, 1985' -> ['Gavrilov & Dolnik 1985'];
    'Gavrilov, Dolnik, 1985, Gavrilov et al.,1995b, 1998' -> ['Gavrilov & Dolnik 1985',
    'Gavrilov et al. 1995b', 'Gavrilov et al. 1998'] (a name after the years opens a new group)."""
    groups, authors, years = [], [], []
    for tok in re.split(r',\s*|\s+(?=\d{4})', norm(text).strip(' ,')):
        tok = tok.strip(' ,.')
        if not tok:
            continue
        if re.fullmatch(YEAR_RE + r'[a-z]*', tok):
            years.append(tok)
        else:
            if years:
                groups.append((authors, years))
                authors, years = [], []
            authors.append(tok)
    if authors or years:
        groups.append((authors, years))
    keys = []
    for authors, years in groups:
        if not authors or not years:
            log(f'  reference cell {text!r}: group without authors or years ({authors}, {years})')
            continue
        head = ' '.join(authors) if authors[-1].endswith(('et al', 'et al.')) else None
        if head:
            head = re.sub(r'\s*et al\.?$', ' et al.', head)
        elif len(authors) == 1:
            head = authors[0]
        elif len(authors) == 2:
            head = f'{authors[0]} & {authors[1]}'
        else:
            head = f'{authors[0]} et al.'
        for y in years:
            ym = re.fullmatch('(' + YEAR_RE + ')([a-z]*)', y)
            if ym.group(3):
                keys.extend(f'{head} {ym.group(1)}{c}' for c in ym.group(3))
            else:
                keys.append(f'{head} {ym.group(1)}')
    return keys


# ---- the reference register -----------------------------------------------------------
class Register:
    """Entries by table with their canonical keys; data keys are resolved by their
    folded author-year form."""

    def __init__(self):
        self.entries = OrderedDict()     # key -> dict(citation, note, owner_review)
        self.lookup = defaultdict(dict)  # table -> folded key -> key
        self.ambiguous = defaultdict(dict)   # table -> folded base key -> n entries
        self.by_author = defaultdict(lambda: defaultdict(list))   # table -> folded author part -> keys
        self.by_first = defaultdict(lambda: defaultdict(list))    # table -> (folded first surname, year) -> keys
        self.fallbacks = []                                       # (table, data key, key, rule)

    def add_list(self, table, citations, style, note):
        made = Counter()
        pending = []
        seen_text = set()
        for c in citations:
            if c in seen_text:
                log(f'  {table}: entry printed twice, kept once: {c[:70]!r}')
                continue
            seen_text.add(c)
            k = entry_key(c, style)
            if k is None:
                err(f'{table}: no author-year key for entry {c[:90]!r}')
                k = f'? {c[:40]}'
            made[k] += 1
            pending.append((k, c))
        seen = Counter()
        for k, c in pending:
            full = k
            if made[k] > 1:
                seen[k] += 1
                full = f'{k} [{seen[k]}]'
                self.ambiguous[table][fold(k)] = made[k]
                log(f'  {table}: key {k!r} stands for {made[k]} entries -> {full!r}')
            self._put(f'{table}:{full}', c, note, '')
            if made[k] == 1:
                self.lookup[table][fold(k)] = f'{table}:{full}'
        log(f'  {table}: {len(pending)} entries, {len(made)} distinct author-year keys')

    def _put(self, key, citation, note, owner_review):
        if key in self.entries:
            err(f'duplicated key {key}')
        self.entries[key] = {'citation': citation, 'note': note, 'owner_review': owner_review}
        table, _, rest = key.partition(':')
        self.lookup[table][fold(rest)] = key
        author = re.sub(r'\s(' + YEAR_RE + r'|n\.d\.)[a-z]?(\s\[\d+\])?$', '', rest)
        self.by_author[table][fold(author)].append(key)
        ym = re.search(r'\s(' + YEAR_RE + r')[a-z]?(\s\[\d+\])?$', rest)
        first = re.split(r' & | et al\.', author)[0]
        self.by_first[table][(fold(first), ym.group(1) if ym else 'n.d.')].append(key)

    def add(self, key, citation, note, owner_review=''):
        self._put(key, citation, note, owner_review)

    def resolve(self, table, data_key, aliases=None):
        """The references.csv key of a data key, or None (nothing matches) or
        'AMBIGUOUS' (several same-key entries, no letter to tell them apart). The
        ladder, each step taken only when it names exactly one entry:
        exact author-year form; a year letter the list lacks taken as the entry's
        position among the same-author same-year entries ('Edwards & Lloyd 1977a'
        -> '... 1977 [1]', flagged owner_review); a key without a letter against
        the list's only lettered entry ('Gavrilov 1974' -> 'Gavrilov 1974a'); the
        same authors with the year off by one or missing ('Reed & Dugan 1978' ->
        1979); the first surname and year (an abbreviated author list, 'Kahn 1981'
        -> 'Kahn & Gromkova 1981'); a near-identical spelling of the same year
        ('Seaman & Noulihan 1950' -> 'Seaman & Houlihan 1950')."""
        aliases = aliases or {}
        if data_key in aliases:
            data_key = aliases[data_key]
        f = fold(re.sub(r"\s(?:[A-Z]\.){1,3}(?=\s)", '', data_key))     # 'Wilson P. 1961' -> 'Wilson 1961'
        hit = self.lookup[table].get(f)
        if hit:
            return hit
        m = re.match(r'^(.*\d{4})([a-z])$', f)
        if m and m.group(1) in self.ambiguous[table]:
            idx = ord(m.group(2)) - 96
            hit = self.lookup[table].get(fold(f'{m.group(1)} [{idx}]'))
            if hit:
                self.entries[hit]['owner_review'] = ('record key year letter mapped to the position of the entry '
                                                     'among the same-author same-year entries of the list')
                self.fallbacks.append((table, data_key, hit, 'year letter -> list position'))
                return hit
        if f in self.ambiguous[table]:
            return 'AMBIGUOUS'
        if re.search(r'\d{4}$', f):
            lettered = [k for fk, k in self.lookup[table].items() if re.fullmatch(re.escape(f) + '[a-z]', fk)]
            if len(set(lettered)) == 1:
                self.fallbacks.append((table, data_key, lettered[0], 'the only lettered entry of that year'))
                return lettered[0]
        ym = re.search(r'(\d{4})[a-z]?$', f)
        author = re.sub(r'\s\d{4}[a-z]?$', '', f)
        cands = self.by_author[table].get(author, [])
        if len(cands) == 1:
            yl = re.search(r'\s(\d{4})[a-z]?(\s\[\d+\])?$', cands[0])
            if not (ym and yl and abs(int(ym.group(1)) - int(yl.group(1))) > 1):
                self.fallbacks.append((table, data_key, cands[0], 'same authors, year off by one or missing'))
                return cands[0]
        if ym:
            first = re.split(r' & | et al', author)[0]
            cands = self.by_first[table].get((first, ym.group(1)), [])
            # an abbreviated author list only: a key naming a second author that the
            # entry lacks ('Ikeda & Skjoldal 1982' against 'Ikeda & Mitchell 1982') is another paper
            if len(cands) == 1 and ' & ' not in author:
                self.fallbacks.append((table, data_key, cands[0], 'first surname and year'))
                return cands[0]
            near = [(SequenceMatcher(None, f, fk).ratio(), k) for fk, k in self.lookup[table].items()
                    if fk.endswith(ym.group(0)) or re.search(re.escape(ym.group(1)) + r'[a-z]? \d$', fk)]
            near = sorted((r, k) for r, k in near if r >= 0.88)
            if near and len(set(k for _, k in near)) == 1:
                self.fallbacks.append((table, data_key, near[-1][1], f'spelling (similarity {near[-1][0]:.2f})'))
                return near[-1][1]
        return None


# ---- tables ----------------------------------------------------------------------------
def records_by_opener(lines, iv, opener_col, opener_re):
    """Split the lines of a rotated table into records: a row holding, in
    `opener_col`, a line matching `opener_re` starts a record, every following
    row belongs to it until the next opener row (lines of one visual row differ
    slightly in their row coordinate, so rows are grouped first). Lines before
    the first opener are dropped. Returns [(opener_match, [lines])]."""
    recs = []
    col_start = iv.starts[iv.names.index(opener_col)]
    for row in group_rows(lines):
        opener = None
        for l in row:
            # the number of a numbered cell hangs to the left of its column (S1a's
            # Valid name column), so the opener is found near the column start
            if abs(l.s - col_start) <= 30:
                m = re.match(opener_re, l.text)
                if m and m.group(2).strip() not in ('Taxonomic group',):   # the numbered header of S2a
                    opener = m
                    break
        if opener:
            recs.append((opener, list(row)))
        elif recs:
            recs[-1][1].extend(row)
    return recs


def cell(lines, iv, col, spans=False):
    """The text of column `col` in a record: its lines (or spans) joined in reading order."""
    parts = []
    if spans:
        for l in lines:
            for sp in l.spans:
                if column_of(sp, iv) == col and sp.text.strip():
                    parts.append((l.page, round(l.row / ROW_TOL), sp.s, sp.text))
    else:
        for l in lines:
            if column_of(l, iv) == col:
                parts.append((l.page, round(l.row / ROW_TOL), l.s, l.text))
    parts.sort()
    return join_lines(p[3] for p in parts)


def fix_spill(records, field):
    """A Source cell printed once for two consecutive records (a vertically merged
    cell) overflows into the second record's rows: a cell text that closes a
    bracket before opening one starts with the previous record's tail, which is
    moved back."""
    for prev, cur in zip(records, records[1:]):
        t = cur[field]
        i, j = t.find(']'), t.find('[')
        if i >= 0 and (j < 0 or i < j):
            prev[field] = norm(prev[field] + ' ' + t[:i + 1])
            cur[field] = t[i + 1:].strip()
            log(f'  spill: {t[:i + 1]!r} moved from record {cur["row"]} back to {prev["row"]}')


def parse_s1a(doc):
    lines = lines_of(doc, *PAGES['S1a_table'])
    header = [l for l in lines if l.page == PAGES['S1a_table'][0]]
    names = ['Comments', 'Culture age', 'Source', 'Mpg', 'q25Wkg', 'TC', 'qWkg', 'qou', 'MIN',
             'Original units', 'Class: Order', 'Valid name', 'Species (strain)']
    # the columns are listed right to left on the rotated page: reverse for increasing s
    iv = column_intervals(header, names)
    recs = records_by_opener(lines, iv, 'Valid name', r'^(\d{1,3})\.\s+(.*)$')
    out = []
    for m, ls in recs:
        out.append({'row': int(m.group(1)), 'valid_name': norm(m.group(2) + ' ' + cell(ls[1:], iv, 'Valid name')),
                    'Mpg': cell(ls, iv, 'Mpg'), 'source': cell(ls, iv, 'Source')})
    fix_spill(out, 'source')
    nums = [r['row'] for r in out]
    if nums != list(range(1, len(nums) + 1)):
        err(f'S1a: record numbers {nums[:5]}... are not 1..{len(nums)}')
    log(f'S1a: {len(out)} records read from the PDF')
    return out


def parse_s7(doc):
    lines = lines_of(doc, *PAGES['S7_table'])
    header = [l for l in lines if l.page == PAGES['S7_table'][0]]
    names = ['Comments', 'Source', 'Order', 'Mpg', 'TC', 'q25Wkg', 'qWkg', 'qou', 'Original units', 'U', 'Species']
    iv = column_intervals(header, names)
    recs = records_by_opener(lines, iv, 'Species', r'^(\d{1,3})\.\s+(.*)$')
    out = []
    for m, ls in recs:
        out.append({'row': int(m.group(1)), 'species': norm(m.group(2) + ' ' + cell(ls[1:], iv, 'Species')),
                    'Mpg': cell(ls, iv, 'Mpg'), 'source': cell(ls, iv, 'Source')})
    fix_spill(out, 'source')
    nums = [r['row'] for r in out]
    if nums != list(range(1, len(nums) + 1)):
        err(f'S7: record numbers {nums[:5]}... are not 1..{len(nums)}')
    log(f'S7: {len(out)} records read from the PDF')
    return out


def parse_s4(doc):
    lines = lines_of(doc, *PAGES['S4_table'])
    header = [l for l in lines if l.page == PAGES['S4_table'][0]]
    names = ['Source', 'WC', 'N/DM', 'DMg', 'TC', 'Mg', 'qWkg', 'q25Wkg', 'MIN', 'Species', 'Family',
             'Higher Taxon', 'Group']
    # N/DM, WC and Source share one text line: columns are assigned span by span
    hdr = []
    for l in header:
        for sp in l.spans:
            if sp.text.strip():
                hdr.append(Line(l.page, l.row, sp.s, sp.e, [sp]))
    iv = column_intervals(hdr, names)
    stop = None
    body = []
    for l in lines:
        if l.text.startswith('References to Table S4'):
            stop = l
            break
        body.append(l)
    if stop is None:
        err('S4: end of the table (References to Table S4) not found')
    recs = records_by_opener(body, iv, 'Higher Taxon', r'^(\d{1,3})\.\s+(.*)$')
    out = []
    for m, ls in recs:
        out.append({'row': int(m.group(1)), 'species': cell(ls, iv, 'Species', spans=True),
                    'MIN': cell(ls, iv, 'MIN', spans=True), 'qWkg': cell(ls, iv, 'qWkg', spans=True),
                    'Mg': cell(ls, iv, 'Mg', spans=True), 'TC': cell(ls, iv, 'TC', spans=True),
                    'source': cell(ls, iv, 'Source', spans=True)})
    nums = [r['row'] for r in out]
    if nums != list(range(1, len(nums) + 1)):
        err(f'S4: record numbers are not 1..{len(nums)}: first gaps '
            f'{[n for n in range(1, len(nums) + 1) if n not in nums][:5]}')
    log(f'S4: {len(out)} records read from the PDF; {sum(1 for r in out if not r["source"])} with an empty Source cell')
    return out


def parse_s2a(doc):
    lines = lines_of(doc, *PAGES['S2a_table'])
    header = [l for l in lines if l.page == PAGES['S2a_table'][0]]
    names = ['Reference', 'Source', 'Culture age', 'TC', 'Mpg', 'qWkg', 'qou', 'Original units', 'Species',
             'Taxonomic group']
    iv = column_intervals(header, names)
    body = []
    for l in lines:
        if l.text.startswith('References to Table S2a'):
            break
        body.append(l)
    recs = records_by_opener(body, iv, 'Taxonomic group', r'^(\d{1,3})\.\s+(.*)$')
    out = []
    for m, ls in recs:
        out.append({'row': int(m.group(1)), 'group': m.group(2), 'species': cell(ls, iv, 'Species'),
                    'qWkg': cell(ls, iv, 'qWkg'), 'Mpg': cell(ls, iv, 'Mpg'), 'TC': cell(ls, iv, 'TC'),
                    'source': cell(ls, iv, 'Source'), 'reference': cell(ls, iv, 'Reference')})
    nums = [r['row'] for r in out]
    if nums != list(range(nums[0], nums[0] + len(nums))):
        err(f'S2a: record numbers are not consecutive ({nums[0]}..{nums[-1]}, {len(nums)} records)')
    log(f'S2a: records numbered {nums[0]}-{nums[-1]} (the header line carries number 1)')
    log(f'S2a: {len(out)} records read from the PDF; sources OTHER: {sum(1 for r in out if r["source"] == "OTHER")}')
    return out


def parse_s3(doc):
    lines = lines_of(doc, *PAGES['S3_table'])
    header = [l for l in lines if l.page == PAGES['S3_table'][0]]
    names = ['Q (µW)', 'M (mg)', 'Order', 'Family', 'Species']
    iv = column_intervals(header, names, mode='centre')
    rows = group_rows(lines)
    out = []
    for r in rows:
        cols = {}
        for l in r:
            c = column_of(l, iv)
            if c in cols:
                cols[c] = Line(l.page, l.row, min(cols[c].s, l.s), l.e, cols[c].spans + l.spans)
            else:
                cols[c] = l
        if 'M (mg)' in cols and 'Q (µW)' in cols and 'Species' in cols \
                and re.fullmatch(r'-?\d+(\.\d+)?', cols['M (mg)'].text):
            sp = cols['Species']
            out.append({'page': r[0].page, 'species': sp.body, 'marks': sp.sup,
                        'family': cols.get('Family', Line(0, 0, 0, 0, [])).text,
                        'order': cols.get('Order', Line(0, 0, 0, 0, [])).text,
                        'M_mg': cols['M (mg)'].text, 'Q_uW': cols['Q (µW)'].text,
                        # the ten data points Makarieva et al. added to Chown's set are printed in green
                        'green': 'TRUE' if any(x.color != 0 for x in sp.spans if x.size >= SUP_SIZE) else 'FALSE'})
        elif out and set(cols) <= {'Species', 'Family', 'Order'} and 'Species' in cols \
                and not re.match(r'^(\*|Wing status|Ten data points)', cols['Species'].text) \
                and len(cols['Species'].text) < 40 and not re.search(r'[:=]', cols['Species'].text):
            # a species name wrapped onto a second line
            out[-1]['species'] = norm(out[-1]['species'] + ' ' + cols['Species'].body)
            out[-1]['marks'] = norm(out[-1]['marks'] + cols['Species'].sup)
            log(f'  S3 page {r[0].page}: wrapped species name -> {out[-1]["species"]!r}')
        else:
            t = ' | '.join(l.text for l in r)
            if not re.match(r'^(Dataset S3|Standard metabolic|Scaling of insect|Notations|M is body|Analyses|dimension|Species$|Family$|Order$|M \(mg\)|Q \(µW\))', t):
                log(f'  S3 page {r[0].page}: non-data line: {t[:100]}')
    for r in out:
        marks = r['marks']
        if 'Ŧ' in marks or '†' in marks:
            log(f'  S3 page {r["page"]}: footnote mark {marks!r} on {r["species"]!r} (dropped from the reference marks)')
            marks = marks.replace('Ŧ', '').replace('†', '')
        r['ref_marks'] = '; '.join(k for k in re.split(r'[,;]\s*', marks) if k)
        if r['species'].endswith('*'):
            r['ref_marks'] = '; '.join([x for x in [r['ref_marks'], '*'] if x])
    log(f'S3: {sum(1 for r in out if r["green"] == "TRUE")} green rows (added by Makarieva et al.): '
        + ', '.join(f'{r["species"]} {r["M_mg"]} [{r["ref_marks"]}]' for r in out if r['green'] == 'TRUE'))
    log(f'S3: {len(out)} rows read from the PDF; {sum(1 for r in out if not r["ref_marks"])} without a reference mark; '
        f'{sum(1 for r in out if r["species"].endswith("*"))} asterisk rows')
    return out


def parse_s6b(doc):
    lines = lines_of(doc, *PAGES['S6b_table'])
    body = []
    for l in lines:
        if l.text.startswith('References to Table S6b'):
            break
        body.append(l)
    # columns by the header of page 149
    header = [l for l in body if l.page == PAGES['S6b_table'][0]]
    names = ['Species', 'N', 'Mg', 'Sea-', 'Time', 'QkJday', 'References']
    iv = column_intervals(header, names)
    rows = group_rows(body)
    out, order, pending_species, pending_season = [], '', '', ''
    needs_species = None

    def number(x):
        return re.sub(r'\.$', '', x.replace(',', '.').replace(' ', ''))

    for r in rows:
        cols = defaultdict(list)
        for l in r:
            cols[column_of(l, iv)].append(l.text)
        c = {k: norm(' '.join(v)) for k, v in cols.items()}
        if 'References' in c and not ('Mg' in c and 'QkJday' in c) and out:
            # a wrapped reference line (it may share its line with the species of the next row)
            out[-1]['references'] = norm(out[-1]['references'] + ' ' + c.pop('References'))
        if set(c) == {'Species'} and not re.search(r'\d', c['Species']):
            if c['Species'] == 'Species':
                continue
            if re.fullmatch(r'[A-Z][a-z]+iformes', c['Species']):
                order = c['Species']
            elif needs_species is not None:        # a two-line row: the species below its values
                needs_species['species'] = c['Species']
                needs_species = None
            else:
                pending_species = c['Species']      # a two-line row: the species above its values
            continue
        if set(c) == {'Sea-'} and re.fullmatch(r'[WSAVY](, [WSAVY])?', c['Sea-']):
            if out and not out[-1]['Season'] and needs_species is None:
                out[-1]['Season'] = c['Sea-']
            else:
                pending_season = c['Sea-']
            continue
        if not c:
            continue
        if 'Mg' in c and 'QkJday' in c and re.fullmatch(r'[\d.,]+\.?', c['Mg']):
            species = c.get('Species', '')
            if not species and pending_species:
                species = pending_species
            pending_species = ''
            season = c.get('Sea-', '') or pending_season
            pending_season = ''
            out.append({'order': order, 'species': species, 'N': c.get('N', ''), 'Mg': number(c['Mg']),
                        'Season': season, 'Time': c.get('Time', ''), 'QkJday': number(c['QkJday']),
                        'references': c.get('References', '')})
            needs_species = out[-1] if not species else None
        elif not re.match(r'^(Table S6b|Notations|W —|S —|A —|V —|Y —|QkJday —|Note:|minimum|species, |Species$|annual|\(for|son$|References$|[WSAVY]$)', ' '.join(c.values())):
            log(f'  S6b page {r[0].page}: non-data line: {" | ".join(c.values())[:100]}')
    log(f'S6b: {len(out)} rows read from the PDF, {len(set(r["species"] for r in out))} species')
    return out


# ---- the notes' whole-table sources ------------------------------------------------------
def page_text(doc, pno):
    return norm(' '.join(l.text for l in page_lines(doc, pno)))


def notes_citation(doc, pno, start_re, end_re, what):
    t = page_text(doc, pno)
    m = re.search(start_re + r'.*?' + end_re, t)
    if not m:
        err(f'{what}: citation not found on page {pno}')
        return ''
    return norm(m.group(0))


# ---- CSV I/O -----------------------------------------------------------------------------
def read_csv(name):
    with open(os.path.join(HERE, name), newline='', encoding='utf-8') as fh:
        return list(csv.DictReader(fh))


def write_csv(path, rows, fields):
    with open(path, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=fields, extrasaction='ignore', lineterminator='\n')
        w.writeheader()
        w.writerows(rows)


def num_eq(a, b):
    a, b = re.sub(r'\.$', '', str(a).replace(',', '.').strip()), re.sub(r'\.$', '', str(b).replace(',', '.').strip())
    try:
        return abs(float(a) - float(b)) <= 1e-9 * max(1.0, abs(float(a)))
    except ValueError:
        return norm(a) == norm(b)


# ---- main -----------------------------------------------------------------------------
def main(argv):
    pdf = argv[1] if len(argv) > 1 else DEFAULT_PDF
    if not os.path.exists(pdf):
        sys.exit(f'{pdf} not found: the tracked SI PDF is missing (mirror '
                 'http://www.bioticregulation.ru/common/pdf/pnas08/pnas08SI.pdf)')
    doc = fitz.open(pdf)
    if len(doc) != 212:
        err(f'{os.path.basename(pdf)}: {len(doc)} pages, expected 212')
    reg = Register()
    records = []        # rows of record_refs.csv
    unresolved = Counter()

    def resolve_keys(table, data_keys, aliases=None, context=''):
        keys = []
        for dk in data_keys:
            if not re.search(YEAR_RE, dk) and dk not in ('BM', 'BM9'):
                log(f'  {table}: data key without a year {dk!r} in {context[:80]!r}')
            k = reg.resolve(table, dk, aliases)
            if k == 'AMBIGUOUS':
                unresolved[(table, dk, 'ambiguous')] += 1
                keys.append(f'{table}:{dk}')
            elif k is None:
                unresolved[(table, dk, 'not in list')] += 1
                keys.append(f'{table}:{dk}')
            else:
                keys.append(k)
        seen = []
        for k in keys:
            if k not in seen:
                seen.append(k)
        return '; '.join(seen)

    # ---- the lists ----
    log('Reference lists')
    reg.add_list('S1a', parse_list(lines_of(doc, *PAGES['S1a_refs']), r'^References to Table S1a', r'^Table S1b', 'paren'),
                 'paren', 'S1a list (p. 47-59)')
    reg.add_list('S2a', parse_list(lines_of(doc, *PAGES['S2a_refs']), r'^References to Table S2a', r'^Table S2b', 'russian'),
                 'russian', 'S2a list (p. 70-77)')
    s3_list = parse_numbered_list(lines_of(doc, *PAGES['S3_refs']), r'^References$')
    for k, c in s3_list:
        reg.add(f'S3:{k}', c, 'S3 numbered list (p. 105-110) = Chown et al. 2007 Appendix S2 reference list; '
                              'not keyed by the records, which route to the compilation (S3:Chown et al. 2007)')
    log(f'  S3: {len(s3_list)} numbered entries')
    reg.add_list('S4', parse_list(lines_of(doc, *PAGES['S4_refs']), r'^References to Table S4', r'^Dataset S5', 'paren'),
                 'paren', 'S4 list (p. 127-132)')
    reg.add_list('S6b', parse_list(lines_of(doc, *PAGES['S6b_refs']), r'^References to Table S6b', r'^Dataset S7', 'dot'),
                 'dot', 'S6b list (p. 153-154)')
    reg.add_list('S7', parse_list(lines_of(doc, *PAGES['S7_refs']), r'^References to Table S7', r'^Dataset S8', 'paren'),
                 'paren', 'S7 list (p. 163-166)')
    # whole-table sources named in the dataset notes
    chown = notes_citation(doc, PAGES['S3_table'][0], r'Chown, S\. L\. et al\. \(2007\)', r'282[–-]290\.', 'S3 Chown')
    white = notes_citation(doc, PAGES['S5_notes'][0], r'White, C\. R\., Phillips', r'\(2006\)\.', 'S5 White')
    fishbase = notes_citation(doc, PAGES['S5_notes'][0], r'Database www\.fishbase\.org', r'Table S5c\.', 'S5c FishBase')
    mw = notes_citation(doc, PAGES['S6_notes'][0], r'McKechnie A\.E\., Wolf B\.O\. \(2004\)', r'502-521\.', 'S6 McKechnie')
    reg.add('S3:Chown et al. 2007', chown, 'Dataset S3 note: the insect table is Chown et al. (2007) Appendix S2 '
            '(compilation; the rows route to Chown_etal_2007 at hop 2)')
    reg.add('S5:White et al. 2006', white, 'Dataset S5 note: Tables S5a (amphibians) and S5b (reptiles) are the '
            'per-species minima of White et al. (2006) (compilation)')
    reg.add('S5c:FishBase', fishbase, 'Dataset S5 note: Table S5c, per-species minima of the FishBase metabolism '
            'table (database)', 'database, no DOI: www.fishbase.org as searched in 2008')
    reg.add('S6:McKechnie & Wolf 2004', mw, 'Dataset S6 note: the MW rows of Table S6a are McKechnie & Wolf (2004) '
            'Tables A1 (Reynolds & Lee 1996 compilation) and A2 (compilation)')

    # ---- S1a ----
    log('Tables')
    s1 = parse_s1a(doc)
    csv1 = read_csv('S1a.csv')
    if len(csv1) != len(s1):
        err(f'S1a: {len(csv1)} CSV rows, {len(s1)} PDF records')
    for i, r in enumerate(csv1):
        p = s1[int(r['row_num']) - 1]
        if p['row'] != int(r['row_num']):
            err(f'S1a row {r["row_num"]}: PDF record {p["row"]}')
        if fold(r['valid_name']).split()[:1] != fold(p['valid_name']).split()[:1]:
            log(f'  S1a row {r["row_num"]}: CSV valid_name {r["valid_name"][:50]!r} vs PDF {p["valid_name"][:50]!r}')
        mains, extra = split_source_cell(p['source'])
        keys = resolve_keys('S1a', mains + extra, aliases=S1A_ALIASES, context=p['source'])
        records.append({'table': 'S1a', 'row': i + 1, 'species': r['valid_name'], 'ref_keys': keys,
                        'source_text': p['source']})

    # ---- S2b through S2a ----
    s2a = parse_s2a(doc)
    csv2 = read_csv('S2b.csv')
    by_species = defaultdict(list)
    for p in s2a:
        by_species[fold(p['species'])].append(p)
    for i, r in enumerate(csv2):
        sp_rows = by_species.get(fold(r['species']), [])
        cands = [p for p in sp_rows if num_eq(p['qWkg'], r['qWkg']) and num_eq(p['Mpg'].strip('[]'), r['Mpg_pg'])]
        if not cands:
            cands = [p for p in sp_rows if num_eq(p['qWkg'], r['qWkg'])]
        if not cands:
            cands = [p for p in sp_rows if num_eq(p['Mpg'].strip('[]'), r['Mpg_pg'])]
            if len(cands) == 1:
                log(f'  S2b row {i + 1} {r["species"]!r}: qWkg {r["qWkg"]} is not in Table S2a (row {cands[0]["row"]} has '
                    f'{cands[0]["qWkg"]}); joined by species and Mpg')
        if not cands:
            err(f'S2b row {i + 1} {r["species"]!r} qWkg {r["qWkg"]} Mpg {r["Mpg_pg"]}: no S2a row')
            records.append({'table': 'S2b', 'row': i + 1, 'species': r['species'], 'ref_keys': '', 'source_text': ''})
            continue
        refs = []
        for p in cands:
            if p['reference'] not in refs:
                refs.append(p['reference'])
        if len(refs) > 1:
            log(f'  S2b row {i + 1} {r["species"]!r}: the minimum qWkg {r["qWkg"]} is reported by {len(refs)} S2a rows '
                f'({[(p["row"], p["reference"]) for p in cands]}); all keyed')
        dks = []
        for x in refs:
            mains, extra = split_source_cell(x)
            dks.extend(mains + extra)
        keys = resolve_keys('S2a', dks, aliases=S2A_ALIASES)
        records.append({'table': 'S2b', 'row': i + 1, 'species': r['species'], 'ref_keys': keys,
                        'source_text': '; '.join(f'S2a row {p["row"]}, Source {p["source"]}: {p["reference"]}' for p in cands)})

    # ---- S3 ----
    s3 = parse_s3(doc)
    csv3 = read_csv('S3.csv')
    chown_rows = read_csv(os.path.join('..', 'Chown_etal_2007', 'AppendixS2_insect_mass_parsed.csv'))
    chown_by = defaultdict(list)
    for c in chown_rows:
        chown_by[(fold(c['Species']), round(float(c['Mass_mg']), 4))].append(c)
    used = set()
    agree = disagree = in_chown = n_green = n_prefix = 0
    not_in_chown = []
    for i, r in enumerate(csv3):
        cands = [j for j, p in enumerate(s3) if j not in used and fold(p['species']) == fold(r['species'])
                 and num_eq(p['M_mg'], r['M_mg'])]
        if not cands:          # the CSV drops a trailing numeral ('Griburius sp.' for 'Griburius sp. 1')
            cands = [j for j, p in enumerate(s3) if j not in used and num_eq(p['M_mg'], r['M_mg'])
                     and (fold(p['species']).startswith(fold(r['species'])) or fold(r['species']).startswith(fold(p['species'])))]
            if cands:
                n_prefix += 1
        if not cands:
            err(f'S3 row {i + 1} {r["species"]!r} M {r["M_mg"]}: no PDF row')
            records.append({'table': 'S3', 'row': i + 1, 'species': r['species'], 'ref_keys': 'S3:Chown et al. 2007',
                            'source_text': ''})
            continue
        j = cands[0]
        used.add(j)
        p = s3[j]
        ch = chown_by.get((fold(p['species']), round(float(p['M_mg']), 4)), [])
        note = ''
        if p['green'] == 'TRUE':
            n_green += 1
            keys = '; '.join(f'S3:{k}' for k in p['ref_marks'].split('; ') if k and k != '*')
            records.append({'table': 'S3', 'row': i + 1, 'species': r['species'], 'ref_keys': keys,
                            'source_text': f'superscript {p["ref_marks"]} (green row: added by Makarieva et al. to the Chown et al. 2007 set)'})
            if ch:
                log(f'  S3 row {i + 1} {p["species"]!r}: green row also present in Chown_etal_2007 ({[c["ref_keys"] for c in ch]})')
            continue
        if ch:
            in_chown += 1
            if any(c['ref_keys'] == p['ref_marks'] for c in ch):
                agree += 1
            else:
                disagree += 1
                note = f' (Chown row marks {[c["ref_keys"] for c in ch]})'
        else:
            not_in_chown.append(f'{p["species"]} {p["M_mg"]} [{p["ref_marks"]}]')
            note = ' (no Chown_etal_2007 row with this species and mass)'
        records.append({'table': 'S3', 'row': i + 1, 'species': r['species'], 'ref_keys': 'S3:Chown et al. 2007',
                        'source_text': f'superscript {p["ref_marks"]}{note}'})
    log(f'S3: {len(csv3)} CSV rows joined to the PDF ({n_prefix} by species prefix); {n_green} green rows keyed to their '
        f'numbered reference; of the {len(csv3) - n_green} black rows {in_chown} have a Chown_etal_2007 row with the '
        f'same species and mass (superscripts agree with Chown\'s marks on {agree}, differ on {disagree}) and '
        f'{len(not_in_chown)} have none: {"; ".join(not_in_chown) or "-"}; PDF rows unused: {len(s3) - len(used)}')
    same = sum(1 for k, c in s3_list if c == next((cc['raw_citation'] for cc in CHOWN_REFS if cc['key'] == k), None))
    log(f'S3 list: {same} of {len(s3_list)} entries byte-identical to Chown_etal_2007/references.csv')

    # ---- S4 ----
    s4 = parse_s4(doc)
    csv4 = read_csv('S4.csv')
    s4_mismatch = []
    if len(csv4) != len(s4):
        err(f'S4: {len(csv4)} CSV rows, {len(s4)} PDF records')
    for i, r in enumerate(csv4):
        if i >= len(s4):
            break
        p = s4[i]
        if fold(p['species']) != fold(r['Species']) or not num_eq(p['Mg'], r['Mg']) or not num_eq(p['TC'] or 'nan', r['TC'] or 'nan'):
            if not any(w in fold(p['species']).split() for w in fold(r['Species']).split() if len(w) > 3):
                err(f'S4 row {i + 1}: CSV {r["Species"]!r} vs PDF {p["species"]!r}: not the same row')
            else:
                s4_mismatch.append(f'{i + 1} {r["Species"]} (CSV Mg {r["Mg"]} TC {r["TC"]}; PDF {p["species"]} Mg {p["Mg"]} TC {p["TC"]})')
        if not p['source']:
            records.append({'table': 'S4', 'row': i + 1, 'species': r['Species'], 'ref_keys': '', 'source_text': ''})
            continue
        mains, extra = split_source_cell(p['source'])
        keys = resolve_keys('S4', mains + extra, aliases=S4_ALIASES, context=p['source'])
        records.append({'table': 'S4', 'row': i + 1, 'species': r['Species'], 'ref_keys': keys,
                        'source_text': p['source']})

    log(f'S4: {len(csv4)} CSV rows joined by position; {len(s4_mismatch)} rows whose CSV species / Mg / TC differ from '
        f'the PDF row (the committed table mis-split these rows): {"; ".join(s4_mismatch) or "-"}')

    # ---- S5 ----
    for table, key in (('S5a', 'S5:White et al. 2006'), ('S5b', 'S5:White et al. 2006'), ('S5c', 'S5c:FishBase')):
        for i, r in enumerate(read_csv(f'{table}.csv')):
            records.append({'table': table, 'row': i + 1, 'species': r['Species'], 'ref_keys': key,
                            'source_text': 'Dataset S5 note'})

    # ---- S6b and S6a ----
    s6b = parse_s6b(doc)
    csv6b = read_csv('S6b.csv')
    s6b_keys = []
    for p in s6b:
        dks = expand_year_letters(p['references'])
        p['ref_keys'] = resolve_keys('S6b', dks, aliases=S6B_ALIASES)
        s6b_keys.append(p['ref_keys'])
    s6b_by = defaultdict(list)
    for p in s6b:
        s6b_by[fold(p['species'])].append(p)
    found6b = set()
    for i, r in enumerate(csv6b):
        cands = [p for p in s6b_by.get(fold(r['Species']), [])
                 if num_eq(p['Mg'], r['Mg']) and p['Season'] == r['Season'] and p['Time'] == r['Time']
                 and num_eq(p['QkJday'], r['QkJday'])]
        if len(cands) != 1:
            err(f'S6b row {i + 1} {r["Species"]!r} {r["Mg"]} {r["Season"]} {r["Time"]} {r["QkJday"]}: {len(cands)} PDF rows')
            records.append({'table': 'S6b', 'row': i + 1, 'species': r['Species'], 'ref_keys': '', 'source_text': ''})
            continue
        p = cands[0]
        found6b.add(id(p))
        records.append({'table': 'S6b', 'row': i + 1, 'species': r['Species'], 'ref_keys': p['ref_keys'],
                        'source_text': p['references']})
    missing6b = [p for p in s6b if id(p) not in found6b]
    log(f'S6b: {len(csv6b)} CSV rows joined; {len(missing6b)} PDF rows absent from S6b.csv: '
        + ', '.join(f'{p["species"]} {p["Mg"]} {p["Season"]}{p["Time"]}' for p in missing6b))
    csv6a = read_csv('S6a.csv')
    n_g = n_mw = 0
    for i, r in enumerate(csv6a):
        if r['Src'] == 'MW':
            n_mw += 1
            records.append({'table': 'S6a', 'row': i + 1, 'species': r['Species'], 'ref_keys': 'S6:McKechnie & Wolf 2004',
                            'source_text': 'Src MW'})
            continue
        if r['Src'] != 'G':
            err(f'S6a row {i + 1}: Src {r["Src"]!r}')
            continue
        n_g += 1
        name = fold(r['Species'])
        cands = s6b_by.get(name, [])
        if not cands:
            words = name.split()
            cands = [p for k, ps in s6b_by.items() for p in ps
                     if k.split()[:2] == words[:2]]
        night = [p for p in cands if p['Time'] == 'N']
        pool = night or cands
        if not pool:
            err(f'S6a row {i + 1} {r["Species"]!r} (G): no S6b row')
            records.append({'table': 'S6a', 'row': i + 1, 'species': r['Species'], 'ref_keys': '', 'source_text': 'Src G'})
            continue
        # the minimum night-time mass-specific rate, qWkg = QkJday / Mg * 1e6 / 86400
        best = min(pool, key=lambda p: float(p['QkJday']) / float(p['Mg']))
        q = float(best['QkJday']) / float(best['Mg']) * 1e6 / 86400
        flag = ''
        if not num_eq(best['Mg'], r['Mg']) or abs(q - float(r['qWkg'])) > 0.06:
            flag = f' (S6a Mg {r["Mg"]} qWkg {r["qWkg"]} vs S6b row Mg {best["Mg"]} q {q:.2f})'
            log(f'  S6a row {i + 1} {r["Species"]}: G row does not reproduce the chosen S6b row{flag}')
        records.append({'table': 'S6a', 'row': i + 1, 'species': r['Species'], 'ref_keys': best['ref_keys'],
                        'source_text': f'Src G -> S6b {best["species"]} {best["Mg"]} {best["Season"]}{best["Time"]}: '
                                       f'{best["references"]}{flag}'})
    log(f'S6a: {n_mw} MW rows -> McKechnie & Wolf 2004; {n_g} G rows -> the S6b references')

    # ---- S7 ----
    s7 = parse_s7(doc)
    csv7 = read_csv('S7.csv')
    if len(csv7) != len(s7):
        err(f'S7: {len(csv7)} CSV rows, {len(s7)} PDF records')
    for i, r in enumerate(csv7):
        p = s7[int(r['row_num']) - 1]
        if fold(r['species']).split()[:1] != fold(p['species']).split()[:1]:
            log(f'  S7 row {r["row_num"]}: CSV species {r["species"][:50]!r} vs PDF {p["species"][:50]!r}')
        mains, extra = split_source_cell(p['source'])
        keys = resolve_keys('S7', mains + extra, aliases=S7_ALIASES, context=p['source'])
        records.append({'table': 'S7', 'row': i + 1, 'species': r['species'], 'ref_keys': keys,
                        'source_text': p['source']})

    # ---- summary and checks ----
    cited = Counter()
    for rec in records:
        for k in rec['ref_keys'].split('; '):
            if k:
                cited[k] += 1
    bad = [k for k in cited if k not in reg.entries]
    for (table, dk, why), n in sorted(unresolved.items()):
        if why == 'ambiguous':
            err(f'{table}: data key {dk!r} {why} ({n} record(s))')
        else:
            log(f'  unresolved: {table} data key {dk!r} {why} ({n} record(s)); kept as typed')
    for table, dk, key, rule in reg.fallbacks:
        log(f'  fallback: {table} {dk!r} -> {key!r} ({rule})')
    log(f'Keys resolved by a fallback rule: {len(set((t, d) for t, d, _, _ in reg.fallbacks))}')
    per_table = Counter(rec['table'] for rec in records)
    keyed = Counter(rec['table'] for rec in records if rec['ref_keys'])
    log('Records: ' + ', '.join(f'{t} {keyed[t]}/{per_table[t]}' for t in per_table))
    log(f'Keys cited: {len(cited)} distinct ({sum(cited.values())} record-key links); references.csv entries: '
        f'{len(reg.entries)}; entries cited by no record: {sum(1 for k in reg.entries if k not in cited)}')
    log(f'Keys not in references.csv: {bad or "none"}')
    if errors:
        log(f'{len(errors)} error(s); nothing written')
        return 1
    write_csv(OUT_REFS, [{'key': k, **v} for k, v in reg.entries.items()], ['key', 'citation', 'note', 'owner_review'])
    write_csv(OUT_RECS, records, ['table', 'row', 'species', 'ref_keys', 'source_text'])
    write_csv(OUT_S2A, s2a, ['row', 'group', 'species', 'qWkg', 'Mpg', 'TC', 'source', 'reference'])
    write_csv(OUT_S3, s3, ['page', 'species', 'ref_marks', 'green', 'family', 'order', 'M_mg', 'Q_uW'])
    write_csv(OUT_S6B, s6b, ['order', 'species', 'N', 'Mg', 'Season', 'Time', 'QkJday', 'references', 'ref_keys'])
    log(f'wrote {os.path.basename(OUT_REFS)}, {os.path.basename(OUT_RECS)}, {os.path.basename(OUT_S2A)}, '
        f'{os.path.basename(OUT_S3)}, {os.path.basename(OUT_S6B)}')
    return 0


# spellings of the source cells that differ from the list entries (data key -> list key)
S1A_ALIASES = {'BM': 'Holt 1984', 'BM9': 'Holt et al. 1994'}   # Bergey's Manuals (SI note to Table S1a)
S2A_ALIASES = {}
S4_ALIASES = {}
S6B_ALIASES = {}
S7_ALIASES = {}
CHOWN_REFS = []
try:
    with open(os.path.join(HERE, '..', 'Chown_etal_2007', 'references.csv'), newline='', encoding='utf-8') as _fh:
        CHOWN_REFS = list(csv.DictReader(_fh))
except OSError:
    pass

if __name__ == '__main__':
    sys.exit(main(sys.argv))
