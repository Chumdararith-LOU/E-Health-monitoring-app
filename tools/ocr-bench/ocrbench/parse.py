"""Turn OCR tokens from a BP monitor or glucose meter photo into a reading.

Input is a list of Token (text + box + optional confidence), so the same parser
scores any engine: Tesseract here, ML Kit when its tokens are dumped from the phone.

Rules (they match the app, see mobile/lib/data/ranges.dart and reading_form_screen.dart):
  - a value outside the safe limits is never pre-filled (FR-06)
  - a field the engine was unsure about is "flagged" -> the form highlights it
  - if the reading cannot be trusted at all -> fallback: manual entry with the photo (US-09)
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

# Same numbers as mobile/lib/data/ranges.dart. Change them there first.
SAFE = {"systolic": (50.0, 260.0), "diastolic": (30.0, 160.0), "pulse": (30.0, 220.0)}
GLUCOSE_MGDL = (20.0, 600.0)
MMOL_FACTOR = 18.0
GLUCOSE_MMOL = (round(GLUCOSE_MGDL[0] / MMOL_FACTOR, 1), round(GLUCOSE_MGDL[1] / MMOL_FACTOR, 1))

# Tesseract confidence is 0-100. Below this a field is flagged "please check".
LOW_CONF = 80.0
# The main readout is the tallest text on the screen; smaller numbers (time, date) are ignored.
TALL_RATIO = 0.55


@dataclass(frozen=True)
class Token:
    text: str
    x: float
    y: float
    w: float
    h: float
    conf: float | None = None  # None when the engine gives no confidence

    @property
    def cy(self) -> float:
        return self.y + self.h / 2


@dataclass
class Parsed:
    values: dict = field(default_factory=dict)  # field -> number or unit string
    flagged: set = field(default_factory=set)  # fields the user must check
    fallback: bool = False  # True -> send the user to manual entry
    reason: str = ""


_NUM = re.compile(r"^\d{1,3}(?:[.,]\d)?$")
_LOOKALIKE = str.maketrans({"O": "0", "o": "0", "D": "0", "Q": "0", "l": "1", "I": "1", "|": "1", "S": "5", "s": "5", "B": "8", "Z": "2"})
_LABELS = {
    "systolic": re.compile(r"^sys\w*$", re.I),
    "diastolic": re.compile(r"^dia\w*$", re.I),
    "pulse": re.compile(r"^(pul\w*|pr)$", re.I),
}
_MMOL = re.compile(r"mm[o0]l")
_MGDL = re.compile(r"m\s*g\s*[/l]?\s*d\s*[l1i]")


def _number(text: str):
    """Return (value, corrected) or None. 'corrected' = a look-alike letter was swapped for a digit."""
    t = text.strip()
    if _NUM.match(t):
        return float(t.replace(",", ".")), False
    if re.fullmatch(r"[0-9OoDQlI|SsBZ.,]{1,4}", t) and re.search(r"\d", t):
        fixed = t.translate(_LOOKALIKE)
        if _NUM.match(fixed):
            return float(fixed.replace(",", ".")), True
    return None


def _tall_numbers(tokens):
    """Numeric tokens that are as tall as the main readout: list of (token, value, corrected)."""
    found = [(t, *n) for t in tokens if (n := _number(t.text)) is not None]
    if not found:
        return []
    tallest = max(t.h for t, _, _ in found)
    return [f for f in found if f[0].h >= TALL_RATIO * tallest]


def _overlap(a: Token, b: Token) -> bool:
    return min(a.y + a.h, b.y + b.h) - max(a.y, b.y) > 0


def _unsure(tok: Token, corrected: bool) -> bool:
    return corrected or (tok.conf is not None and tok.conf < LOW_CONF)


def parse_bp(tokens) -> Parsed:
    """Read SYS / DIA / PULSE. All three are needed; anything less is a fallback."""
    nums = _tall_numbers(tokens)
    assigned: dict[str, int] = {}

    for name, rx in _LABELS.items():
        label = next((t for t in tokens if rx.match(t.text.strip(" .:/"))), None)
        if label is None:
            continue
        rows = [i for i, (t, _, _) in enumerate(nums) if i not in assigned.values() and _overlap(label, t)]
        if rows:
            assigned[name] = min(rows, key=lambda i: abs(nums[i][0].cy - label.cy))

    if len(assigned) < 3 and len(nums) == 3:  # labels missing or unreadable: top to bottom is SYS, DIA, PULSE
        order = sorted(range(3), key=lambda i: nums[i][0].cy)
        assigned = dict(zip(("systolic", "diastolic", "pulse"), order))

    out = Parsed()
    for name, (lo, hi) in SAFE.items():
        if name not in assigned:
            out.flagged.add(name)
            continue
        tok, value, corrected = nums[assigned[name]]
        if not lo <= value <= hi:
            out.flagged.add(name)
            continue
        out.values[name] = value
        if _unsure(tok, corrected):
            out.flagged.add(name)

    sys_, dia = out.values.get("systolic"), out.values.get("diastolic")
    if sys_ is not None and dia is not None and sys_ <= dia:
        out.flagged |= {"systolic", "diastolic"}
        out.fallback, out.reason = True, "systolic is not above diastolic"
    elif len(out.values) < 3:
        out.fallback, out.reason = True, f"read {len(out.values)} of 3 values"
    return out


def parse_glucose(tokens) -> Parsed:
    """Read the glucose value and its unit (mg/dL or mmol/L)."""
    out = Parsed()
    nums = _tall_numbers(tokens)
    if not nums:
        out.fallback, out.reason = True, "no number found"
        return out

    nums.sort(key=lambda n: -n[0].h)
    tok, value, corrected = nums[0]
    if len(nums) > 1 and nums[1][0].h >= 0.9 * tok.h:
        out.flagged.add("glucose")  # two numbers of the same size: which one is the reading?

    text = " ".join(t.text.lower() for t in tokens)
    if _MMOL.search(text):
        unit = "mmol/L"
    elif _MGDL.search(text):
        unit = "mg/dL"
    else:
        unit = "mmol/L" if "." in tok.text or "," in tok.text else "mg/dL"
        out.flagged.add("unit")  # the unit was not seen on the screen, we guessed

    lo, hi = GLUCOSE_MMOL if unit == "mmol/L" else GLUCOSE_MGDL
    if not lo <= value <= hi:
        out.flagged.add("glucose")
        out.fallback, out.reason = True, f"{value:g} {unit} is outside {lo:g} to {hi:g}"
        return out

    out.values = {"glucose": value, "unit": unit}
    if _unsure(tok, corrected):
        out.flagged.add("glucose")
    return out


def parse(device: str, tokens) -> Parsed:
    if device == "bp":
        return parse_bp(tokens)
    if device == "glucose":
        return parse_glucose(tokens)
    raise ValueError(f"unknown device: {device!r} (use 'bp' or 'glucose')")
