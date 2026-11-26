#!/usr/bin/env python3
"""OCR benchmark for the E-Health app (issues #23 spike, #59 plan).

  python3 bench.py template PHOTO_DIR --device bp --out truth.csv
  python3 bench.py run-tesseract PHOTO_DIR --truth truth.csv --out pred_tesseract.csv
  python3 bench.py from-tokens tokens.jsonl --truth truth.csv --engine mlkit --out pred_mlkit.csv
  python3 bench.py score --truth truth.csv --pred pred_tesseract.csv pred_mlkit.csv --out report.md
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

from ocrbench.engines import IMAGE_EXT, read_token_dump, tesseract_tokens
from ocrbench.parse import parse
from ocrbench.score import prediction_row, read_csv, render_markdown, score, write_predictions

TRUTH_COLUMNS = ["photo", "device", "condition", "systolic", "diastolic", "pulse", "glucose", "unit"]


def _raw(tokens):
    return " ".join(t.text for t in tokens)


def cmd_template(a):
    photos = sorted(p.name for p in Path(a.photo_dir).iterdir() if p.suffix.lower() in IMAGE_EXT)
    with open(a.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(TRUTH_COLUMNS)
        for name in photos:
            w.writerow([name, a.device, "", "", "", "", "", "" if a.device == "bp" else "mg/dL"])
    print(f"wrote {a.out} with {len(photos)} photos: fill in the true values and the condition")


def cmd_run_tesseract(a):
    truth = {r["photo"]: r for r in read_csv(a.truth)}
    rows = []
    for name, t in truth.items():
        path = Path(a.photo_dir) / name
        if not path.exists():
            print(f"skip {name}: file not found", file=sys.stderr)
            continue
        tokens = tesseract_tokens(path, psm=a.psm, prep=a.prep)
        rows.append(prediction_row(name, a.engine, t["device"], parse(t["device"], tokens), _raw(tokens)))
    write_predictions(a.out, rows)
    print(f"wrote {a.out} ({len(rows)} photos, engine {a.engine})")


def cmd_from_tokens(a):
    truth = {r["photo"]: r for r in read_csv(a.truth)}
    dump = read_token_dump(a.tokens)
    rows = []
    for name, tokens in dump.items():
        if name not in truth:
            print(f"skip {name}: not in truth.csv", file=sys.stderr)
            continue
        device = truth[name]["device"]
        rows.append(prediction_row(name, a.engine, device, parse(device, tokens), _raw(tokens)))
    write_predictions(a.out, rows)
    print(f"wrote {a.out} ({len(rows)} photos, engine {a.engine})")


def cmd_score(a):
    preds = [row for path in a.pred for row in read_csv(path)]
    text = render_markdown(score(read_csv(a.truth), preds))
    if a.out:
        Path(a.out).write_text(text, encoding="utf-8")
        print(f"wrote {a.out}")
    print(text)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("template", help="list photos into an empty truth.csv")
    s.add_argument("photo_dir")
    s.add_argument("--device", choices=["bp", "glucose"], required=True)
    s.add_argument("--out", default="truth.csv")
    s.set_defaults(fn=cmd_template)

    s = sub.add_parser("run-tesseract", help="run Tesseract on the photos listed in truth.csv")
    s.add_argument("photo_dir")
    s.add_argument("--truth", required=True)
    s.add_argument("--out", required=True)
    s.add_argument("--engine", default="tesseract", help="name shown in the report")
    s.add_argument("--psm", type=int, default=11, help="Tesseract page mode, 11 = sparse text")
    s.add_argument("--prep", choices=["none", "gray", "bw"], default="none", help="pre-processing, needs Pillow")
    s.set_defaults(fn=cmd_run_tesseract)

    s = sub.add_parser("from-tokens", help="parse a token dump made on the phone (ML Kit)")
    s.add_argument("tokens")
    s.add_argument("--truth", required=True)
    s.add_argument("--engine", default="mlkit")
    s.add_argument("--out", required=True)
    s.set_defaults(fn=cmd_from_tokens)

    s = sub.add_parser("score", help="score predictions against truth.csv")
    s.add_argument("--truth", required=True)
    s.add_argument("--pred", nargs="+", required=True)
    s.add_argument("--out")
    s.set_defaults(fn=cmd_score)

    args = p.parse_args(argv)
    args.fn(args)


if __name__ == "__main__":
    main()
