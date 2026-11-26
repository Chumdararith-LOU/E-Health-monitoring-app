"""Score OCR predictions against the true readings (the test plan's benchmark, issue #59).

truth.csv:        photo,device,condition,systolic,diastolic,pulse,glucose,unit
predictions.csv:  photo,engine,device,systolic,diastolic,pulse,glucose,unit,flagged,fallback,reason,raw_text

Measures, per engine, per device and per photo condition:
  field accuracy    correct fields / all fields        target >= 80% per device
  reading accuracy  photos with every field correct    report only
  silent errors     wrong fields shown without a flag  target <= 5% of fields (proposed)
  fallback rate     photos sent to manual entry        report only
A photo sent to manual entry (fallback) counts its fields as not read: wrong, but never silent.
"""

from __future__ import annotations

import csv
from collections import defaultdict

FIELDS = {"bp": ("systolic", "diastolic", "pulse"), "glucose": ("glucose", "unit")}
PREDICTION_COLUMNS = ["photo", "engine", "device", "systolic", "diastolic", "pulse", "glucose", "unit", "flagged", "fallback", "reason", "raw_text"]
TARGET_ACCURACY = 0.80
TARGET_SILENT = 0.05


def _same(truth: str, pred: str) -> bool:
    truth, pred = (truth or "").strip(), (pred or "").strip()
    if not pred:
        return False
    try:
        return abs(float(truth) - float(pred)) < 0.05
    except ValueError:
        return truth.lower() == pred.lower()


def read_csv(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def write_predictions(path, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=PREDICTION_COLUMNS)
        w.writeheader()
        w.writerows(rows)


def prediction_row(photo, engine, device, parsed, raw_text=""):
    return {
        "photo": photo, "engine": engine, "device": device,
        **{k: parsed.values.get(k, "") for k in ("systolic", "diastolic", "pulse", "glucose", "unit")},
        "flagged": ";".join(sorted(parsed.flagged)), "fallback": int(parsed.fallback),
        "reason": parsed.reason, "raw_text": raw_text,
    }


class _Tally:
    def __init__(self):
        self.fields = self.correct = self.silent = self.photos = self.perfect = self.fallbacks = 0

    def add_photo(self, results, fallback):
        self.photos += 1
        self.fallbacks += int(fallback)
        self.fields += len(results)
        self.correct += sum(r == "ok" for r in results)
        self.silent += sum(r == "silent" for r in results)
        self.perfect += all(r == "ok" for r in results)

    def summary(self):
        return {
            "photos": self.photos, "fields": self.fields, "correct": self.correct,
            "field_accuracy": self.correct / self.fields if self.fields else 0.0,
            "reading_accuracy": self.perfect / self.photos if self.photos else 0.0,
            "silent_errors": self.silent,
            "silent_error_rate": self.silent / self.fields if self.fields else 0.0,
            "fallback_rate": self.fallbacks / self.photos if self.photos else 0.0,
        }


def score(truth_rows, prediction_rows):
    """Return {engine: {"device": {...}, "condition": {...}, "missing": [photos]}}."""
    truth = {r["photo"]: r for r in truth_rows}
    engines = defaultdict(dict)
    for p in prediction_rows:
        engines[p["engine"]][p["photo"]] = p

    report = {}
    for engine, preds in engines.items():
        by_device, by_condition = defaultdict(_Tally), defaultdict(_Tally)
        for photo, t in truth.items():
            pred = preds.get(photo)
            if pred is None:
                continue
            fields = FIELDS[t["device"]]
            fallback = pred["fallback"] in ("1", 1, True, "True")
            flagged = set(filter(None, pred["flagged"].split(";")))
            results = []
            for f in fields:
                shown = (not fallback) and bool((pred.get(f) or "").strip())
                if shown and _same(t[f], pred[f]):
                    results.append("ok")
                elif shown and f not in flagged:
                    results.append("silent")  # wrong value, shown to the user with no warning
                else:
                    results.append("wrong")
            by_device[t["device"]].add_photo(results, fallback)
            by_condition[(t["device"], t.get("condition", ""))].add_photo(results, fallback)
        report[engine] = {
            "device": {d: tally.summary() for d, tally in sorted(by_device.items())},
            "condition": {k: tally.summary() for k, tally in sorted(by_condition.items())},
            "missing": sorted(set(truth) - set(preds)),
        }
    return report


def _pct(x):
    return f"{x * 100:.0f}%"


def render_markdown(report):
    lines = []
    for engine, r in report.items():
        lines += [f"## {engine}", "", "| Device | Photos | Field accuracy | Reading accuracy | Silent errors | Fallback | Result |", "| --- | --- | --- | --- | --- | --- | --- |"]
        for device, s in r["device"].items():
            ok = s["field_accuracy"] >= TARGET_ACCURACY and s["silent_error_rate"] <= TARGET_SILENT
            lines.append(f"| {device} | {s['photos']} | {_pct(s['field_accuracy'])} (target {_pct(TARGET_ACCURACY)}) | {_pct(s['reading_accuracy'])} | {_pct(s['silent_error_rate'])} (limit {_pct(TARGET_SILENT)}) | {_pct(s['fallback_rate'])} | {'PASS' if ok else 'FAIL'} |")
        lines += ["", "By condition:", "", "| Device | Condition | Photos | Field accuracy | Silent errors | Fallback |", "| --- | --- | --- | --- | --- | --- |"]
        for (device, cond), s in r["condition"].items():
            lines.append(f"| {device} | {cond or '-'} | {s['photos']} | {_pct(s['field_accuracy'])} | {_pct(s['silent_error_rate'])} | {_pct(s['fallback_rate'])} |")
        if r["missing"]:
            lines += ["", f"No prediction for: {', '.join(r['missing'])}"]
        lines.append("")
    return "\n".join(lines)
