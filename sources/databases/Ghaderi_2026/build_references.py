"""
build_references.py — Ghaderi_2026
Resolve the 85 author-year Source keys from Ghaderi_2026_data.csv to full
citations via the Crossref API, then write references.csv for the issue-#1
primary-source attribution pipeline.

Run from the repository root:
    python3 -I sources/databases/Ghaderi_2026/build_references.py

Outputs:
    sources/databases/Ghaderi_2026/references.csv   (key, citation, doi, note)
    sources/databases/Ghaderi_2026/crossref_cache.json

Key format in data:   "Ahmad & Jairajpuri, 1993"
                      "Ahmad et al., 2005"
                      "Ahmad, 1998"
Known typo duplicates in source data (same paper, different spellings):
    "Coetze, 1966"  /  "Coetzee, 1966"
    "Mulvey & Jansen, 1967"  /  "Mulvey & Jensen, 1967"
    "de Braun & Heyns, 1992"  /  "de Bruin & Heyns, 1992"
    "Vinceguerra & Orcelli, 2006"  ->  Vinciguerra & Orselli (probable correct)
    "Orselli & Vincicuerra, 2007"  ->  Orselli & Vinciguerra (probable correct)
These are kept as-is in references.csv (pipeline deduplicates by doi).
"""

import csv
import json
import os
import re
import time
import urllib.parse
import urllib.request

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.join(SRC_DIR, "..", "..", "..")
DATA_FILE = os.path.join(SRC_DIR, "Ghaderi_2026_data.csv")
OUT_CSV = os.path.join(SRC_DIR, "references.csv")
CACHE_FILE = os.path.join(SRC_DIR, "crossref_cache.json")

SELF_KEY = "Ghaderi_etal_2026"
SELF_DOI = "10.1016/j.apsoil.2025.106605"

CROSSREF_UA = "TaxonBodyMass-DB/1.0 (mailto:novakm@oregonstate.edu)"
SIM_ACCEPT = 0.75
RATE_SLEEP = 0.5


def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_cache(cache):
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=2)


def crossref_query(q, year, rows=5):
    params = urllib.parse.urlencode({
        "query": q,
        "filter": f"from-pub-date:{year},until-pub-date:{year}",
        "rows": rows,
        "select": "DOI,title,author,container-title,volume,page,published",
    })
    url = f"https://api.crossref.org/works?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": CROSSREF_UA})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def parse_key(key):
    """Return (author_query, year, et_al, author_list) from a Source key string."""
    key = key.strip()
    m = re.match(r"^(.+?),\s*(1[89]\d{2}|20\d{2})([ab]?)$", key)
    if not m:
        return None, None, False, []
    authors_raw = m.group(1).strip()
    year = int(m.group(2))
    if "et al" in authors_raw:
        first = re.split(r"\s+et\s+al", authors_raw)[0].strip()
        return first, year, True, [first]
    parts = re.split(r"\s*[&]\s*|\s+and\s+", authors_raw)
    parts = [p.strip() for p in parts if p.strip()]
    query = " ".join(parts[:2])
    return query, year, False, parts


def title_sim(t1, t2):
    """Simple bigram-based string similarity."""
    def bigrams(s):
        s = re.sub(r"[^a-z0-9 ]", "", s.lower())
        words = s.split()
        return set(zip(words, words[1:])) if len(words) >= 2 else set(words)
    a, b = bigrams(t1), bigrams(t2)
    if not a or not b:
        return 0.0
    return 2 * len(a & b) / (len(a) + len(b))


NEMATODE_TERMS = {"nematod", "mononch", "nematol", "dorylai", "tylench",
                  "rhabdit", "cephalo", "monhyst", "enopli", "secernentea",
                  "adenophorea", "predatory", "soil"}


def nematode_relevance(item):
    """+1 if title or journal contains nematology terms."""
    text = " ".join(item.get("title", [])).lower()
    text += " ".join(item.get("container-title", [])).lower()
    return any(t in text for t in NEMATODE_TERMS)


def best_match(items, authors, year):
    """Score each candidate and return the best if it passes SIM_ACCEPT."""
    best = None
    best_score = 0.0
    for item in items:
        # Author match: first author family name
        pub_authors = [a.get("family", "").lower() for a in item.get("author", [])]
        if not pub_authors:
            continue
        first_auth = authors[0].lower() if authors else ""
        name_match = any(
            first_auth in pa or pa in first_auth
            for pa in pub_authors[:2]
        ) if first_auth else False
        if not name_match:
            continue
        pub_year = item.get("published", {}).get("date-parts", [[None]])[0][0]
        if pub_year != year:
            continue
        score = 0.5  # author+year match
        if nematode_relevance(item):
            score += 0.4
        if len(authors) >= 2:
            second = authors[1].lower() if len(authors) > 1 else ""
            if any(second in pa or pa in second for pa in pub_authors[:3]):
                score += 0.2
        if score > best_score:
            best_score = score
            best = item
    return best, best_score


def format_citation(item, key):
    authors = item.get("author", [])
    if len(authors) == 1:
        auth_str = authors[0].get("family", "?")
    elif len(authors) == 2:
        auth_str = f"{authors[0].get('family','?')} & {authors[1].get('family','?')}"
    else:
        auth_str = f"{authors[0].get('family','?')} et al."
    year = item.get("published", {}).get("date-parts", [[None]])[0][0] or "?"
    title = item.get("title", ["?"])[0]
    journal = (item.get("container-title") or [""])[0]
    vol = item.get("volume", "")
    page = item.get("page", "")
    loc = f"{vol}:{page}" if vol and page else (vol or page or "")
    parts = [f"{auth_str} ({year}) {title}."]
    if journal:
        parts.append(f"{journal}{' ' + loc if loc else ''}.")
    return " ".join(parts)


def main():
    cache = load_cache()

    # Collect unique keys from data file
    keys = set()
    with open(DATA_FILE, newline="", encoding="utf-8") as f:
        rd = csv.DictReader(f)
        for row in rd:
            src = row.get("Source", "").strip()
            if src:
                keys.add(src)
    keys = sorted(keys)
    print(f"Found {len(keys)} unique Source keys")

    rows = []
    not_found = []
    found_doi = 0

    for key in keys:
        author_q, year, et_al, author_list = parse_key(key)
        if author_q is None:
            print(f"  UNPARSEABLE: {key!r}")
            rows.append({"key": key, "citation": key, "doi": "", "note": ""})
            not_found.append(key)
            continue

        cache_key = f"{key}"
        if cache_key in cache:
            result = cache[cache_key]
        else:
            try:
                time.sleep(RATE_SLEEP)
                data = crossref_query(author_q, year)
                items = data.get("message", {}).get("items", [])
                item, score = best_match(items, author_list, year)
                result = {
                    "doi": item.get("DOI", "") if item and score >= SIM_ACCEPT else "",
                    "citation": format_citation(item, key) if item and score >= SIM_ACCEPT else key,
                    "note": f"score={score:.2f}" if item else "not_found",
                    "score": score,
                }
            except Exception as e:
                print(f"  ERROR querying {key!r}: {e}")
                result = {"doi": "", "citation": key, "note": "query_error", "score": 0.0}
            cache[cache_key] = result
            save_cache(cache)

        doi = result.get("doi", "")
        note = result.get("note", "")
        citation = result.get("citation", key)
        score = result.get("score", 0.0)

        if doi:
            found_doi += 1
            print(f"  DOI {doi[:35]:<35} [{score:.2f}] {key!r}")
        else:
            not_found.append(key)
            print(f"  NOT_FOUND                                       {key!r}")

        rows.append({"key": key, "citation": citation, "doi": doi, "note": note})

    # Add self-entry for the compilation paper
    self_citation = (
        "Ghaderi R, Nielsen UN, He Z (2026) Morphometric parameters and population-level "
        "body mass of predatory soil nematodes (Mononchida) collected from 246 sites across "
        "21 countries. Applied Soil Ecology 217:106605."
    )
    rows.insert(0, {
        "key": SELF_KEY,
        "citation": self_citation,
        "doi": SELF_DOI,
        "note": "self",
    })

    # Write references.csv
    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["key", "citation", "doi", "note"])
        w.writeheader()
        w.writerows(rows)

    print(f"\nWrote {len(rows)} entries to references.csv")
    print(f"  DOI found: {found_doi} / {len(keys)}")
    print(f"  Not found ({len(not_found)}): {', '.join(not_found[:10])}{'...' if len(not_found)>10 else ''}")


if __name__ == "__main__":
    main()
