# OCR bench

Owner: Phak. Scores OCR engines on photos of the BP monitor and the glucose meter. It is the benchmark in the test plan (issue #59) and the engine comparison for the OCR spike (issue #23: ML Kit vs Tesseract). It is not part of the app or the pnpm workspace, so CI does not run it.

Needs Python 3.10+ and, to run Tesseract, the `tesseract` command (`sudo apt install tesseract-ocr`, or the Windows installer). Pillow is only needed for `--prep`.

## How it works

```
photo -> engine (Tesseract / ML Kit) -> tokens (text, box, confidence)
      -> parse.py -> reading + flagged fields + fallback
      -> score.py -> report
```

`parse.py` follows the app's rules: a value outside the safe limits in `mobile/lib/data/ranges.dart` is never pre-filled, an unsure field is flagged, and a reading that cannot be trusted goes to manual entry (US-09). When you change a limit, change it in `ranges.dart` first, then in `parse.py`.

## Steps

1. Put the photos of one device in a folder, then make a truth file and fill it in. For each photo, write the numbers shown on the display before you run any OCR.

   ```
   python3 bench.py template photos/bp --device bp --out truth_bp.csv
   ```

   `condition` is free text, for example `bright straight`, `dim tilted`, `glare`. Keep the names the same across photos so the report can group them (see the 20-photo table in the test plan). For a combined file, put the glucose rows below the BP rows.

2. Run Tesseract:

   ```
   python3 bench.py run-tesseract photos --truth truth.csv --out pred_tesseract.csv
   ```

   Try `--prep gray` or `--prep bw` if digits are missed, and `--psm 6` for dense screens. Each variant can be saved under its own name with `--engine tesseract-gray`, so the report compares them.

3. ML Kit runs on the phone. Make the app write one JSON object per photo (see `ocrbench/engines.py` for the format), copy the file to your computer, then:

   ```
   python3 bench.py from-tokens tokens_mlkit.jsonl --truth truth.csv --engine mlkit --out pred_mlkit.csv
   ```

4. Score:

   ```
   python3 bench.py score --truth truth.csv --pred pred_tesseract.csv pred_mlkit.csv --out report.md
   ```

## Reading the report

| Measure | Meaning | Target |
| --- | --- | --- |
| Field accuracy | correct fields / all fields (BP: 3 per photo, glucose: value + unit) | at least 80% per device |
| Reading accuracy | photos with every field correct | report only |
| Silent errors | wrong values shown without a "please check" flag | at most 5% of fields |
| Fallback | photos sent to manual entry | report only |

A photo sent to manual entry counts its fields as not read. They are wrong, but not silent, because the user types them.

## Try it on the demo photos

```
python3 bench.py run-tesseract ../../mobile/assets/images --truth samples/truth_demo.csv --out /tmp/pred.csv
python3 bench.py score --truth samples/truth_demo.csv --pred /tmp/pred.csv
```

The demo photos are clean drawings, so they only prove the tool works. The real result needs real device photos.

## Tests

```
python3 -m unittest discover -s tests -t .
```
