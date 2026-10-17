"""
build_references.py -- Cai_etal_2025 citation DOI lookup

Reads the unique Ref.BodyMass values from Dataset S27.csv, classifies each as
paper / database / website / self, queries Crossref by full title for the paper
entries, and writes references.csv with keys c001-c099 (sorted by descending
frequency in the source data).

Run from the DB root or from the source folder:
  python3 sources/databases/Cai_etal_2025/build_references.py

Requires: requests (pip install requests).
Polite pool: CROSSREF_EMAIL below.
Cache: crossref_cache.json beside this script.
"""

import csv, json, os, re, time
import urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_CSV  = os.path.join(SCRIPT_DIR, 'Dataset S27.csv')
REFS_CSV    = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE  = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

# ---------------------------------------------------------------------------
# Classification helpers
# ---------------------------------------------------------------------------
DATABASES = {
    'fishbase', 'anage', 'sealifebase', 'gbif', 'animal diversity web',
    'animals diversity web', 'birds of the world', 'amphibiaweb',
    'society for marine mammalogy', 'australia_threatened_species_database',
    'fauna of china',
}
WEBSITE_PREFIXES = ('http://', 'https://', 'www.')
SELF_STRINGS = {'estimated by total length'}

def classify(raw):
    """Return 'database', 'website', 'self', 'grey', or 'paper'."""
    low = raw.lower().strip()
    if low in SELF_STRINGS:
        return 'self'
    if any(low.startswith(p) for p in WEBSITE_PREFIXES):
        return 'website'
    if low in DATABASES:
        return 'database'
    # Check for known database names in the string
    for db in ('wikipedia', 'worldspecies.org', 'baidu', 'animalia.bio'):
        if db in low:
            return 'website'
    # Contains an explicit DOI?
    if low.startswith('doi:') or 'doi.org/' in low:
        return 'doi_inline'
    return 'paper'

def extract_inline_doi(raw):
    """Pull a DOI from 'doi:10.xxx/...' or 'https://doi.org/10.xxx/...' strings."""
    m = re.search(r'10\.\d{4,}/\S+', raw)
    return m.group(0).rstrip('.,;)') if m else None

# ---------------------------------------------------------------------------
# Crossref title query
# ---------------------------------------------------------------------------
def title_sim(a, b):
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()

def crossref_by_title(title, cache, email=CROSSREF_EMAIL):
    """Query Crossref by title; return DOI with sim >= 0.90, or None."""
    key = f'title:{title}'
    if key in cache:
        return cache[key]
    params = {
        'query.title': title,
        'filter': 'type:journal-article',
        'rows': '5',
        'mailto': email,
        'select': 'DOI,title,published',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{email})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f'  ERROR: {e}')
        cache[key] = None
        return None
    items = data.get('message', {}).get('items', [])
    for item in items:
        cr_titles = item.get('title', [])
        cr_title = cr_titles[0] if cr_titles else ''
        sim = title_sim(title, cr_title)
        if sim >= 0.90:
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
    # Load source data to get frequency table
    with open(SOURCE_CSV, newline='', encoding='utf-8-sig') as f:
        # skip title row
        reader = csv.DictReader(f, skipinitialspace=True)
        rows = list(reader)
    # The real header is row 2 (index 1 after skip=1)
    # Re-read with skip=1
    with open(SOURCE_CSV, newline='', encoding='utf-8-sig') as f:
        next(f)  # skip first descriptor row
        reader = csv.DictReader(f)
        rows = list(reader)

    # Get Ref.BodyMass frequencies (same filter as BodyMass_Cai_etal_2025.r)
    from collections import Counter
    freq = Counter()
    for row in rows:
        ref = (row.get('Ref.BodyMass') or '').strip()
        if not ref:
            continue
        # Drop imputed rows (same logic as R script)
        if ref in ('Estimated', 'Sister species', 'My'):
            continue
        if re.match(r'^Average of (genus|family)', ref, re.I):
            continue
        freq[ref] += 1

    # Sort by descending frequency
    sorted_refs = sorted(freq.items(), key=lambda x: -x[1])

    # Load existing references.csv if present
    existing = {}
    if os.path.exists(REFS_CSV):
        with open(REFS_CSV, newline='', encoding='utf-8') as f:
            for r in csv.DictReader(f):
                existing[r['citation']] = r

    # Load cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    # Build reference rows
    ref_rows = []
    for i, (citation, count) in enumerate(sorted_refs, 1):
        key = f'c{i:03d}'
        ctype = classify(citation)

        # Determine DOI
        doi = ''
        if ctype == 'doi_inline':
            doi = extract_inline_doi(citation) or ''
            ctype = 'paper'  # treat as paper once DOI is known
        elif ctype == 'paper' and existing.get(citation, {}).get('doi', '').strip():
            doi = existing[citation]['doi']  # keep existing
        elif ctype == 'paper':
            print(f'  Querying Crossref for: {citation[:80]}')
            doi = crossref_by_title(citation, cache) or ''
            if doi:
                print(f'    -> {doi}')
            else:
                print(f'    -> not found')
            time.sleep(0.15)

        # Note for non-paper types
        note = ''
        if ctype == 'database':
            note = f'owner: database source ({citation}); drop unless a citable paper DOI is confirmed'
        elif ctype == 'website':
            note = f'owner: website/URL source; drop unless DOI confirmed'
        elif ctype == 'self':
            note = 'owner: allometry-derived (estimated from body length in Cai_etal_2025); cite as self'
        elif ctype == 'grey':
            note = 'owner: grey literature; nodoi or drop'

        ref_rows.append({
            'key': key, 'citation': citation, 'doi': doi,
            'type': ctype, 'note': note, 'n_records': count,
        })

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write references.csv
    fieldnames = ['key', 'citation', 'doi', 'type', 'note', 'n_records']
    with open(REFS_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(ref_rows)

    n_paper = sum(1 for r in ref_rows if r['type'] == 'paper')
    n_doi   = sum(1 for r in ref_rows if r['doi'])
    n_db    = sum(1 for r in ref_rows if r['type'] == 'database')
    n_web   = sum(1 for r in ref_rows if r['type'] == 'website')
    print(f'\nDone: {len(ref_rows)} references ({n_paper} papers, {n_doi} with DOI, '
          f'{n_db} databases, {n_web} websites)')

if __name__ == '__main__':
    main()
