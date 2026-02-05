#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import csv
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
CONVERTER = SCRIPT_DIR / "convert-mysql-tsv-to-csv.py"
UTF8_BOM = b"\xef\xbb\xbf"


class ConvertMysqlTsvToCsvTests(unittest.TestCase):
    def _run_converter(self, input_bytes: bytes):
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_dir_path = Path(tmp_dir)
            input_path = tmp_dir_path / "input.tsv"
            output_path = tmp_dir_path / "output.csv"

            input_path.write_bytes(input_bytes)

            subprocess.run(
                [sys.executable, str(CONVERTER), str(input_path), str(output_path)],
                check=True,
            )

            return output_path.read_bytes()

    def test_writes_utf8_bom(self):
        out = self._run_converter(b"id\tvalue\n1\tabc\n")
        self.assertTrue(out.startswith(UTF8_BOM))

    def test_strips_input_bom_and_parses_escapes(self):
        input_bytes = UTF8_BOM + (
            b"id\tvalue\n"
            b"1\tHello\\nWorld, \\\"quoted\\\" and tab\\tX and backslash\\\\Y\n"
        )
        out = self._run_converter(input_bytes)
        self.assertTrue(out.startswith(UTF8_BOM))

        with tempfile.TemporaryDirectory() as tmp_dir:
            out_path = Path(tmp_dir) / "out.csv"
            out_path.write_bytes(out)

            with out_path.open("r", encoding="utf-8-sig", newline="") as f:
                rows = list(csv.reader(f))

        self.assertEqual(rows[0], ["id", "value"])
        self.assertEqual(
            rows[1],
            ["1", "Hello\nWorld, \"quoted\" and tab\tX and backslash\\Y"],
        )


if __name__ == "__main__":
    unittest.main()

