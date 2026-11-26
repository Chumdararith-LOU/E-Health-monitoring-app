import unittest

from ocrbench.score import render_markdown, score

TRUTH = [
    {"photo": "a.jpg", "device": "bp", "condition": "bright", "systolic": "132", "diastolic": "84", "pulse": "72", "glucose": "", "unit": ""},
    {"photo": "b.jpg", "device": "bp", "condition": "glare", "systolic": "120", "diastolic": "80", "pulse": "65", "glucose": "", "unit": ""},
    {"photo": "c.jpg", "device": "bp", "condition": "glare", "systolic": "150", "diastolic": "95", "pulse": "80", "glucose": "", "unit": ""},
    {"photo": "g.jpg", "device": "glucose", "condition": "bright", "systolic": "", "diastolic": "", "pulse": "", "glucose": "118", "unit": "mg/dL"},
]


def pred(photo, device="bp", engine="e", fallback=0, flagged="", **v):
    row = {"photo": photo, "engine": engine, "device": device, "systolic": "", "diastolic": "", "pulse": "", "glucose": "", "unit": "", "flagged": flagged, "fallback": fallback, "reason": "", "raw_text": ""}
    row.update({k: str(x) for k, x in v.items()})
    return row


class Score(unittest.TestCase):
    def setUp(self):
        self.preds = [
            pred("a.jpg", systolic=132, diastolic=84, pulse=72),  # all correct
            pred("b.jpg", systolic=120, diastolic=80, pulse=85),  # pulse wrong and NOT flagged -> silent
            pred("c.jpg", fallback=1, flagged="systolic;diastolic;pulse"),  # sent to manual entry
            pred("g.jpg", device="glucose", glucose=118, unit="mg/dL"),
        ]
        self.r = score(TRUTH, self.preds)["e"]

    def test_bp_numbers(self):
        s = self.r["device"]["bp"]
        self.assertEqual((s["photos"], s["fields"], s["correct"], s["silent_errors"]), (3, 9, 5, 1))
        self.assertAlmostEqual(s["field_accuracy"], 5 / 9)
        self.assertAlmostEqual(s["reading_accuracy"], 1 / 3)
        self.assertAlmostEqual(s["silent_error_rate"], 1 / 9)
        self.assertAlmostEqual(s["fallback_rate"], 1 / 3)

    def test_glucose_counts_value_and_unit(self):
        s = self.r["device"]["glucose"]
        self.assertEqual((s["fields"], s["correct"]), (2, 2))

    def test_flagged_wrong_value_is_not_silent(self):
        preds = [pred("b.jpg", systolic=120, diastolic=80, pulse=85, flagged="pulse")]
        s = score(TRUTH, preds)["e"]["device"]["bp"]
        self.assertEqual(s["silent_errors"], 0)
        self.assertEqual(s["correct"], 2)

    def test_by_condition(self):
        glare = self.r["condition"][("bp", "glare")]
        self.assertEqual((glare["photos"], glare["correct"]), (2, 2))

    def test_unit_comparison_ignores_case(self):
        preds = [pred("g.jpg", device="glucose", glucose=118, unit="MG/DL")]
        self.assertEqual(score(TRUTH, preds)["e"]["device"]["glucose"]["correct"], 2)

    def test_engines_are_scored_separately_and_missing_is_listed(self):
        both = self.preds + [pred("a.jpg", engine="other", systolic=1, diastolic=1, pulse=1)]
        rep = score(TRUTH, both)
        self.assertEqual(set(rep), {"e", "other"})
        self.assertEqual(rep["other"]["missing"], ["b.jpg", "c.jpg", "g.jpg"])

    def test_markdown_has_pass_fail(self):
        text = render_markdown(score(TRUTH, self.preds))
        self.assertIn("## e", text)
        self.assertIn("FAIL", text)  # bp: 56% accuracy


if __name__ == "__main__":
    unittest.main()
