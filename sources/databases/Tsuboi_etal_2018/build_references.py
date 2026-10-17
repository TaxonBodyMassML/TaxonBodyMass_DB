"""
build_references.py -- Tsuboi_etal_2018 citation DOI lookup

Reads references.csv (163 unique citation strings in the Tsuboi format
"Author Initial (Year) J.Abbrev. vol:pages" or "Author (Year) Book Title"),
parses author1/year/container/volume/first-page via regex, queries Crossref
with the bibliographic filter (no title available), accepts candidates whose
container, volume and first page all match, and writes the DOI back into
references.csv.

Run from the source folder or from the DB root:
  python3 sources/databases/Tsuboi_etal_2018/build_references.py

Requires: requests (pip install requests).
Polite pool: mailto in the query (set CROSSREF_EMAIL or edit below).
Cache: crossref_cache.json beside this script (survives reruns).
"""

import csv, json, os, re, time, sys
import urllib.request, urllib.parse

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REFS_CSV    = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE  = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

# ---------------------------------------------------------------------------
# Regex parser for "Author S et al. (Year) J.Abbrev. vol:pages"
# ---------------------------------------------------------------------------
YEAR_RE  = re.compile(r'\(\s*(\d{4})\s*\)')
VOL_PAGE = re.compile(r'\b(\d+)\s*[:(]\s*(\d+)(?:\s*[-–]\s*\d+)?\s*[.)$]?')
# Volume:first-page extractor (also handles "vol(issue):pages" where issue is in parens)
VOL_PAGE2 = re.compile(r'\b(\d+)\s*(?:\(\d+\))?\s*:\s*(\d+)')

def parse_tsuboi_citation(raw):
    """Return dict with author1, year, vol, first_page (strings), or None for self/book/database refs."""
    if re.search(r'this study|fishbase|in fishbase', raw, re.I):
        return None  # self or database
    m_year = YEAR_RE.search(raw)
    if not m_year:
        return None  # unparseable
    year = m_year.group(1)
    after_year = raw[m_year.end():].strip()
    # Extract vol:pages
    m_vp = VOL_PAGE2.search(after_year)
    if not m_vp:
        return None  # book or chapter without volume:pages
    vol = m_vp.group(1)
    first_page = m_vp.group(2)
    # Container = text between year and the volume number
    container_raw = after_year[:m_vp.start()].strip().rstrip('.,; ')
    # Author = first word before the year
    before_year = raw[:m_year.start()].strip()
    author1 = re.split(r'[\s,]', before_year)[0] if before_year else ''
    return dict(author1=author1, year=year, container=container_raw, vol=vol, first_page=first_page)

# ---------------------------------------------------------------------------
# Crossref biblio query + container/volume/page match
# ---------------------------------------------------------------------------
def crossref_query(author1, year, container, vol, first_page, cache, email=CROSSREF_EMAIL):
    """Query Crossref with author+year+volume+page, return best DOI or None."""
    key = f'{author1}|{year}|{vol}|{first_page}'
    if key in cache:
        return cache[key]
    # Build query URL
    params = {
        'query.bibliographic': f'{author1} {year} volume:{vol} page:{first_page}',
        'filter': f'type:journal-article',
        'rows': '5',
        'mailto': email,
        'select': 'DOI,title,author,published,volume,page,container-title'
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{email})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f'  ERROR querying Crossref for {key}: {e}')
        cache[key] = None
        return None
    items = data.get('message', {}).get('items', [])
    for item in items:
        # Check volume and first-page match
        item_vol = str(item.get('volume', '') or '').strip()
        item_page = str(item.get('page', '') or '').strip().split('-')[0].strip()
        item_year = str((item.get('published', {}).get('date-parts') or [['']])[0][0])
        if item_vol == vol and item_page == first_page and item_year == year:
            doi = item.get('DOI', '').strip()
            if doi:
                cache[key] = doi
                return doi
    cache[key] = None
    return None

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    # Load cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    rows = []
    with open(REFS_CSV, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames[:]
        rows = list(reader)

    if 'doi' not in fieldnames:
        fieldnames.append('doi')
    for row in rows:
        row.setdefault('doi', '')

    n_found = 0
    n_tried = 0
    for row in rows:
        key = row['key']
        raw = row['citation']
        if row.get('doi', '').strip():
            continue  # already have a DOI

        parsed = parse_tsuboi_citation(raw)
        if parsed is None:
            continue  # self/database/book/unparseable

        n_tried += 1
        doi = crossref_query(parsed['author1'], parsed['year'], parsed['container'],
                             parsed['vol'], parsed['first_page'], cache)
        if doi:
            row['doi'] = doi
            n_found += 1
            print(f'  {key}: DOI found {doi}  ({raw[:70]})')
        else:
            print(f'  {key}: not found  ({raw[:70]})')
        time.sleep(0.1)  # polite rate

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write updated CSV
    with open(REFS_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f'\nDone: {n_found}/{n_tried} DOIs found ({len(rows)} total references)')

if __name__ == '__main__':
    main()
