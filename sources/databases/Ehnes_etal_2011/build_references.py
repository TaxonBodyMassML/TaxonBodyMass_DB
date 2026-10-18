"""
build_references.py - Build references.csv for Ehnes_etal_2011.

The data CSV (ehnes2011_appendix_a.csv) has a 'studies' column: "METASTUDY   ORIGINAL_STUDY"
(split on 2+ whitespace). The ORIGINAL_STUDY (second part) is the primary mass source.
When ORIGINAL_STUDY == "this study", the mass is from Ehnes et al. 2011 themselves.

The PDF supplement (ele_1660_sm_meta-scaling-appendix.pdf) contains a 'References' section
with full bibliographic entries. This script:
  1. Extracts full citations from the PDF reference list.
  2. Matches abbreviated keys (e.g. "Anderson 1970", "Bailey & Singh 1977") to full citations.
  3. Searches Crossref for DOIs (for journal articles).
  4. Writes references.csv (key = abbreviated key, citation = full text, doi, note).

Run from the DB root:
  python3 sources/databases/Ehnes_etal_2011/build_references.py
"""

import csv, json, os, re, subprocess, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
PDF_FILE    = os.path.join(SCRIPT_DIR, 'ele_1660_sm_meta-scaling-appendix.pdf')
DATA_CSV    = os.path.join(SCRIPT_DIR, 'ehnes2011_appendix_a.csv')
REFS_OUT    = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE  = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

SELF_KEY    = 'this study'
SELF_DOI    = '10.1111/j.1461-0248.2011.01620.x'
SELF_CITATION = ('Ehnes, R.B., Rall, B.C. & Brose, U., 2011. Phylogenetic grouping, curvature '
                 'and metabolic scaling in terrestrial invertebrates. Ecology Letters, 14(10), '
                 '993-1000.')

# Unpublished / non-bibliography keys that can't be matched to the reference list
KEY_OVERRIDES = {
    'Chown lab unpublished data': ('Chown lab unpublished data', '', 'unpublished'),
}

# Species filter matching BodyMass_Ehnes_etal_2011.r
SP_KEEP = re.compile(r'^[A-Z][a-z]+ [a-z]+$')
SP_DROP = re.compile(r'\b(sp|spp|cf|aff|juv)\b')

ADULT_TYPE = re.compile(r'^adult|female|male', re.IGNORECASE)
MASS_DROP  = re.compile(r'^alternat|^%|pred mass|^average (genus|order)', re.IGNORECASE)


def normalize_hyphens(s):
    # Replace Unicode hyphen/dash variants (U+2010-U+2015, soft hyphen U+00AD) with ASCII -
    return re.sub("[‐-―­]", "-", s)


def normalize(s):
    s = normalize_hyphens(s)
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub("[^a-z0-9 ]", " ", s.lower())
    return re.sub(r"\s+", " ", s).strip()


def extract_pdf_text():
    result = subprocess.run(
        ['pdftotext', '-enc', 'UTF-8', PDF_FILE, '-'],
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    return result.stdout


def parse_refs_from_pdf(pdf_text):
    """
    Parse full bibliographic entries from the 'References' section.
    Format: "Author(s), YEAR. Title. Journal, vol(issue), pages."
    Returns list of raw reference strings.
    """
    lines = pdf_text.splitlines()
    # Find "References" header
    start = None
    for i, l in enumerate(lines):
        if re.match(r'^\s*References\s*$', l.strip()):
            start = i
            break
    if start is None:
        return []

    ref_lines = []
    for line in lines[start+1:]:
        stripped = normalize_hyphens(line.strip())
        if not stripped:
            continue
        # Skip page headers/footers
        if re.match(r'^Ehnes et al\.?$', stripped) or re.match(r'^Invertebrate metabolism Appendix$', stripped):
            continue
        if re.match(r'^\d+$', stripped):
            continue
        ref_lines.append(stripped)

    # Join into individual references: each starts with "Author, YEAR." or "Author et al., YEAR."
    # A new ref starts when we see a capitalized word followed by comma and year (possibly with
    # a single letter suffix like 1977a).
    def is_new_ref(line):
        return bool(re.match(r'^[A-Z][a-zA-Z-À-ɏ]+[,.]', line)) and \
               bool(re.search(r'\b(19|20)\d{2}[a-z]?\b', line[:100]))

    refs = []
    current = ''
    for line in ref_lines:
        if is_new_ref(line) and current:
            refs.append(current.strip())
            current = line
        else:
            current = (current + ' ' + line).strip() if current else line
    if current:
        refs.append(current.strip())
    return refs


def parse_ref_entry(text):
    """
    Parse a full reference into (first_surname, year, title_frag, is_grey).
    Format: "Surname, I. et al., YEAR. Title. Journal, vol, pp."
         or "Surname, I. & Surname2, I., YEAR. Title..."
         or "Surname, I., YEAR. Title..."
    """
    text = re.sub(r'[\r\n]+', ' ', text).strip()
    # Normalize hyphens first so compound surnames parse correctly
    text_norm = normalize_hyphens(text)
    # Year: look for ", YEAR." or "(YEAR)"
    m_year = re.search(r',\s*((?:19|20)\d{2})\b', text_norm[:100])
    if not m_year:
        m_year = re.search(r'\b((?:19|20)\d{2})\b', text_norm[:100])
    year = m_year.group(1) if m_year else ''

    # First author surname: word before first comma (hyphens normalized)
    m_first = re.match(r'^([À-ɏA-Z][a-zA-ZÀ-ɏ\-]+)', text_norm)
    first_surname = m_first.group(1) if m_first else ''

    # Grey literature check
    is_grey = bool(re.search(
        r'\bPhD\b|\bthesis\b|\bThesis\b|\bbook\b|\bBook\b|\bIn:\b|'
        r'\bPress\b|\bpublisher\b|\bUniversity of\b|\bchapter\b',
        text, re.IGNORECASE))

    # Title fragment: text after the year
    if m_year:
        after_year = text[m_year.end():].lstrip('. ')
        # Title ends at first period-space-Capital pattern (start of journal)
        m_end = re.search(r'\.\s+[A-Z]', after_year)
        title_frag = after_year[:m_end.start()] if m_end else after_year[:100]
    else:
        title_frag = text[:100]
    title_frag = title_frag.strip().rstrip('.')

    return first_surname, year, title_frag.strip(), is_grey


def build_pdf_lookup(refs):
    """
    Build lookup: (norm_first_surname, year) -> (full_text, title_frag, is_grey).
    Also stores second author for disambiguation.
    """
    lookup = {}
    for ref in refs:
        first_surname, year, title_frag, is_grey = parse_ref_entry(ref)
        if not year:
            continue
        key = (normalize(first_surname), year)
        if key not in lookup:
            lookup[key] = []
        lookup[key].append((ref, title_frag, is_grey))
    return lookup


def match_abbrev_to_full(abbrev, lookup):
    """
    Match an abbreviated key like "Anderson 1970" or "Bailey & Singh 1977"
    or "Ford 1977a" to the full citation in lookup.
    Returns (full_text, title_frag, is_grey) or None.
    """
    abbrev = normalize_hyphens(abbrev)
    # Match year optionally followed by a single lowercase letter (e.g. 1977a)
    m_year = re.search(r'\b((?:19|20)\d{2})([a-z])?\b', abbrev)
    if not m_year:
        return None
    year = m_year.group(1)
    suffix = m_year.group(2) or ''  # '' or 'a', 'b', etc.
    author_part = abbrev[:m_year.start()].strip().rstrip(',')

    # First surname
    first_surname = re.split(r'\s+(?:&|et al\.?|and)\s*|\s{2,}', author_part)[0].strip()
    key = (normalize(first_surname), year)

    candidates = lookup.get(key, [])
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    # Disambiguate by second author
    m_and = re.search(r'\s+&\s+([A-Za-zÀ-ɏ\-]+)', author_part)
    if m_and:
        second = normalize(m_and.group(1))
        for cand in candidates:
            if second in normalize(cand[0][:80]):
                return cand

    # Disambiguate by year suffix (e.g. 1977a)
    if suffix:
        for cand in candidates:
            if re.search(rf'\b{year}{suffix}\b', cand[0], re.IGNORECASE):
                return cand

    # Fallback: first candidate
    return candidates[0]


def crossref_search(title_frag, author, year, cache):
    query = f'{author} {year} {title_frag[:60]}'
    if query in cache:
        return cache[query]
    params = {
        'query': query, 'rows': '5', 'mailto': CROSSREF_EMAIL,
        'select': 'DOI,title,published',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{CROSSREF_EMAIL})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception:
        cache[query] = None
        return None
    items = data.get('message', {}).get('items', [])
    cache[query] = items if items else None
    return cache[query]


def find_doi(title_frag, author, year, cache):
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


def load_unique_orig_studies():
    """
    Load the data CSV, apply species filter, extract unique original study
    values from the 'studies' column (second part after 2+ whitespace).
    """
    with open(DATA_CSV, newline='', encoding='utf-8', errors='replace') as f:
        rows = list(csv.DictReader(f))
    orig_set = set()
    for r in rows:
        sp = r.get('sp', '').strip()
        if not SP_KEEP.match(sp) or SP_DROP.search(sp):
            continue
        studies = r.get('studies', '').strip()
        parts = re.split(r'\s{2,}', studies)
        orig = parts[1].strip() if len(parts) >= 2 else parts[0].strip()
        if orig:
            orig_set.add(orig)
    return orig_set


def main():
    print('Extracting PDF references...')
    pdf_text = extract_pdf_text()
    pdf_refs = parse_refs_from_pdf(pdf_text)
    print(f'PDF references found: {len(pdf_refs)}')

    lookup = build_pdf_lookup(pdf_refs)
    print(f'Lookup entries: {sum(len(v) for v in lookup.values())} refs under '
          f'{len(lookup)} (surname, year) keys')

    orig_studies = load_unique_orig_studies()
    print(f'Unique original study values: {len(orig_studies)}')

    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    output = []
    not_matched = []

    # Add self-citation first
    if SELF_KEY in orig_studies:
        output.append({'key': SELF_KEY, 'citation': SELF_CITATION,
                       'doi': SELF_DOI, 'note': 'self'})
        orig_studies.discard(SELF_KEY)

    # Hard-coded overrides for unpublished / unresolvable keys
    for abbrev, (citation, doi, note) in KEY_OVERRIDES.items():
        if abbrev in orig_studies:
            output.append({'key': abbrev, 'citation': citation, 'doi': doi, 'note': note})
            orig_studies.discard(abbrev)
            print(f'[OVERRIDE: {abbrev[:45]}]  note={note}')

    for abbrev in sorted(orig_studies):
        match = match_abbrev_to_full(abbrev, lookup)
        if match:
            full_text, title_frag, is_grey = match
            _, year, _, _ = parse_ref_entry(full_text)
            first_surname = re.match(r'^([A-Za-zÀ-ɏ\-]+)', full_text)
            surname = first_surname.group(1) if first_surname else ''
            if is_grey or not year:
                doi = ''
                note = 'book' if is_grey else ''
            else:
                doi = find_doi(title_frag, surname, year, cache)
                note = ''
                time.sleep(0.2)
            print(f'[{abbrev[:45]}]  doi={doi[:35] if doi else ""}')
            output.append({'key': abbrev, 'citation': full_text, 'doi': doi, 'note': note})
        else:
            not_matched.append(abbrev)
            print(f'[NOT MATCHED: {abbrev[:45]}]')
            output.append({'key': abbrev, 'citation': abbrev, 'doi': '', 'note': 'not_matched'})

    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI, {len(not_matched)} not matched')
    if not_matched:
        print('Not matched:', not_matched)


if __name__ == '__main__':
    main()
