"""
build_references.py - Build references.csv for Gillooly_etal_2016.

The data CSV has integer-indexed mass references (negative: -1 means reference 1).
The bibliography is the numbered reference list in Appendix 1 of Gillooly_etal_2016.pdf,
formatted in PNAS style: "N. I. Surname, ... Title. Journal vol, pp (year)."

Native keys in references.csv are the string integers "1", "2", ..., "N";
the R script converts abs(M.1) to character for lookup.

Run from the DB root:
  python3 sources/databases/Gillooly_etal_2016/build_references.py
"""

import csv, json, os, re, subprocess, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = 'mnovak.m@gmail.com'
SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
PDF_FILE    = os.path.join(SCRIPT_DIR, 'Gillooly_etal_2016.pdf')
REFS_OUT    = os.path.join(SCRIPT_DIR, 'references.csv')
CACHE_FILE  = os.path.join(SCRIPT_DIR, 'crossref_cache.json')

BIB_START = 'References, Appendix 1:'
BIB_END   = 'References, Appendix 2:'

# Hard-coded overrides for refs whose text appears in the wrong PDF block
MANUAL_REFS = {
    29: ('S. F. Perry, Gas exchange strategy in the Nile crocodile: a morphometric study. '
         'Journal of Comparative Physiology B 159, 761-769 (1990).'),
}


def normalize(s):
    _TRANSLIT = {'ø': 'o', 'Ø': 'O', 'æ': 'ae', 'Æ': 'AE', 'ß': 'ss',
                 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ó': 'o',
                 'í': 'i', 'ú': 'u', 'ñ': 'n', 'ç': 'c'}
    for c, r in _TRANSLIT.items():
        s = s.replace(c, r)
    s = s.replace("'", '')
    s = unicodedata.normalize('NFD', s)
    s = ''.join(c for c in s if unicodedata.category(c) != 'Mn')
    s = re.sub(r'[^a-z0-9 ]', ' ', s.lower())
    return re.sub(r'\s+', ' ', s).strip()


def extract_pdf_text():
    result = subprocess.run(
        ['pdftotext', '-enc', 'UTF-8', PDF_FILE, '-'],
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    return result.stdout


def get_bibliography(text):
    """Extract the Appendix 1 reference lines."""
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines) if BIB_START in l), None)
    end   = next((i for i, l in enumerate(lines) if BIB_END in l and i > start), None)
    if start is None or end is None:
        raise ValueError('Could not find Appendix 1 reference section')
    return lines[start+1:end]


def join_numbered_refs(lines):
    """
    Join multi-line references into single strings. Each entry starts with
    a line containing only a number or "N.\n" with the text on the next line.
    Returns dict {number: full_text}.
    """
    refs = {}
    current_num = None
    current_text = []
    for line in lines:
        line_s = line.strip()
        if not line_s:
            continue
        # Check if this line is a standalone reference number
        m_num = re.match(r'^(\d+)\.$', line_s)
        if m_num:
            if current_num is not None:
                refs[current_num] = ' '.join(current_text).strip()
            current_num = int(m_num.group(1))
            current_text = []
        else:
            if current_num is not None:
                current_text.append(line_s)
    if current_num is not None and current_text:
        refs[current_num] = ' '.join(current_text).strip()
    return refs


def parse_pnas_ref(text):
    """
    Parse a PNAS-format reference: "I. Surname, I. Surname, Title. Journal vol, pp (year)."
    Returns (abbreviated_key, year, first_surname, title_frag).
    """
    text = re.sub(r'[\r\n]+', ' ', text).strip()

    # Year: (YYYY)
    m_year = re.search(r'\((\d{4})\)', text)
    year = m_year.group(1) if m_year else ''

    # First author surname: first multi-char word after initial(s) "I. " pattern
    m_first = re.match(r'(?:[A-Z]\.\s+){1,4}(?:[a-z]{1,4}\s+)?([A-Z][a-zA-ZöäüÖÄÜøæéèàñç\-]+)',
                       text)
    first_surname = m_first.group(1) if m_first else ''

    # Detect et al.
    has_etal = bool(re.search(r'\bet al\b', text[:200]))

    # Count author patterns before year (each author: "I. Surname,")
    before_year = text[:m_year.start()] if m_year else text[:250]
    author_segments = re.findall(r'[A-Z]\.\s+[A-Z][a-zA-Z\-éèàü]{2,}', before_year)
    n_authors = len(author_segments)

    if has_etal or n_authors >= 3:
        key_authors = first_surname + ' et al.'
    elif n_authors == 2:
        # Extract second author surname
        # After the first "I. Surname, " find the next "I. Surname"
        m_second = re.search(
            r'[A-Z]\.\s+[A-Z][a-zA-Z\-éèàü]+,\s+(?:[A-Z]\.\s+){1,3}([A-Z][a-zA-Z\-éèàü]+)',
            before_year)
        second = m_second.group(1) if m_second else ''
        key_authors = (first_surname + ' and ' + second) if second else first_surname + ' et al.'
    else:
        key_authors = first_surname

    # Title fragment: text after the last author / et al., before the journal (first ". ")
    # Roughly: strip the leading author portion
    if has_etal:
        after_etal = re.sub(r'^.*?\bet al\b[.,]\s*', '', text, flags=re.DOTALL)
        title_frag = after_etal[:100]
    elif n_authors >= 2 and m_year:
        # Find title start: after the last comma-initial pattern in the author block
        # Approximate: split at the last "Surname, " followed by capitalized title word
        # Use: text after all author segments
        author_end = 0
        for m in re.finditer(r'[A-Z]\.\s+[A-Z][a-zA-Z\-éèàü]+[,.]', before_year):
            author_end = m.end()
        title_frag = text[author_end:].lstrip(', ').strip()[:100]
    else:
        title_frag = text[:100]

    key = (key_authors + ' ' + year).strip() if year else key_authors

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
    print('Extracting PDF text...')
    pdf_text = extract_pdf_text()
    bib_lines = get_bibliography(pdf_text)
    refs = join_numbered_refs(bib_lines)
    print(f'Parsed {len(refs)} references (nums: {sorted(refs)[:5]}...)')

    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    refs.update(MANUAL_REFS)
    output = []
    for num in sorted(refs):
        text = refs[num]
        key, year, surname, title_frag = parse_pnas_ref(text)
        # Key is the string integer for lookup; abbreviated key goes in citation
        native_key = str(num)
        is_grey = bool(re.search(
            r'\b(in |In |Ed\.|ed\.|editor|press|Press|book|Book|chapter|Chapter|'
            r'thesis|Thesis|unpubl|Unpubl|[Pp]roc\.|Rep\.\s|Tech\.)\b',
            text))
        if is_grey or not year:
            doi = ''
            note = 'book' if is_grey else ''
        else:
            doi = find_doi(title_frag, surname, year, cache)
            note = ''
            time.sleep(0.2)
        print(f'[{native_key}] {key or "?"}  doi={doi[:35] if doi else ""}')
        output.append({'key': native_key, 'citation': text, 'doi': doi, 'note': note,
                       'abbrev_key': key})

    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)

    with open(REFS_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['key', 'citation', 'doi', 'note', 'abbrev_key'])
        w.writeheader()
        w.writerows(output)

    n_doi = sum(1 for r in output if r['doi'])
    print(f'\nDone: {len(output)} entries, {n_doi} with DOI')


if __name__ == '__main__':
    main()
