"""
build_references.py - Build references.csv for DeLong_etal_2018 (FoRAGE database).

The 'Source' column in the CSV contains abbreviated references of the form
"Lastname YEAR JOURNAL_ABBREV" or "Lastname et al YEAR JOURNAL_ABBREV" or
"Lastname and Lastname2 YEAR JOURNAL_ABBREV".

Only Sources that survive the mass-source-code filter are needed
(original/species-average mass codes kept; alternate-taxon/order-average dropped).

Run from the DB root:
  python3 sources/databases/DeLong_etal_2018/build_references.py
"""

import csv, json, os, re, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_CSV   = os.path.join(SCRIPT_DIR, 'FoRAGE_db_12_19_18_data_set.csv')
REFS_OUT   = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

MASS_CODE_DROP = re.compile(
    r'^alternat|^%|pred mass|^average (genus|order)', re.IGNORECASE)
ADULT_TYPE = re.compile(r'^adult|female|male', re.IGNORECASE)


def normalize(s):
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9 ]', ' ', s.lower())
    return re.sub(r'\s+', ' ', s).strip()


def parse_source(src):
    """
    Parse abbreviated Source string: "Lastname et al YEAR JOURNAL" or
    "Lastname and Lastname2 YEAR JOURNAL" or "Lastname YEAR JOURNAL".
    Returns (first_surname, year, journal_fragment).
    """
    src = src.strip()
    m_year = re.search(r'\b(\d{4})\b', src)
    if not m_year:
        return '', '', src
    year = m_year.group(1)
    author_part = src[:m_year.start()].strip()
    journal_part = src[m_year.end():].strip()
    first_surname = author_part.split()[0] if author_part else ''
    return first_surname, year, journal_part


def crossref_search(author, year, journal_frag, cache):
    query = f'{author} {year} {journal_frag[:40]}'
    if query in cache:
        return cache[query]
    params = {
        'query': query, 'rows': '5', 'mailto': CROSSREF_EMAIL,
        'select': 'DOI,title,author,published,container-title',
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


def find_doi_and_citation(src, cache):
    """
    Search Crossref for the Source string. Match on first author surname + year.
    Returns (doi, full_citation_text).
    """
    author, year, journal_frag = parse_source(src)
    if not year:
        return '', src

    items = crossref_search(author, year, journal_frag, cache)
    if not items:
        return '', src

    norm_author = normalize(author)
    for item in items:
        # Year check
        pub = item.get('published', {})
        parts = pub.get('date-parts', [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ''
        if pub_year and abs(int(pub_year) - int(year)) > 1:
            continue
        # Author check: first author surname must match
        cr_authors = item.get('author', [])
        if cr_authors:
            first_cr = cr_authors[0].get('family', '')
            if normalize(first_cr)[:8] != norm_author[:8]:
                continue
        doi = item.get('DOI', '').strip()
        title = ' '.join(item.get('title', []))
        journal = ', '.join(item.get('container-title', []))
        cr_authors_str = ', '.join(
            f"{a.get('given', '')} {a.get('family', '')}".strip()
            for a in cr_authors[:5])
        if len(cr_authors) > 5:
            cr_authors_str += ' et al.'
        citation = f'{cr_authors_str}. ({year}). {title}. {journal}.' if title else src
        if doi:
            return doi, citation
    return '', src


def load_filtered_sources():
    """Load and filter the FoRAGE CSV; return set of unique Source values."""
    with open(DATA_CSV, newline='', encoding='latin1') as f:
        rows = list(csv.DictReader(f))
    sources = set()
    for r in rows:
        for suffix in ('', '.1'):
            pred_type = r.get('Predator.type', '') or ''
            prey_type  = r.get('Prey.type', '') or ''
            # Predator side
            code = (r.get('Predator.mass.source.code', '') or '').strip()
            if not MASS_CODE_DROP.match(code):
                p_type = pred_type.strip()
                if not p_type or ADULT_TYPE.match(p_type):
                    src = (r.get('Source', '') or '').strip()
                    if src:
                        sources.add(src)
            # Prey side
            code = (r.get('Prey.mass.source.code', '') or '').strip()
            if not MASS_CODE_DROP.match(code):
                p_type = prey_type.strip()
                if not p_type or ADULT_TYPE.match(p_type):
                    src = (r.get('Source', '') or '').strip()
                    if src:
                        sources.add(src)
    return sources


def main():
    sources = load_filtered_sources()
    print(f'Unique Source keys after filter: {len(sources)}')

    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    output = []
    for src in sorted(sources):
        doi, citation = find_doi_and_citation(src, cache)
        note = ''
        print(f'[{src[:50]}]  doi={doi[:30] if doi else ""}')
        output.append({'key': src, 'citation': citation, 'doi': doi, 'note': note})
        time.sleep(0.15)

    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI')


if __name__ == '__main__':
    main()
