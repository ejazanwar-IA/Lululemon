#!/usr/bin/env python3
"""Add Notion <colgroup> widths to tables missing them. Proportional to cell text length."""

import re
import sys

TARGET_TOTAL = 800
MIN_COL = 70


def max_col_lengths(table_html: str) -> list[int]:
    rows = re.findall(r"<tr>\s*(.*?)\s*</tr>", table_html, re.DOTALL)
    if not rows:
        return []
    ncols = len(re.findall(r"<td>", rows[0]))
    lengths = [0] * ncols
    for row in rows:
        cells = re.findall(r"<td>(.*?)</td>", row, re.DOTALL)
        for i, cell in enumerate(cells):
            text = re.sub(r"<[^>]+>", "", cell)
            lengths[i] = max(lengths[i], len(text.strip()))
    return lengths


def colgroup(lengths: list[int]) -> str:
    total_chars = sum(max(l, 1) for l in lengths)
    raw = [max(MIN_COL, int(TARGET_TOTAL * max(l, 1) / total_chars)) for l in lengths]
    diff = TARGET_TOTAL - sum(raw)
    if diff and raw:
        raw[-1] += diff
    lines = ["<colgroup>"]
    for w in raw:
        lines.append(f'<col width="{w}">')
    lines.append("</colgroup>")
    return "\n".join(lines)


def add_colgroups(content: str) -> str:
    pattern = re.compile(
        r"(<table header-row=\"true\">)\s*(?!<colgroup>)(<tr>)",
        re.MULTILINE,
    )

    def repl(match: re.Match) -> str:
        start = match.start()
        table_open = match.group(1)
        # find end of this table
        end = content.find("</table>", start)
        if end == -1:
            return match.group(0)
        table_html = content[start : end + len("</table>")]
        lengths = max_col_lengths(table_html)
        if not lengths:
            return match.group(0)
        cg = colgroup(lengths)
        return f"{table_open}\n{cg}\n{match.group(2)}"

    return pattern.sub(repl, content)


if __name__ == "__main__":
    text = sys.stdin.read()
    sys.stdout.write(add_colgroups(text))
