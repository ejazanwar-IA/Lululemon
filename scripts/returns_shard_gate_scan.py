#!/usr/bin/env python3
"""Stream-scan returns CSV from stdin (or byte-limited); aggregate gate metrics only."""
from __future__ import annotations

import csv
import sys
from collections import Counter


def main() -> None:
    n = 0
    units_pos = units_neg = units_zero = 0
    price_nonzero = price_zero = 0
    dates: list[str] = []
    returns_suffix = 0
    order_patterns: Counter[str] = Counter()
    samples: list[dict] = []

    reader = csv.DictReader(sys.stdin)
    header = reader.fieldnames
    for row in reader:
        n += 1
        u = (row.get("UNITS") or "").strip()
        try:
            uf = float(u)
            if uf > 0:
                units_pos += 1
            elif uf < 0:
                units_neg += 1
            else:
                units_zero += 1
        except ValueError:
            units_zero += 1
        p = (row.get("PRICE_SALES_TOTAL") or "").strip()
        try:
            if float(p) != 0:
                price_nonzero += 1
            else:
                price_zero += 1
        except ValueError:
            price_zero += 1
        d = (row.get("DATE_TRANSACTION") or "").strip()
        if d:
            dates.append(d)
        oid = (row.get("SALES_ORDER_ID") or "").strip()
        if "RETURNS" in oid.upper():
            returns_suffix += 1
        if "|" in oid:
            order_patterns["pipe_delimited"] += 1
        elif oid.isdigit():
            order_patterns["numeric"] += 1
        else:
            order_patterns["other"] += 1
        if n <= 3:
            samples.append(row)

    print("HEADER:", header)
    print(f"rows={n:,}")
    if n:
        print(f"units>0={units_pos:,} ({100 * units_pos / n:.2f}%)")
        print(f"units<0={units_neg:,} ({100 * units_neg / n:.2f}%)")
        print(f"units=0={units_zero:,} ({100 * units_zero / n:.2f}%)")
        print(f"price!=0={price_nonzero:,} ({100 * price_nonzero / n:.2f}%)")
        print(f"order_id_RETURNS={returns_suffix:,} ({100 * returns_suffix / n:.2f}%)")
    if dates:
        print(f"date_min={min(dates)} date_max={max(dates)} distinct_dates={len(set(dates))}")
    print("order_patterns:", dict(order_patterns))
    for i, s in enumerate(samples, 1):
        print(f"SAMPLE_{i}:", {k: s.get(k) for k in (header or [])})


if __name__ == "__main__":
    main()
