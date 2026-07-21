# Client open questions: CSV exports

Per-master workbook tables for lululemon client workshops. **Response (Client)** and some **Action Item** cells are left blank for live fill-in.

**Source of truth (markdown):** [`findings/lululemon_client_open_questions.md`](../../findings/lululemon_client_open_questions.md)

## Files

| CSV | Rows |
|-----|-----:|
| [`product_master_open_questions.csv`](product_master_open_questions.csv) | 18 |
| [`transaction_master_open_questions.csv`](transaction_master_open_questions.csv) | 11 |
| [`inventory_master_open_questions.csv`](inventory_master_open_questions.csv) | 9 |
| [`store_master_open_questions.csv`](store_master_open_questions.csv) | 10 |
| [`calendar_hierarchy_open_questions.csv`](calendar_hierarchy_open_questions.csv) | 2 |
| [`cross_cutting_open_questions.csv`](cross_cutting_open_questions.csv) | 6 |

**Total:** 56 client-facing open items (SizeSmart archived separately).

## Regenerate

After editing row definitions in `export_open_questions_csv.py`:

```bash
python3 deliverables/client_open_questions/export_open_questions_csv.py
```

Outputs: 6 CSV files + OneNote HTML/TSV + `findings/lululemon_client_open_questions.md` (all from one source).

## OneNote paste

| File | How to use |
|------|------------|
| [`open_questions_onenote.html`](open_questions_onenote.html) | Open in browser → select one table → **Cmd+C** → paste into OneNote (best formatting) |
| [`open_questions_onenote_paste.txt`](open_questions_onenote_paste.txt) | Copy one TSV block (header + rows) → paste into OneNote |

Paste **one master section at a time** so each stays a separate table in OneNote.

## Import to Google Sheets

1. Create one tab per master (or one sheet per CSV).
2. File → Import → Upload → select CSV.
3. Fill **Response (Client)** during client calls.
