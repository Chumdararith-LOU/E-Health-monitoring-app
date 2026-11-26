import unittest

from ocrbench.parse import Token, parse_bp, parse_glucose


def T(text, x, y, h=40, w=80, conf=95.0):
    return Token(text, x, y, w, h, conf)


def bp_screen(sys_="132", dia="84", pul="72", conf=95.0):
    """A typical screen: small labels on the left, big numbers on the right, rows top to bottom."""
    return [
        T("SYS", 10, 20, h=14, w=40), T(sys_, 200, 10, h=60, conf=conf),
        T("DIA", 10, 120, h=14, w=40), T(dia, 200, 110, h=60, conf=conf),
        T("PUL", 10, 220, h=14, w=40), T(pul, 200, 210, h=60, conf=conf),
    ]


class ParseBp(unittest.TestCase):
    def test_clear_screen(self):
        r = parse_bp(bp_screen())
        self.assertEqual(r.values, {"systolic": 132, "diastolic": 84, "pulse": 72})
        self.assertFalse(r.fallback)
        self.assertEqual(r.flagged, set())

    def test_no_labels_uses_top_to_bottom_order(self):
        r = parse_bp([t for t in bp_screen() if t.text.isdigit()])
        self.assertEqual(r.values, {"systolic": 132, "diastolic": 84, "pulse": 72})

    def test_labels_win_over_order(self):
        # pulse printed on the top row: the label decides, not the position
        tokens = [T("PUL", 10, 20, h=14), T("72", 200, 10, h=60), T("SYS", 10, 120, h=14), T("132", 200, 110, h=60), T("DIA", 10, 220, h=14), T("84", 200, 210, h=60)]
        self.assertEqual(parse_bp(tokens).values, {"systolic": 132, "diastolic": 84, "pulse": 72})

    def test_low_confidence_field_is_flagged_not_dropped(self):
        tokens = bp_screen()
        tokens[5] = T("72", 200, 210, h=60, conf=60.0)
        r = parse_bp(tokens)
        self.assertEqual(r.values["pulse"], 72)
        self.assertEqual(r.flagged, {"pulse"})
        self.assertFalse(r.fallback)

    def test_value_outside_safe_limits_is_never_filled(self):
        r = parse_bp(bp_screen(sys_="432"))  # the blurry demo photo reads 132 as 432
        self.assertNotIn("systolic", r.values)
        self.assertIn("systolic", r.flagged)
        self.assertTrue(r.fallback)

    def test_systolic_not_above_diastolic_falls_back(self):
        r = parse_bp(bp_screen(sys_="80", dia="120"))
        self.assertTrue(r.fallback)
        self.assertEqual(r.flagged, {"systolic", "diastolic"})

    def test_two_values_only_falls_back(self):
        r = parse_bp([t for t in bp_screen() if t.text not in ("DIA", "84")])
        self.assertTrue(r.fallback)
        self.assertIn("diastolic", r.flagged)

    def test_letter_for_digit_is_fixed_and_flagged(self):
        r = parse_bp(bp_screen(pul="7Z"))
        self.assertEqual(r.values["pulse"], 72)
        self.assertEqual(r.flagged, {"pulse"})

    def test_small_numbers_are_ignored(self):
        tokens = bp_screen() + [T("24", 300, 300, h=12)]  # a date or battery figure
        self.assertEqual(parse_bp(tokens).values, {"systolic": 132, "diastolic": 84, "pulse": 72})

    def test_nothing_read(self):
        r = parse_bp([])
        self.assertTrue(r.fallback)
        self.assertEqual(r.values, {})


class ParseGlucose(unittest.TestCase):
    def test_mgdl(self):
        r = parse_glucose([T("GLU", 10, 10, h=14), T("118", 100, 100, h=80), T("07:05", 10, 300, h=14), T("mg/dL", 200, 300, h=14)])
        self.assertEqual(r.values, {"glucose": 118, "unit": "mg/dL"})
        self.assertEqual(r.flagged, set())

    def test_mmol(self):
        r = parse_glucose([T("6.5", 100, 100, h=80), T("mmol/L", 200, 300, h=14)])
        self.assertEqual(r.values, {"glucose": 6.5, "unit": "mmol/L"})

    def test_unit_noise_is_still_recognised(self):
        r = parse_glucose([T("118", 100, 100, h=80), T("mg/d1", 200, 300, h=14)])
        self.assertEqual(r.values["unit"], "mg/dL")

    def test_unit_missing_is_guessed_and_flagged(self):
        r = parse_glucose([T("118", 100, 100, h=80)])
        self.assertEqual(r.values["unit"], "mg/dL")
        self.assertEqual(r.flagged, {"unit"})

    def test_lost_decimal_point_falls_back(self):
        r = parse_glucose([T("65", 100, 100, h=80), T("mmol/L", 200, 300, h=14)])  # 6.5 read as 65
        self.assertTrue(r.fallback)

    def test_two_equally_big_numbers_are_flagged(self):
        r = parse_glucose([T("118", 100, 100, h=80), T("120", 100, 250, h=78), T("mg/dL", 200, 400, h=14)])
        self.assertIn("glucose", r.flagged)

    def test_no_number(self):
        self.assertTrue(parse_glucose([T("GLU", 10, 10, h=14)]).fallback)


if __name__ == "__main__":
    unittest.main()
