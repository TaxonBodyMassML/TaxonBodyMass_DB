"""
build_references.py - Build references.csv for Tucker_etal_2014b.

Extracts the Appendix S1 bibliography from geb12194-sup-0001-si-2.pdf, parses
multi-line references, generates abbreviated keys (matching the 'References'
column in Tucker_etal_2014b.csv), and searches Crossref for DOIs.

Run from the DB root:
  python3 sources/databases/Tucker_etal_2014b/build_references.py
"""

import csv, json, os, re, subprocess, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PDF_FILE   = os.path.join(SCRIPT_DIR, 'geb12194-sup-0001-si-2.pdf')
DATA_CSV   = os.path.join(SCRIPT_DIR, 'Tucker_etal_2014b.csv')
REFS_OUT   = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache_tucker2.json')

REF_COL = 'References'
BIBLIO_START = 'Appendix S1 References'
BIBLIO_END   = 'Appendix S2 References'

# Manual aliases: norm_abbrev -> norm_lookup_key (for author-order mismatches, etc.)
NORM_ALIASES = {
    # Data lists second author first; bibliography has Skinner as first author
    'van aarde and skinner 1986': 'skinner and aarde 1986',
    # Babb bibliography has typo 'nad' instead of 'and'; manual full citation below
    'babb and kennedy 1988': '_babb_kennedy_1988_manual',
    # Doebel bibliography has typo 'aB.' instead of 'and B.'; manual full citation below
    'doebel and mcginnes 1974': '_doebel_mcginnes_1974_manual',
    # Data has typo 'Scharzenberger' (missing 'w'); bibliography has 'Schwarzenberger'
    'scharzenberger and klingel 1995': 'schwarzenberger and klingel 1995',
}

# Manual full citations for entries with uncorrectable bibliography typos
MANUAL_CITS = {
    '_babb_kennedy_1988_manual': (
        'Babb, J. G., and M. L. Kennedy. 1988. Home range of the coyote in western Tennessee. '
        'Proc. Ann. Conf. S. E. Assoc. Fish Wildlife Agencies 42:443-447.',
        '1988', 'Babb', 'Home range of the coyote in western Tennessee', 'Babb and Kennedy 1988'),
    '_doebel_mcginnes_1974_manual': (
        'Doebel, J. H., and B. S. McGinnis. 1974. Home range and activity of gray squirrel population. '
        'Journal of Wildlife Management 38:860-867.',
        '1974', 'Doebel', 'Home range and activity of gray squirrel population', 'Doebel and McGinnes 1974'),
}


def normalize(s):
    # Transliterate characters that NFD does not decompose
    _TRANSLIT = {'ø': 'o', 'Ø': 'O', 'æ': 'ae', 'Æ': 'AE', 'ß': 'ss',
                 'œ': 'oe', 'Œ': 'OE', 'ð': 'd', 'Ð': 'D', 'þ': 'th', 'Þ': 'TH'}
    for c, r in _TRANSLIT.items():
        s = s.replace(c, r)
    # Remove apostrophes/curly-quotes (O'Brien → OBrien → obrien)
    s = s.replace("'", '').replace('’', '').replace('‘', '')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    # CamelCase split before lowercasing (VanBallenberghe → Van Ballenberghe)
    s = re.sub(r'(?<=[a-z])([A-Z])', r' \1', s)
    s = re.sub(r'[^a-z0-9 ]', ' ', s.lower())
    return re.sub(r'\s+', ' ', s).strip()


def extract_pdf_text():
    """Extract plain text from the PDF using pdftotext."""
    result = subprocess.run(
        ['pdftotext', '-enc', 'UTF-8', PDF_FILE, '-'],
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    return result.stdout


def get_bibliography(text):
    """Extract the Appendix S1 bibliography lines from the full PDF text."""
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if BIBLIO_START in l), None)
    end   = next((i for i, l in enumerate(lines) if BIBLIO_END in l and i > start), None)
    if start is None or end is None:
        raise ValueError('Could not find bibliography section')
    return [l for l in lines[start+1:end] if l.strip()]


def is_new_ref(line):
    """A line starts a new reference if it begins with Author, M. Year. pattern."""
    line = line.strip()
    starts_like_author = bool(re.match(
        r'^(?:[A-Z\(]|(?:de|du|van|von|le|la|el)\s+[A-Z])', line))
    has_year = bool(re.search(r'\b(19|20)\d{2}\b', line[:200]))
    return starts_like_author and has_year


def split_merged(ref):
    """
    Split a joined ref that actually contains two refs concatenated.
    Pattern: '... vol:pages. Lastname, I. YEAR.' in the middle of the string.
    Returns a list of one or two refs.
    """
    # Find occurrences of ". CapSurname, Initial. " after the first year
    m_first_year = re.search(r'\b(19|20)\d{2}\b', ref)
    if not m_first_year:
        return [ref]
    after_first_year = ref[m_first_year.end():]
    # Look for pattern indicating a new author-year entry starts
    m_split = re.search(
        r'\.\s+([A-Z][a-zA-Z\-]{2,},\s+[A-Z]\.)',
        after_first_year)
    if not m_split:
        return [ref]
    split_pos = m_first_year.end() + m_split.start() + 1  # +1 to keep the period
    part1 = ref[:split_pos].strip()
    part2 = ref[split_pos:].strip()
    if part1 and part2:
        return [part1, part2]
    return [ref]


def join_refs(lines):
    """Join multi-line reference entries into single strings, then split merged ones."""
    refs = []
    current = ''
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if is_new_ref(line) and current:
            refs.append(current.strip())
            current = line
        else:
            current = (current + ' ' + line).strip() if current else line
    if current:
        refs.append(current.strip())
    # Post-split: detect refs that got incorrectly merged (e.g. Trapp+Travaini)
    result = []
    for r in refs:
        result.extend(split_merged(r))
    return result


def parse_ref(text):
    """
    Extract (abbreviated_key, year, first_surname, title_frag) from a full citation string.

    Citation format: "Lastname, F., and F. Lastname. YEAR. Title. Journal vol:pp."
    Key rules:
      - 1 author:  "Lastname Year"
      - 2 authors: "Lastname1 and Lastname2 Year"
      - 3+ authors: "Lastname1 et al. Year"
    Hyphens in surnames → spaces (e.g. "Abensperg-Traun" → "Abensperg Traun").
    Lowercase prefixes (de, du, van, von) captured as part of first surname.
    """
    text = re.sub(r'[\r\n]+', ' ', text).strip()

    m_year = re.search(r'\b(19|20)\d{2}[a-z]?\b', text)
    year = m_year.group(0)[:4] if m_year else ''
    before_year = text[:m_year.start()].strip().rstrip('.,') if m_year else text[:150]

    # First author surname: handles apostrophes (O'Brien), hyphens, lowercase prefixes
    m_first = re.match(
        r"^((?:de |du |van |von |le |la |el |d'|l')?"
        r"[A-Z\(][a-zA-ZÀ-ÿ'\-]+"
        r"(?:\s+[A-Z][a-zA-ZÀ-ÿ'\-]+)*)",
        text.strip())
    first_surname = m_first.group(1).strip() if m_first else ''

    m_and = re.search(r'\b[Aa]nd\s+', before_year)
    if m_and:
        before_and = before_year[:m_and.start()]
        if before_and.count(',') >= 3:
            key_authors = first_surname + ' et al.'
        else:
            after_and = before_year[m_and.end():]
            # Allow lowercase-prefix surnames and apostrophes in second author
            m2 = re.findall(r'\b([A-Za-z][a-zA-ZÀ-ÿ\'\-]{2,})\b', after_and)
            # Filter out likely initials (single uppercase + period already stripped)
            second_surname = m2[-1] if m2 else ''
            if second_surname:
                key_authors = first_surname + ' and ' + second_surname
            else:
                key_authors = first_surname + ' et al.'
    else:
        extra = re.findall(r',\s*[A-Z]\.\s+([A-Z][a-zA-ZÀ-ÿ\-]{2,})', before_year)
        key_authors = first_surname + ' et al.' if len(extra) >= 2 else first_surname

    key_authors = key_authors.replace('-', ' ')
    key = (key_authors + ' ' + year).strip()

    if m_year:
        after_year = text[m_year.end():].strip().lstrip('.,')
        title_frag = after_year[:120]
    else:
        title_frag = text[:120]

    return key, year, first_surname, title_frag


def crossref_search(title_frag, author, year, cache):
    """Search Crossref for a DOI given title fragment, author, and year."""
    query = f'{author} {year} {title_frag[:60]}'
    if query in cache:
        return cache[query]
    params = {
        'query': query,
        'rows': '5',
        'mailto': CROSSREF_EMAIL,
        'select': 'DOI,title,published',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{CROSSREF_EMAIL})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        cache[query] = None
        return None
    items = data.get('message', {}).get('items', [])
    cache[query] = items if items else None
    return cache[query]


def find_doi(title_frag, author, year, cache):
    """Return best DOI match from Crossref, or '' if not found."""
    items = crossref_search(title_frag, author, year, cache)
    if not items:
        return ''
    for item in items:
        cr_title = ' '.join(item.get('title', []))
        s = SequenceMatcher(None, normalize(title_frag[:80]), normalize(cr_title)).ratio()
        if s < 0.75:
            continue
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ''
        if year and pub_year and abs(int(pub_year) - int(year)) > 1:
            continue
        doi = item.get('DOI', '').strip()
        if doi:
            return doi
    return ''


def main():
    # 1. Get all unique abbreviated refs from data
    with open(DATA_CSV, newline='', encoding='latin1') as f:
        data_rows = list(csv.DictReader(f))
    individual_refs = set()
    for r in data_rows:
        val = r.get(REF_COL, '').strip()
        if not val:
            continue
        parts = re.split(r',\s*(?=[A-Z(])', val)
        for p in parts:
            p = re.sub(r'[\r\n]+', ' ', p).strip()
            if p:
                individual_refs.add(p)
    print(f'Unique individual refs in data: {len(individual_refs)}')

    # 2. Extract bibliography from PDF
    print('Extracting PDF text...')
    pdf_text = extract_pdf_text()
    bib_lines = get_bibliography(pdf_text)
    full_refs = join_refs(bib_lines)
    print(f'Full references parsed (after merge-split): {len(full_refs)}')

    # 3. Build lookup: normalized_key -> (full_text, year, first_surname, title_frag, raw_key)
    lookup = {}
    for ref in full_refs:
        key, year, surname, title_frag = parse_ref(ref)
        norm_key = normalize(key)
        if norm_key and norm_key not in lookup:
            lookup[norm_key] = (ref, year, surname, title_frag, key)
    # Add manual citations for bibliography typos
    for mankey, val in MANUAL_CITS.items():
        lookup[mankey] = val

    print(f'Lookup entries: {len(lookup)}')

    # 4. Load Crossref cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    # 5. Match each abbreviated ref to a full citation and find DOI
    output = []
    not_matched = []

    for abbrev in sorted(individual_refs):
        abbrev_clean = re.sub(r'[\r\n]+', ' ', abbrev).strip()
        norm_abbrev = normalize(abbrev_clean)
        norm_no_suffix = re.sub(r'(\d{4})[a-z]$', r'\1', norm_abbrev)

        # Check NORM_ALIASES first
        norm_abbrev_resolved = NORM_ALIASES.get(norm_abbrev, norm_abbrev)
        norm_no_suffix_resolved = NORM_ALIASES.get(norm_no_suffix, norm_no_suffix)

        match = (lookup.get(norm_abbrev_resolved) or
                 lookup.get(norm_no_suffix_resolved) or
                 lookup.get(norm_abbrev) or
                 lookup.get(norm_no_suffix))

        if not match:
            # Prefix match: abbreviated key may differ slightly from generated key
            prefix = norm_no_suffix[:max(8, len(norm_no_suffix) - 5)]
            candidates = [(k, v) for k, v in lookup.items()
                          if k.startswith(prefix[:8]) and not k.startswith('_')]
            if len(candidates) == 1:
                match = candidates[0][1]
            elif len(candidates) > 1:
                best = min(candidates, key=lambda x: abs(len(x[0]) - len(norm_abbrev)))
                match = best[1]

        if not match:
            # Year + first-surname fallback: useful when citation format differs
            # (e.g. Jones et al. 2009 vs jones 2009 for PanTHERIA)
            m_yr = re.search(r'\b(\d{4})\b', norm_abbrev)
            if m_yr:
                yr = m_yr.group(1)
                first_word = norm_abbrev.split()[0] if norm_abbrev else ''
                surname_candidates = [(k, v) for k, v in lookup.items()
                                      if k.endswith(' ' + yr) and k.split()[0] == first_word
                                      and not k.startswith('_')]
                if len(surname_candidates) == 1:
                    match = surname_candidates[0][1]

        if match:
            full_text, year, surname, title_frag, raw_key = match
            is_grey = bool(re.search(
                r'\b(thesis|Thesis|Unpubl|unpubl|Ph\.D|M\.S\.|M\.Sc|book|Book|Press|press|'
                r'publisher|Publisher|edit|Edit|volume|Volume|chapter|Chapter|'
                r'Proc\.|conf\.|Conf\.|Rep\.|report|Report|Tech\.|tech\.|memo|Memo)\b',
                full_text))
            if is_grey or not year:
                doi = ''
                note = 'book' if is_grey else ''
            else:
                doi = find_doi(title_frag, surname, year, cache)
                note = ''
                time.sleep(0.2)
            output.append({'key': abbrev_clean, 'citation': full_text, 'doi': doi, 'note': note})
        else:
            not_matched.append(abbrev_clean)
            output.append({'key': abbrev_clean, 'citation': abbrev_clean, 'doi': '', 'note': 'not_matched'})

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write references.csv
    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    n_not_matched = len(not_matched)
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI, {n_not_matched} not matched')
    if not_matched:
        print(f'Not matched ({n_not_matched}): {not_matched}')


if __name__ == '__main__':
    main()
