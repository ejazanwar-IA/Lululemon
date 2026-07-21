#!/usr/bin/env python3
"""Stream-verify transfer_orders shard against Receipts requirement spec."""
import argparse
import csv
import re
import subprocess
import sys
from collections import Counter


def is_blank(v):
    if v is None:
        return True
    s = str(v).strip()
    return s == "" or s == "\\N"


def parse_date(s):
    s = (s or "").strip()
    if not s or s == "\\N":
        return None
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
        return s
    return "INVALID"


def parse_num(s):
    s = (s or "").strip()
    if not s or s == "\\N":
        return None
    try:
        return float(s)
    except ValueError:
        return "INVALID"


def open_input(path: str | None, gcs_uri: str | None):
    if path:
        return open(path, newline="", encoding="utf-8", errors="replace")
    if gcs_uri:
        proc = subprocess.Popen(
            ["gcloud", "storage", "cat", gcs_uri, "--project=lululemon-01042025"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        return proc.stdout
    raise ValueError("Provide --local or --gcs")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--local")
    ap.add_argument("--gcs")
    args = ap.parse_args()

    n = 0
    checks = {
        "transfer_order_id_pop": 0,
        "transfer_order_id_blank": 0,
        "transfer_order_id_unique": set(),
        "sku_id_pop": 0,
        "sku_id_blank": 0,
        "location_id_receiving_pop": 0,
        "location_id_receiving_blank": 0,
        "date_received_pop": 0,
        "date_received_blank": 0,
        "date_received_invalid": 0,
        "units_received_pop": 0,
        "units_received_blank": 0,
        "units_received_gt0": 0,
        "units_received_eq0": 0,
        "units_received_invalid": 0,
        "recv_blank_units_gt0": 0,
        "recv_blank_units_eq0": 0,
        "recv_pop_units_blank": 0,
        "recv_pop_units_eq0": 0,
        "recv_pop_units_gt0": 0,
        "recv_pop_units_invalid": 0,
    }
    composite = Counter()
    samples = {k: [] for k in [
        "recv_blank_units_gt0",
        "recv_pop_units_blank",
        "recv_pop_units_gt0",
        "duplicate_composite",
    ]}

    with open_input(args.local, args.gcs) as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames or []

        for row in reader:
            n += 1
            toid = row.get("TRANSFER_ORDER_ID", "")
            sku = row.get("SKU_ID", "")
            loc = row.get("LOCATION_ID_RECEIVING", "")
            dr = row.get("DATE_RECEIVED", "")
            ur = row.get("UNITS_RECEIVED", "")

            if not is_blank(toid):
                checks["transfer_order_id_pop"] += 1
                checks["transfer_order_id_unique"].add(toid)
            else:
                checks["transfer_order_id_blank"] += 1

            if not is_blank(sku):
                checks["sku_id_pop"] += 1
            else:
                checks["sku_id_blank"] += 1

            if not is_blank(loc):
                checks["location_id_receiving_pop"] += 1
            else:
                checks["location_id_receiving_blank"] += 1

            dr_blank = is_blank(dr)
            if dr_blank:
                checks["date_received_blank"] += 1
            else:
                checks["date_received_pop"] += 1
                if parse_date(dr) == "INVALID":
                    checks["date_received_invalid"] += 1

            ur_parsed = parse_num(ur)
            ur_blank = is_blank(ur)
            if ur_blank:
                checks["units_received_blank"] += 1
            else:
                checks["units_received_pop"] += 1
                if ur_parsed == "INVALID":
                    checks["units_received_invalid"] += 1
                elif ur_parsed is not None:
                    if ur_parsed > 0:
                        checks["units_received_gt0"] += 1
                    else:
                        checks["units_received_eq0"] += 1

            if dr_blank and ur_parsed not in (None, "INVALID") and ur_parsed > 0:
                checks["recv_blank_units_gt0"] += 1
                if len(samples["recv_blank_units_gt0"]) < 3:
                    samples["recv_blank_units_gt0"].append(dict(row))
            if dr_blank and ur_parsed == 0:
                checks["recv_blank_units_eq0"] += 1

            if not dr_blank and ur_blank:
                checks["recv_pop_units_blank"] += 1
                if len(samples["recv_pop_units_blank"]) < 3:
                    samples["recv_pop_units_blank"].append(dict(row))
            if not dr_blank and ur_parsed == 0:
                checks["recv_pop_units_eq0"] += 1
            if not dr_blank and ur_parsed not in (None, "INVALID") and ur_parsed > 0:
                checks["recv_pop_units_gt0"] += 1
                if len(samples["recv_pop_units_gt0"]) < 3:
                    samples["recv_pop_units_gt0"].append(dict(row))
            if not dr_blank and ur_parsed == "INVALID":
                checks["recv_pop_units_invalid"] += 1

            key = (toid, sku, loc, dr)
            composite[key] += 1
            if composite[key] == 2 and len(samples["duplicate_composite"]) < 3:
                samples["duplicate_composite"].append({"key": key, "count": 2})

    pct = lambda x: 100.0 * x / max(n, 1)
    dup_extra = sum(c - 1 for c in composite.values() if c > 1)
    dup_keys = sum(1 for c in composite.values() if c > 1)

    print("=== SHARD META ===")
    src = args.local or args.gcs
    print(f"source={src}")
    print(f"rows={n:,}")
    print(f"columns={cols}")
    print()

    print("=== REQUIREMENT FIELD CHECK ===")
    absent = {
        "Receipt ID": "RECEIPT_ID",
        "Line ID": "LINE_ID",
        "ASN ID": "ASN_ID",
        "Pack ID": "PACK_ID",
        "Created Timestamp": None,
        "Updated Timestamp": None,
    }
    for name, col in absent.items():
        if col:
            present = col in cols
        else:
            present = any(
                ("CREATED" if "Created" in name else "UPDATED") in c.upper()
                and "TIMESTAMP" in c.upper()
                for c in cols
            )
        print(f"{name}: column_present={present} | expected=Not Available | status={'OK' if not present else 'CONTRADICTION'}")

    mappings = [
        ("PO ID (proxy)", "TRANSFER_ORDER_ID", checks["transfer_order_id_pop"]),
        ("Location ID", "LOCATION_ID_RECEIVING", checks["location_id_receiving_pop"]),
        ("SKU ID", "SKU_ID", checks["sku_id_pop"]),
        ("Receipt Date", "DATE_RECEIVED", checks["date_received_pop"]),
        ("Total Receipt Qty", "UNITS_RECEIVED", checks["units_received_pop"]),
    ]
    for name, col, pop in mappings:
        print(f"{name}: column={col} | fill_rate={pop:,} ({pct(pop):.2f}%)")

    print()
    print("=== DETAIL METRICS ===")
    print(f"transfer_order_id distinct={len(checks['transfer_order_id_unique']):,}")
    print(f"date_received blank={checks['date_received_blank']:,} ({pct(checks['date_received_blank']):.2f}%)")
    print(f"units_received >0={checks['units_received_gt0']:,} ({pct(checks['units_received_gt0']):.2f}%)")
    print(f"units_received =0={checks['units_received_eq0']:,} ({pct(checks['units_received_eq0']):.2f}%)")
    print(
        "units_received >0 among date_received populated="
        f"{checks['recv_pop_units_gt0']:,} of {checks['date_received_pop']:,} "
        f"({100 * checks['recv_pop_units_gt0'] / max(checks['date_received_pop'], 1):.2f}%)"
    )

    print()
    print("=== CROSS-FIELD PATTERNS ===")
    print(f"date_received blank + units_received>0: {checks['recv_blank_units_gt0']:,} ({pct(checks['recv_blank_units_gt0']):.2f}%)")
    print(f"date_received blank + units_received=0: {checks['recv_blank_units_eq0']:,} ({pct(checks['recv_blank_units_eq0']):.2f}%)")
    print(f"date_received populated + units_received blank: {checks['recv_pop_units_blank']:,} ({pct(checks['recv_pop_units_blank']):.2f}%)")
    print(f"date_received populated + units_received=0: {checks['recv_pop_units_eq0']:,} ({pct(checks['recv_pop_units_eq0']):.2f}%)")
    print(f"date_received populated + units_received>0: {checks['recv_pop_units_gt0']:,} ({pct(checks['recv_pop_units_gt0']):.2f}%)")

    print()
    print("=== GRAIN / UNIQUENESS ===")
    print("composite (transfer_order_id, sku_id, location_id_receiving, date_received)")
    print(f"distinct_keys={len(composite):,} duplicate_keys={dup_keys:,} extra_rows={dup_extra:,}")

    print()
    print("=== EXTRA COLUMNS (not in receipts spec) ===")
    spec_cols = {
        "TRANSFER_ORDER_ID",
        "SKU_ID",
        "LOCATION_ID_RECEIVING",
        "UNITS_RECEIVED",
        "DATE_RECEIVED",
    }
    print([c for c in cols if c not in spec_cols])

    print()
    print("=== SAMPLES ===")
    for k, rows in samples.items():
        print(f"-- {k} --")
        for r in rows:
            print(r)


if __name__ == "__main__":
    main()
