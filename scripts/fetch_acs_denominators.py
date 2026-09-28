"""Pull Nebraska ACS employed-worker denominators by industry and occupation.

Tables (civilian employed population 16 years and over, by sex):
  C24030  Sex by Industry
  C24010  Sex by Occupation

Writes one tidy CSV per table and year to data/denominators/:
  acs_<dataset>_<year>_<table>_NE.csv
with columns: table, dataset, year, variable, label, estimate, moe

Labels come from the API's own variable metadata, so nothing about the line
structure is hard-coded here. Check the labels against the DC industry and
occupation code crosswalk before joining.

Usage:
  python scripts/fetch_acs_denominators.py                 # acs5 2024 (2020-2024)
  python scripts/fetch_acs_denominators.py --dataset acs1 --years 2021 2022 2023 2024
Optional: set CENSUS_API_KEY in the environment. Low-volume pulls work without one.

Needs outbound access to api.census.gov. Standard library only.
"""
import argparse
import csv
import json
import os
import pathlib
import urllib.parse
import urllib.request

STATE_FIPS = "31"  # Nebraska
TABLES = ["C24030", "C24010"]
OUT_DIR = pathlib.Path(__file__).resolve().parent.parent / "data" / "denominators"


def get_json(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return json.load(r)


def fetch(dataset, year, table, key):
    base = f"https://api.census.gov/data/{year}/acs/{dataset}"
    meta = get_json(f"{base}/groups/{table}.json")["variables"]
    params = {"get": f"NAME,group({table})", "for": f"state:{STATE_FIPS}"}
    if key:
        params["key"] = key
    rows = get_json(f"{base}?{urllib.parse.urlencode(params)}")
    header, values = rows[0], rows[1]
    record = dict(zip(header, values))
    out = []
    for var, info in meta.items():
        if not var.endswith("E") or var not in record:
            continue
        moe_var = var[:-1] + "M"
        out.append({
            "table": table,
            "dataset": dataset,
            "year": year,
            "variable": var,
            "label": info.get("label", ""),
            "estimate": record.get(var),
            "moe": record.get(moe_var),
        })
    out.sort(key=lambda d: d["variable"])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default="acs5", choices=["acs5", "acs1"])
    ap.add_argument("--years", nargs="+", type=int, default=[2024])
    args = ap.parse_args()
    key = os.environ.get("CENSUS_API_KEY", "")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for year in args.years:
        for table in TABLES:
            rows = fetch(args.dataset, year, table, key)
            path = OUT_DIR / f"acs_{args.dataset}_{year}_{table}_NE.csv"
            with open(path, "w", newline="", encoding="utf-8") as f:
                w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
                w.writeheader()
                w.writerows(rows)
            print(f"wrote {path} ({len(rows)} lines)")


if __name__ == "__main__":
    main()
