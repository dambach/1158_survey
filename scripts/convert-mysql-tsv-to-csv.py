#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Convert MySQL batch TSV output (with MySQL-style backslash escapes)
to a proper CSV file with correct quoting.
"""

import csv
import sys


def unescape_mysql(value):
    mapping = {
        "0": "\0",
        "b": "\b",
        "n": "\n",
        "r": "\r",
        "t": "\t",
        "Z": "\x1a",
        "\\": "\\",
        "'": "'",
        '"': '"',
    }
    out = []
    i = 0
    while i < len(value):
        ch = value[i]
        if ch == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            out.append(mapping.get(nxt, nxt))
            i += 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def main():
    if len(sys.argv) != 3:
        print("Usage: convert-mysql-tsv-to-csv.py <input.tsv> <output.csv>", file=sys.stderr)
        return 2

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    with open(input_path, "r", encoding="utf-8", errors="replace") as in_f, open(
        output_path, "w", encoding="utf-8", newline=""
    ) as out_f:
        writer = csv.writer(out_f)
        for line in in_f:
            line = line.rstrip("\n")
            if line == "":
                writer.writerow([])
                continue
            fields = line.split("\t")
            fields = [unescape_mysql(f) for f in fields]
            writer.writerow(fields)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
