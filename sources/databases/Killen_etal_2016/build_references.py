"""
build_references.py - Build references.csv and key_map.csv for Killen_etal_2016.

MMRref column contains full APA citations; this script:
  1. Parses each unique citation to generate an abbreviated key (Author et al. YEAR).
  2. Searches Crossref for DOIs.
  3. Writes references.csv (key, citation, doi).
  4. Writes key_map.csv (citation_text, key) for use by the R script.

Run from the DB root:
  python3 sources/databases/Killen_etal_2016/build_references.py
"""

import csv, json, os, re, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_CSV   = os.path.join(SCRIPT_DIR, 'TableS1.csv')
REFS_OUT   = os.path.join(SCRIPT_DIR, 'references.csv')
KEY_MAP    = os.path.join(SCRIPT_DIR, 'key_map.csv')
CACHE_FILE = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

REF_COL = 'MMRref'

# Hard-coded key overrides for entries that parse_ref cannot handle
KEY_OVERRIDES = {
    'Killen_et_al._unpublished': 'Killen et al. unpublished',
    'Killen_unpublished': 'Killen unpublished',
}
# Any citation_text that starts with this prefix gets this key
KEY_PREFIX_OVERRIDES = [
    ('Killen_et_al_unpublished', 'Killen et al. unpublished (2011 fish)'),
]


def normalize(s):
    _TRANSLIT = {'ø': 'o', 'Ø': 'O', 'æ': 'ae', 'Æ': 'AE', 'ß': 'ss'}
    for c, r in _TRANSLIT.items():
        s = s.replace(c, r)
    s = s.replace("'", '').replace('’', '')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9 ]', ' ', s.lower())
    return re.sub(r'\s+', ' ', s).strip()


def parse_ref(text):
    """
    Return (abbreviated_key, year, first_surname, title_frag) from an APA citation.

    Formats handled:
      Author, I. I., & Author, I. I. (YEAR). Title. Journal...
      Author, I. I. YEAR. Title. Journal... (no parentheses)
    Key rules: 1 author -> "Surname YEAR"; 2 authors -> "S1 and S2 YEAR";
               3+ authors -> "S1 et al. YEAR".
    """
    text = re.sub(r'[\r\n]+', ' ', text).strip()

    # Extract year: try parenthetical first, then "year." format
    m_paren = re.search(r'\((\d{4}[a-z]?)\)', text)
    m_dot   = re.search(r'\b(\d{4}[a-z]?)\.\s', text)
    if m_paren:
        year_str = m_paren.group(1)
        year = year_str[:4]
        author_part = text[:m_paren.start()].rstrip('. ')
    elif m_dot:
        year_str = m_dot.group(1)
        year = year_str[:4]
        author_part = text[:m_dot.start()].rstrip('. ')
    else:
        return '', '', '', text[:100]

    # First author surname (first token before first comma)
    first_surname = author_part.split(',')[0].strip()
    first_surname = first_surname.replace('-', ' ')

    # Determine author count from commas before '&' (or 'and ')
    m_amp = re.search(r'[&]|(?<!\w)and(?!\w)', author_part)
    if not m_amp:
        # Single author
        key_authors = first_surname
    else:
        before_amp = author_part[:m_amp.start()]
        n_commas = before_amp.count(',')
        if n_commas <= 2:
            # 2 authors total
            after_amp = author_part[m_amp.end():]
            m2 = re.match(r'\s*([A-Z][a-zA-Z\-]+)', after_amp)
            second_surname = m2.group(1).replace('-', ' ') if m2 else ''
            if second_surname:
                key_authors = first_surname + ' and ' + second_surname
            else:
                key_authors = first_surname + ' et al.'
        else:
            key_authors = first_surname + ' et al.'

    key = key_authors + ' ' + year

    # Title fragment: text after the year for Crossref search
    if m_paren:
        after_year = text[m_paren.end():].strip().lstrip('.')
    else:
        after_year = text[m_dot.end():].strip()
    title_frag = after_year[:120]

    return key, year, first_surname, title_frag


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


def main():
    with open(DATA_CSV, newline='', encoding='latin1') as f:
        data_rows = list(csv.DictReader(f))

    # Collect unique citation texts
    unique_cits = {}  # citation_text -> (key, year, surname, title_frag)
    for r in data_rows:
        v = r.get(REF_COL, '').strip()
        if not v or v == 'NA':
            continue
        if v not in unique_cits:
            # Check hard-coded overrides first
            override_key = KEY_OVERRIDES.get(v)
            if not override_key:
                for prefix, ok in KEY_PREFIX_OVERRIDES:
                    if v.startswith(prefix):
                        override_key = ok
                        break
            if override_key:
                unique_cits[v] = (override_key, '', '', v[:80])
            else:
                key, year, surname, title_frag = parse_ref(v)
                unique_cits[v] = (key, year, surname, title_frag)

    print(f'Unique citations: {len(unique_cits)}')

    # Detect key collisions and make unique
    key_counts = {}
    for k, (key, *_) in unique_cits.items():
        key_counts[key] = key_counts.get(key, 0) + 1
    collisions = {k for k, n in key_counts.items() if n > 1}
    if collisions:
        print(f'Key collisions: {collisions}')
        # Append 'a', 'b', ... suffix to disambiguate
        collision_counters = {k: 0 for k in collisions}
        unique_cits_new = {}
        for cit, (key, year, surname, title_frag) in unique_cits.items():
            if key in collisions:
                suffix = chr(ord('a') + collision_counters[key])
                collision_counters[key] += 1
                key = key + suffix
            unique_cits_new[cit] = (key, year, surname, title_frag)
        unique_cits = unique_cits_new

    # Load Crossref cache
    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    # Build output
    output = []   # references.csv rows
    key_map = []  # key_map.csv rows: citation_text, key

    for cit_text, (key, year, surname, title_frag) in sorted(unique_cits.items()):
        is_grey = bool(re.search(
            r'\b(thesis|Thesis|Unpubl|unpubl|Ph\.D|M\.S\.|M\.Sc|book|Book|'
            r'Press|press|chapter|Chapter|In |In:|ed\.|ed\s|editor)\b',
            cit_text))
        if is_grey or not year:
            doi = ''
            note = 'book' if is_grey else ''
        else:
            doi = find_doi(title_frag, surname, year, cache)
            note = ''
            time.sleep(0.2)

        print(f'[{key}] doi={doi[:40] if doi else ""}')
        output.append({'key': key, 'citation': cit_text, 'doi': doi, 'note': note})
        key_map.append({'citation_text': cit_text, 'key': key})

    # Save cache
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note'])
        w.writeheader()
        w.writerows(output)

    with open(KEY_MAP, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['citation_text', 'key'])
        w.writeheader()
        w.writerows(key_map)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI')
    print(f'Wrote {KEY_MAP}')


if __name__ == '__main__':
    main()
