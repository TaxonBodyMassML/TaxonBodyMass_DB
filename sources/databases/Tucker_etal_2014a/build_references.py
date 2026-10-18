"""
build_references.py - Build references.csv for Tucker_etal_2014a.

Reads abbreviated body-mass source strings from TrophicLevel_Appendix1.csv
(column 'Predator Body Mass Source'), matches them to full citations from
References.csv, and searches Crossref for DOIs.

Run from the DB root:
  python3 sources/databases/Tucker_etal_2014a/build_references.py
"""

import csv, json, os, re, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_CSV   = os.path.join(SCRIPT_DIR, 'TrophicLevel_Appendix1.csv')
REFS_SRC   = os.path.join(SCRIPT_DIR, 'References.csv')
REFS_OUT   = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache_tucker1.json')

REF_COL = 'Predator Body Mass Source'

# Manual aliases: abbreviated key (as in data) -> key to use in our references.csv
# Used when spelling differs from the exact abbreviated form.
ALIASES = {
    'Cabone 2007':             'Carbone et al. 2007',
    'Heide jorgenson  2002':   'Heide-Jorgensen 2002',
    'Bornemann & Plötz 2005':  'Bornemann & Plötz 2005',
}

# Known refs not in References.csv - use brief note
MISSING = {
    'Gubbins et al. 2002':       '',
    'Rodrigo et al. 2010':       '',
    'Scheffer 1972':             '',
    'Sheppard et al. 2006':      '',
    'Kipps et al. 2002':         '',
    'Thibault et al. 2003':      '',
    'Tracey Rogers, unpublished':'',
    'Carbone et al. 2008':       '',
}


def normalize(s):
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9 ]', ' ', s.lower()).strip()


def sim(a, b):
    return SequenceMatcher(None, normalize(a), normalize(b)).ratio()


def parse_full_citation(text):
    """Extract (surname1_normalized, year) from full citation string."""
    text = text.strip().strip('"')
    # Year in parentheses
    m = re.search(r'\((\d{4})\)', text)
    year = m.group(1) if m else ''
    # First author surname: first word(s) up to initials like 'P.J.N.'
    # Handle 'de Bruyn', 'van Vuren' etc. by taking text before first initial
    m2 = re.match(r'^([\w\-][\w\-]*(?:\s+(?:de|van|von|le|la|du|el)\s+[\w\-]+)*)', text, re.UNICODE)
    raw = m2.group(1).strip() if m2 else ''
    surname = normalize(raw)
    return surname, year


def parse_abbreviated(key):
    """Extract (surname1_normalized, year) from abbreviated ref like 'Jones et al. 2009'."""
    key = key.strip()
    # Year: last 4-digit number
    m = re.search(r'(\d{4})', key)
    year = m.group(1) if m else ''
    # First author: take everything before 'et al.', '&', ' and ', or year
    part = re.split(r'\s+et\s+al|\s+&|\s+and\s+|\s+\d{4}', key, maxsplit=1)[0].strip()
    surname = normalize(part)
    return surname, year


def crossref_search(query, cache):
    if query in cache:
        return cache[query]
    params = {
        'query': query,
        'rows': '5',
        'mailto': CROSSREF_EMAIL,
        'select': 'DOI,title,published,author',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{CROSSREF_EMAIL})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f'  Crossref ERROR: {e}')
        cache[query] = None
        return None
    items = data.get('message', {}).get('items', [])
    cache[query] = items if items else None
    return cache[query]


def find_doi(citation_text, year, cache):
    """Search Crossref for a DOI matching citation_text."""
    # Extract title fragment (heuristic: text after first period)
    m = re.search(r'\(\d{4}\)\.\s+(.+?)[\.\,]', citation_text)
    title_frag = m.group(1)[:80] if m else citation_text[:80]
    # First author
    m2 = re.match(r'^([A-Za-z][A-Za-zÀ-ÿ\-]+)', citation_text.strip('"').strip())
    author = m2.group(1) if m2 else ''
    query = f'{author} {year} {title_frag[:60]}'
    print(f'  searching: {query[:80]}')
    items = crossref_search(query, cache)
    if not items:
        print(f'  -> not found')
        return ''
    for item in items:
        cr_title = ' '.join(item.get('title', []))
        s = sim(title_frag, cr_title)
        if s < 0.75:
            continue
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ''
        if year and pub_year and abs(int(pub_year) - int(year)) > 1:
            continue
        doi = item.get('DOI', '').strip()
        if doi:
            print(f'  -> {doi} (sim={s:.2f})')
            return doi
    print(f'  -> not found')
    return ''


def main():
    # 1. Read data file and collect all individual abbreviated refs
    with open(DATA_CSV, newline='', encoding='latin1') as f:
        rows = list(csv.DictReader(f))

    raw_keys_per_row = []
    all_individual = set()
    for r in rows:
        val = r.get(REF_COL, '').strip()
        if val in ('', '-'):
            raw_keys_per_row.append([])
            continue
        parts = re.split(r', (?=[A-Z])', val)
        parts = [p.strip() for p in parts if p.strip()]
        raw_keys_per_row.append(parts)
        for p in parts:
            all_individual.add(p)

    print(f'Unique individual refs in data: {len(all_individual)}')

    # 2. Parse full citations from References.csv
    full_cits = []
    with open(REFS_SRC, newline='', encoding='utf-8-sig') as f:
        content = f.read()
    # Each full citation is a quoted or unquoted line
    for line in content.splitlines():
        line = line.strip().strip('"').strip()
        if not line or line.startswith('Appendx'):
            continue
        full_cits.append(line)
    print(f'Full citations in References.csv: {len(full_cits)}')

    # Build lookup: (surname_lower, year) -> full citation
    lookup = {}
    for cit in full_cits:
        surname, year = parse_full_citation(cit)
        key_tuple = (surname, year)
        if key_tuple not in lookup:
            lookup[key_tuple] = cit

    # 3. Load Crossref cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    # 4. Build the references.csv entries
    output = []
    not_matched = []

    for abbrev in sorted(all_individual):
        # Resolve alias
        canonical = ALIASES.get(abbrev, abbrev)

        # Skip known-missing references
        if canonical in MISSING or abbrev in MISSING:
            print(f'[MISSING] {abbrev}')
            output.append({'key': abbrev, 'citation': abbrev, 'doi': '', 'note': 'not_in_refs'})
            continue

        # Special: Tracey Rogers unpublished
        if 'unpublished' in abbrev.lower():
            output.append({'key': abbrev, 'citation': abbrev, 'doi': '', 'note': 'unpublished'})
            continue

        # Match to full citation
        surname, year = parse_abbreviated(canonical)  # both already normalized
        full = lookup.get((surname, year), '')

        # Fallback: prefix match (handles slight spelling variants)
        if not full:
            for (s, y), cit in lookup.items():
                if y == year and (s.startswith(surname[:5]) or surname.startswith(s[:5])):
                    full = cit
                    break

        if full:
            print(f'[MATCH] {abbrev!r}')
            print(f'        {full[:80]}')
            # Search Crossref for DOI
            doi = find_doi(full, year, cache)
            time.sleep(0.3)
            output.append({'key': abbrev, 'citation': full, 'doi': doi, 'note': ''})
        else:
            print(f'[NOMATCH] {abbrev!r}')
            not_matched.append(abbrev)
            output.append({'key': abbrev, 'citation': abbrev, 'doi': '', 'note': 'not_matched'})

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # 5. Write references.csv
    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI')
    if not_matched:
        print(f'Not matched ({len(not_matched)}): {not_matched}')


if __name__ == '__main__':
    main()
