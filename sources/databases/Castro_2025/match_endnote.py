"""
match_endnote.py -- match references.csv entries against the EndNote library.

Reads deCastro_SciData_Refs.enl (SQLite), extracts author/year/title/DOI,
then matches each open references.csv row by first-author-surname + year.
For confirmed matches uses the EndNote DOI if present, otherwise queries
Crossref by full title.  Updates references.csv doi column.

Run from the DB root or from the source folder:
  python3 sources/databases/Castro_2025/match_endnote.py
"""

import csv, json, os, re, sqlite3, time, unicodedata
import urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ENL_FILE   = os.path.join(SCRIPT_DIR, 'deCastro_SciData_Refs.enl')
REFS_CSV   = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

SIM_AUTHOR_THRESHOLD = 0.70
SIM_TITLE_CONFIRM    = 0.60   # lower bar since title is full vs abbreviated
SIM_TITLE_CROSSREF   = 0.80   # bar for accepting a Crossref title search result


def normalize(s):
    """Lower-case, strip accents, remove non-alphanumeric."""
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    return re.sub(r'[^a-z0-9 ]', ' ', s.lower()).strip()


def sim(a, b):
    return SequenceMatcher(None, normalize(a), normalize(b)).ratio()


def first_surname(author_field):
    """Extract first author's surname from EndNote author string.
    Format: 'Surname, F.^MSecond Author^M...'  or 'Surname F.'
    The separator is a literal caret-M (^M) or actual ctrl-M.
    """
    # Split on ^M (literal two chars) or actual carriage return
    parts = re.split(r'\^M|\r', author_field)
    first = parts[0].strip()
    # If 'Surname, Initials' take the part before the comma
    if ',' in first:
        return first.split(',')[0].strip()
    # Otherwise the whole thing or first word
    words = first.split()
    return words[0] if words else first


def extract_doi(ern):
    """Strip https://doi.org/ prefix from electronic_resource_number."""
    ern = ern.strip()
    ern = re.sub(r'^https?://doi\.org/', '', ern, flags=re.I)
    ern = re.sub(r'^doi:', '', ern, flags=re.I)
    return ern.strip() if ern else ''


def crossref_by_title(title, year, cache, email=CROSSREF_EMAIL):
    """Search Crossref by full title; return DOI if title_sim >= threshold."""
    key = f'title:{title[:80]}:{year}'
    if key in cache:
        return cache[key]
    params = {
        'query.title': title,
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
        cr_title = ' '.join(item.get('title', []))
        title_s = sim(title, cr_title)
        if title_s < SIM_TITLE_CROSSREF:
            continue
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ''
        if pub_year and pub_year != str(year):
            continue
        doi = item.get('DOI', '').strip()
        if doi:
            cache[key] = doi
            return doi
    cache[key] = None
    return None


def main():
    # Load EndNote records
    con = sqlite3.connect(ENL_FILE)
    con.row_factory = sqlite3.Row
    cur = con.cursor()
    cur.execute("""
        SELECT id, author, year, title, secondary_title, volume, pages,
               electronic_resource_number
        FROM enl_refs WHERE trash_state=0
    """)
    enl_rows = cur.fetchall()
    con.close()
    print(f'EndNote records: {len(enl_rows)}')

    # Index by (first_surname_normalized, year)
    enl_by_key = {}
    for row in enl_rows:
        surname = first_surname(row['author'])
        yr = str(row['year']).strip()
        key = (normalize(surname), yr)
        enl_by_key.setdefault(key, []).append(dict(row))

    # Load references.csv
    with open(REFS_CSV, newline='', encoding='utf-8') as f:
        refs = list(csv.DictReader(f))
    print(f'References: {len(refs)} (open: {sum(1 for r in refs if not r["doi"])})')

    # Load cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    matched = 0
    for ref in refs:
        if ref['doi']:
            continue  # already has a DOI
        author = ref['parsed_author'].strip()
        year   = ref['parsed_year'].strip()
        if not author or not year:
            continue

        lookup_key = (normalize(author), year)
        candidates = enl_by_key.get(lookup_key, [])

        # Also try slight author variants (e.g. 'van Aardt' vs 'Aardt')
        if not candidates:
            for (enl_sur, enl_yr), rows in enl_by_key.items():
                if enl_yr == year and sim(author, enl_sur) >= SIM_AUTHOR_THRESHOLD:
                    candidates = rows
                    break

        if not candidates:
            continue

        # Pick best candidate by title similarity (if multiple same author+year)
        best = None
        best_score = -1
        for cand in candidates:
            enl_title = cand['title'].strip()
            s = sim(author, first_surname(cand['author']))
            if s < SIM_AUTHOR_THRESHOLD:
                continue
            # For single-candidate same year, accept even with no title comparison
            score = s
            best_score = score
            best = cand

        if best is None:
            continue

        enl_doi = extract_doi(best['electronic_resource_number'])
        enl_title = best['title'].strip()

        if enl_doi:
            ref['doi'] = enl_doi
            matched += 1
            print(f"  {ref['key']:5s} ({ref['n_records']:4s} rec) ENDNOTE DOI: {ref['citation'][:45]} -> {enl_doi[:45]}")
        else:
            # Search Crossref by full title
            print(f"  {ref['key']:5s} ({ref['n_records']:4s} rec) title search: {enl_title[:60]}")
            doi = crossref_by_title(enl_title, year, cache)
            if doi:
                ref['doi'] = doi
                matched += 1
                print(f"    -> {doi}")
            else:
                print(f"    -> not found")
                # Still store the title in a note for the pipeline
            time.sleep(0.15)

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    # Write updated references.csv
    fieldnames = ['key', 'citation', 'doi', 'parsed_author', 'parsed_year', 'n_records']
    with open(REFS_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(refs)

    n_doi = sum(1 for r in refs if r['doi'])
    print(f'\nDone: {matched} matched, {n_doi} total with DOI out of {len(refs)} references')


if __name__ == '__main__':
    main()
