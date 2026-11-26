"""End to end on the three demo photos in mobile/assets/images (needs the tesseract CLI)."""

import shutil
import unittest
from pathlib import Path

from ocrbench.engines import tesseract_tokens
from ocrbench.parse import parse

IMAGES = Path(__file__).resolve().parents[3] / "mobile" / "assets" / "images"


@unittest.skipUnless(shutil.which("tesseract") and IMAGES.exists(), "tesseract or demo images not available")
class DemoImages(unittest.TestCase):
    def read(self, device, name):
        return parse(device, tesseract_tokens(IMAGES / name))

    def test_clear_bp_photo(self):
        r = self.read("bp", "demo-bp.png")
        self.assertEqual(r.values, {"systolic": 132, "diastolic": 84, "pulse": 72})
        self.assertFalse(r.fallback)

    def test_clear_glucose_photo(self):
        r = self.read("glucose", "demo-glucose.png")
        self.assertEqual(r.values, {"glucose": 118, "unit": "mg/dL"})

    def test_blurry_bp_photo_goes_to_manual_entry(self):
        # Tesseract reads 132 as 432 here. It must never be pre-filled as if it were right.
        r = self.read("bp", "demo-bp-blurry.png")
        self.assertTrue(r.fallback)
        self.assertNotIn("systolic", r.values)


if __name__ == "__main__":
    unittest.main()
