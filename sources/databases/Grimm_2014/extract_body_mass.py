"""Extract body mass rows from Grimm_etal_Reptile_DB_Update_2015.accdb.

Filters Morphometry to Trait == 2 (mass in g), then joins Species,
Lookup Who, and References. Writes Grimm_2014_body_mass.csv.

Run with: python3 -I extract_body_mass.py
"""
import csv
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
ACCDB = HERE / "Grimm_etal_Reptile_DB_Update_2015.accdb"
OUT = HERE / "Grimm_2014_body_mass.csv"

TABLES = ["Morphometry", "Species", "References", "Lookup Who"]
MASS_TRAIT_ID = "2"


def export_table(accdb: Path, table: str) -> list[dict]:
    result = subprocess.run(
        ["mdb-export", str(accdb), table],
        capture_output=True, text=True, check=True,
    )
    return list(csv.DictReader(result.stdout.splitlines()))


def main():
    print(f"Reading: {ACCDB.name}")
    morphometry = export_table(ACCDB, "Morphometry")
    species = export_table(ACCDB, "Species")
    references = export_table(ACCDB, "References")
    who_lookup = export_table(ACCDB, "Lookup Who")

    mass_rows = [r for r in morphometry if r["Trait"] == MASS_TRAIT_ID]
    print(f"  Mass rows (Trait=2): {len(mass_rows)}")

    sp_by_id = {r["Species ID"]: r for r in species}
    ref_by_id = {r["Ref_ID"]: r for r in references}
    who_by_id = {r["ID"]: r["Who"] for r in who_lookup}

    out_rows = []
    for r in mass_rows:
        sp = sp_by_id[r["Species_ID"]]
        ref = ref_by_id[r["Ref_ID"]]
        out_rows.append({
            "morphometry_id":       r["ID"],
            "species_name_seh":     sp["Species name SEH"],
            "current_species_name": sp["Current species name"],
            "mass_min_g":           r["Min"],
            "mass_max_g":           r["Max"],
            "mass_mean_g":          r["Mean"],
            "sample_size":          r["Sample_size"],
            "who":                  who_by_id[r["Who"]],
            "country_id":           r["Country_ID"],
            "country_specs":        r["Country_Specifications"],
            "altitude_m":           r["Altitude (m)"],
            "latitude":             r["Latitude"],
            "longitude":            r["Longitude"],
            "ref_id":               ref["Ref_ID"],
            "ref_abbr":             ref["Ref_Abbr"],
            "author":               ref["Author"],
            "second_author":        ref["Second Author"],
            "last_author":          ref["Last Author"],
            "year":                 ref["Year"],
            "title":                ref["Title"],
            "journal":              ref["Journal"],
            "volume_number":        ref["Number"],
            "pages":                ref["Pages"],
            "book_author":          ref["Book Author"],
            "book_title":           ref["Book Title"],
            "publisher":            ref["Publisher"],
            "city":                 ref["City"],
            "doi":                  ref["DOI"],
            "isbn":                 ref["ISBN"],
        })

    fieldnames = list(out_rows[0].keys())
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(out_rows)

    print(f"  Unique species:    {len({r['current_species_name'] for r in out_rows})}")
    print(f"  Unique references: {len({r['ref_id'] for r in out_rows})}")
    print(f"Written: {OUT.name}  ({len(out_rows)} rows)")


if __name__ == "__main__":
    sys.exit(main())
