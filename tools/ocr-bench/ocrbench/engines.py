"""Get tokens from an OCR engine.

tesseract_tokens(): runs the tesseract CLI on a photo (works here and on any laptop).
read_token_dump(): reads tokens an engine produced on the phone (ML Kit), one JSON object per line:
    {"photo": "bp_01.jpg", "tokens": [{"text": "132", "x": 256, "y": 194, "w": 220, "h": 90, "conf": 97}]}
"conf" is optional (0-100). x, y, w, h are the box in pixels.
"""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

from .parse import Token

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def _preprocess(path: Path, prep: str, tmp_dir: Path) -> Path:
    """prep 'gray' = grayscale + contrast + upscale; 'bw' = also black and white. Needs Pillow."""
    from PIL import Image, ImageOps  # imported late: only needed for --prep

    img = ImageOps.autocontrast(Image.open(path).convert("L"))
    if img.width < 1200:
        scale = 1200 / img.width
        img = img.resize((1200, round(img.height * scale)))
    if prep == "bw":
        mean = sum(i * c for i, c in enumerate(img.histogram())) / (img.width * img.height)
        img = img.point(lambda p: 255 if p > mean else 0)
    out = tmp_dir / f"{path.stem}_{prep}.png"
    img.save(out)
    return out


def tesseract_tokens(path, psm: int = 11, prep: str = "none", lang: str = "eng", exe: str = "tesseract"):
    """Run tesseract and return one Token per word. psm 11 (sparse text) finds the big LCD digits."""
    path = Path(path)
    with tempfile.TemporaryDirectory() as tmp:
        src = path if prep == "none" else _preprocess(path, prep, Path(tmp))
        res = subprocess.run(
            [exe, str(src), "stdout", "--psm", str(psm), "-l", lang, "tsv"],
            capture_output=True, text=True, check=True,
        )
    tokens = []
    for line in res.stdout.splitlines()[1:]:  # first line is the header
        cols = line.split("\t", 11)
        if len(cols) < 12 or cols[0] != "5" or not cols[11].strip():
            continue
        x, y, w, h, conf = (float(c) for c in cols[6:11])
        tokens.append(Token(cols[11].strip(), x, y, w, h, conf if conf >= 0 else None))
    return tokens


def read_token_dump(path):
    """Return {photo file name: [Token, ...]} from a JSON-lines dump made on the phone."""
    dump = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        dump[Path(row["photo"]).name] = [
            Token(t["text"], t["x"], t["y"], t["w"], t["h"], t.get("conf")) for t in row["tokens"]
        ]
    return dump
