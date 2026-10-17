"""
build_references.py -- Castro_2025 citation DOI lookup

Reads the unique Reference values from FieldMR_SciDataPub.csv, parses each
into (first_author, year), queries Crossref by bibliographic search, and
writes references.csv with keys r001-rNNN (sorted by descending frequency).

Reference format examples:
  "LopezUrrutia 2006"
  "Anderson 2005"
  "Evans, Purdie, Hickmann 1962"
  "Nagy 1987"

Run from the DB root or from the source folder:
  python3 sources/databases/Castro_2025/build_references.py

Requires: requests (pip install requests).
Cache: crossref_cache.json beside this script.

NOTE (2026-10-17): DOIs found by this script via author+year matching have a
very high false-positive rate.  After checking all 16 DOIs that passed verify,
all but r001 (LopezUrrutia 2006) and r005 (Caulton 1978) pointed to unrelated
papers (wrong discipline, wrong journal).  The doi column in the output
references.csv has been reset to empty for all false-positive entries; only
manually confirmed DOIs should be kept.
"""

import csv, json, os, re, time
import urllib.request, urllib.parse
from collections import Counter
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_CSV  = os.path.join(SCRIPT_DIR, 'FieldMR_SciDataPub.csv')
REFS_CSV    = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE  = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

# ---------------------------------------------------------------------------
# Parse author-year reference strings
# ---------------------------------------------------------------------------

def parse_author_year(raw):
    """Return (first_author_surname, year) from 'Surname Year' or 'S1, S2, S3 Year'."""
    raw = raw.strip()
    # Year is the last 4-digit token
    m = re.search(r'\b(1[89]\d\d|20\d\d)\b', raw)
    if not m:
        return None, None
    year = m.group(1)
    # Everything before the year
    before = raw[:m.start()].strip().rstrip(',').strip()
    # First author is first comma-separated token, or the whole thing
    parts = [p.strip() for p in before.split(',')]
    first = parts[0] if parts else before
    # Remove parenthetical suffixes
    first = re.sub(r'\s+et\s+al\.?$', '', first, flags=re.I).strip()
    return first, year

# ---------------------------------------------------------------------------
# Crossref bibliographic search
# ---------------------------------------------------------------------------

def name_sim(a, b):
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()

def crossref_by_biblio(author, year, cache, email=CROSSREF_EMAIL):
    """Query Crossref with author + year; return best DOI with reasonable match, or None."""
    key = f'biblio:{author}:{year}'
    if key in cache:
        return cache[key]
    query = f'{author} {year}'
    params = {
        'query.bibliographic': query,
        'rows': '5',
        'mailto': email,
        'select': 'DOI,title,author,published',
    }
    url = 'https://api.crossref.org/works?' + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={'User-Agent': f'TaxonBodyMass/1.0 (mailto:{email})'})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception as e:
        print(f'  ERROR: {e}')
        cache[key] = None
        return None

    items = data.get('message', {}).get('items', [])
    for item in items:
        pub_year = None
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        if parts and parts[0]:
            pub_year = str(parts[0][0])
        if pub_year != year:
            continue
        # Check first author surname similarity
        authors = item.get('author', [])
        if authors:
            cr_surname = authors[0].get('family', '')
            sim = name_sim(author, cr_surname)
            if sim >= 0.70:
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
    # Load source data frequencies
    with open(SOURCE_CSV, newline='', encoding='latin-1') as f:
        rows = list(csv.DictReader(f))

    freq = Counter()
    for row in rows:
        ref = (row.get('Reference') or '').strip()
        if ref:
            freq[ref] += 1

    sorted_refs = sorted(freq.items(), key=lambda x: -x[1])
    print(f'Unique references: {len(sorted_refs)}')

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

    ref_rows = []
    for i, (citation, count) in enumerate(sorted_refs, 1):
        key = f'r{i:03d}'
        author, year = parse_author_year(citation)

        # Keep existing DOI if already found
        doi = existing.get(citation, {}).get('doi', '').strip()

        if not doi and author and year:
            print(f'  Querying: {citation[:60]}')
            doi = crossref_by_biblio(author, year, cache) or ''
            if doi:
                print(f'    -> {doi}')
            else:
                print(f'    -> not found')
            time.sleep(0.15)

        ref_rows.append({
            'key': key,
            'citation': citation,
            'doi': doi,
            'parsed_author': author or '',
            'parsed_year': year or '',
            'n_records': count,
        })

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write references.csv
    fieldnames = ['key', 'citation', 'doi', 'parsed_author', 'parsed_year', 'n_records']
    with open(REFS_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(ref_rows)

    n_doi = sum(1 for r in ref_rows if r['doi'])
    print(f'\nDone: {len(ref_rows)} references, {n_doi} with DOI')

if __name__ == '__main__':
    main()
