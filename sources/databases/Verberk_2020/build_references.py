"""
build_references.py - Build references.csv and key_map.csv for Verberk_2020.

Diving_dataset.csv (latin1) has a 'Literature.source' column with full APA
citations like "Adams N.J. & Walter C.B. (1993) Maximum diving depths of Cape
gannets. Condor 95: 734-736." The script:
  1. Extracts unique Literature.source values.
  2. Parses each to an abbreviated key (Surname_etal_YEAR or Surname_Surname_YEAR).
  3. Searches Crossref for DOIs using title fragment.
  4. Writes references.csv (key, citation, doi, note) and
     key_map.csv (citation_text -> key).

Run from DB root:
  python3 sources/databases/Verberk_2020/build_references.py
"""

import csv, json, os, re, time, unicodedata, urllib.request, urllib.parse
from difflib import SequenceMatcher

CROSSREF_EMAIL = "mnovak.m@gmail.com"
SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
DATA_CSV    = os.path.join(SCRIPT_DIR, "Diving_dataset.csv")
REFS_OUT    = os.path.join(SCRIPT_DIR, "references.csv")
KEYMAP_OUT  = os.path.join(SCRIPT_DIR, "key_map.csv")
CACHE_FILE  = os.path.join(SCRIPT_DIR, "crossref_cache.json")


def normalize(s):
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = re.sub("[^a-z0-9 ]", " ", s.lower())
    return re.sub(r"\s+", " ", s).strip()


def clean_citation(text):
    """Best-effort cleanup of latin1-decoded citation text."""
    # Replace common latin1 corruption patterns with ASCII equivalents
    text = text.replace("\x82", ",").replace("\x91", "'").replace("\x92", "'")
    text = text.replace("\x93", '"').replace("\x94", '"').replace("\x96", "-")
    text = text.replace("\x97", "-").replace("\xa0", " ").replace("\xad", "-")
    # Replace garbled question marks (encoding artifacts) with space for parsing
    return text.strip()


def parse_citation(text):
    """
    Parse a full-text citation into (first_surname, year, second_surname, title_frag, is_grey).
    Handles formats:
      "Smith J.K. & Jones A.B. (2003) Title..."
      "Smith, J.K., Jones, A.B., Brown, C. (2003) Title..."
      "Smith J.K. (2003) Title..."
    """
    text = clean_citation(text)

    # Year: look for (YEAR) first, then bare YEAR
    m_year = re.search(r"\((\d{4})\)", text)
    if not m_year:
        m_year = re.search(r"\b((?:19|20)\d{2})\b", text[:80])
    if not m_year:
        return "", "", "", text[:60], False
    year = m_year.group(1)

    author_part = text[:m_year.start()].strip().rstrip(",. ")
    after_year  = text[m_year.end():].strip().lstrip(". ")

    # Title fragment: text up to first period followed by capital or digits
    m_end = re.search(r"\.\s+[A-Z0-9]", after_year)
    title_frag = after_year[:m_end.start()] if m_end else after_year[:80]
    title_frag = title_frag.strip().rstrip(".")

    # Grey literature
    is_grey = bool(re.search(
        r"\bPhD\b|\bthesis\b|\bThesis\b|\bIn:\b|\bPress\b|\bUniversity\b|"
        r"\bReport\b|\bchapter\b|\bmanuscript\b",
        text, re.IGNORECASE))

    # Extract first and second surnames
    first_surname = ""
    second_surname = ""

    # Pattern: "Surname, I." comma-separated authors
    m_comma = re.match(r"^([A-Za-z][A-Za-z\-']+),", author_part)
    # Pattern: "Surname I.J. & Surname2 ..."
    m_plain = re.match(r"^([A-Za-z][A-Za-z\-']+)\s+[A-Z]", author_part)

    if m_comma:
        first_surname = m_comma.group(1)
        # Second author: after "& Surname" or second comma block
        m_sec = re.search(r"&\s+([A-Za-z][A-Za-z\-']+)", author_part)
        if m_sec:
            second_surname = m_sec.group(1)
    elif m_plain:
        first_surname = m_plain.group(1)
        m_sec = re.search(r"&\s+([A-Za-z][A-Za-z\-']+)", author_part)
        if m_sec:
            second_surname = m_sec.group(1)
    else:
        # Fallback: first word
        words = author_part.split()
        first_surname = words[0] if words else ""

    return first_surname, year, second_surname, title_frag, is_grey


def make_key(first_surname, year, second_surname, author_part):
    """Build abbreviated key: Surname_Surname_YEAR or Surname_etal_YEAR."""
    fs = re.sub(r"[^A-Za-z]", "", first_surname)
    if not fs:
        return f"Unknown_{year}"
    # Count authors: if more than 2, use et al.
    has_et_al = bool(re.search(r"\bet\s*al\.?", author_part, re.IGNORECASE))
    n_authors = len(re.findall(r"[A-Z]\.", author_part)) or \
                len(re.findall(r",&", author_part)) + 1
    if has_et_al or n_authors > 2:
        return f"{fs}_etal_{year}"
    if second_surname:
        ss = re.sub(r"[^A-Za-z]", "", second_surname)
        return f"{fs}_{ss}_{year}" if ss else f"{fs}_{year}"
    return f"{fs}_{year}"


def disambiguate(key, used_keys):
    """Append a, b, c ... if key already used."""
    if key not in used_keys:
        return key
    for ch in "abcdefghijklmnopqrstuvwxyz":
        candidate = f"{key}{ch}"
        if candidate not in used_keys:
            return candidate
    return key + "_dup"


def crossref_search(title_frag, author, year, cache):
    query = f"{author} {year} {title_frag[:60]}"
    if query in cache:
        return cache[query]
    params = {
        "query": query, "rows": "5", "mailto": CROSSREF_EMAIL,
        "select": "DOI,title,published",
    }
    url = "https://api.crossref.org/works?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url,
              headers={"User-Agent": f"TaxonBodyMass/1.0 (mailto:{CROSSREF_EMAIL})"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read())
    except Exception:
        cache[query] = None
        return None
    items = data.get("message", {}).get("items", [])
    cache[query] = items if items else None
    return cache[query]


def find_doi(title_frag, author, year, cache):
    if not title_frag or len(normalize(title_frag)) < 10:
        return ""
    items = crossref_search(title_frag, author, year, cache)
    if not items:
        return ""
    for item in items:
        cr_title = " ".join(item.get("title", []))
        s = SequenceMatcher(None, normalize(title_frag[:80]), normalize(cr_title)).ratio()
        if s < 0.75:
            continue
        pub = item.get("published", {})
        parts = pub.get("date-parts", [[]])
        pub_year = str(parts[0][0]) if parts and parts[0] else ""
        if year and pub_year and abs(int(pub_year) - int(year)) > 1:
            continue
        doi = item.get("DOI", "").strip()
        if doi:
            return doi
    return ""


def load_unique_sources():
    with open(DATA_CSV, newline="", encoding="latin1", errors="replace") as f:
        rows = list(csv.DictReader(f))
    src_set = set()
    for r in rows:
        mass = r.get("Mass..kg.", "").strip()
        if not mass or mass in ("NA", ""):
            continue
        src = r.get("Literature.source", "").strip()
        if src:
            src_set.add(src)
    return src_set


def main():
    raw_sources = load_unique_sources()
    print(f"Unique Literature.source values: {len(raw_sources)}")

    cache = {}
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            cache = json.load(f)

    used_keys = set()
    refs = []
    keymap = []

    for citation_text in sorted(raw_sources):
        first_surname, year, second_surname, title_frag, is_grey = parse_citation(citation_text)
        raw_key = make_key(first_surname, year, second_surname, citation_text)
        key = disambiguate(raw_key, used_keys)
        used_keys.add(key)

        if is_grey or not year or not first_surname:
            doi = ""
            note = "book" if is_grey else "not_parsed"
        else:
            doi = find_doi(title_frag, first_surname, year, cache)
            note = ""
            time.sleep(0.15)

        print(f"[{key[:40]}]  doi={doi[:35] if doi else ''}")
        refs.append({"key": key, "citation": citation_text, "doi": doi, "note": note})
        keymap.append({"citation_text": citation_text, "key": key})

    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

    with open(REFS_OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["key", "citation", "doi", "note"])
        w.writeheader()
        w.writerows(refs)

    with open(KEYMAP_OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["citation_text", "key"])
        w.writeheader()
        w.writerows(keymap)

    n_doi = sum(1 for r in refs if r["doi"])
    print(f"\nDone: {len(refs)} entries, {n_doi} with DOI")


if __name__ == "__main__":
    main()
