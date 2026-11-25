// FR-06. Safe input limits reject impossible values (typos).
// Normal ranges only FLAG a value; they never block saving.
//
// NOTE: the normal ranges below are DEMO values for adult morning (fasting)
// readings. Open question in the spec: which reference to cite (WHO /
// Cambodian MoH) and whether a doctor can adjust per patient. Change them here
// only; every screen reads from this file.

import 'types.dart';

class MeasureDef {
  const MeasureDef(this.unit, this.safeMin, this.safeMax, this.normalMin, this.normalMax);
  final String unit;
  final double safeMin;
  final double safeMax;
  final double normalMin;
  final double normalMax;
}

const measures = <MeasureKey, MeasureDef>{
  MeasureKey.systolic: MeasureDef('mmHg', 50, 260, 90, 129),
  MeasureKey.diastolic: MeasureDef('mmHg', 30, 160, 60, 84),
  MeasureKey.pulse: MeasureDef('bpm', 30, 220, 60, 100),
  MeasureKey.glucose: MeasureDef('mg/dL', 20, 600, 70, 130),
};

const measureOrder = MeasureKey.values;

/// mg/dL = mmol/L × 18
const mmolFactor = 18.0;

enum Level { normal, high, low }

Level? levelOf(MeasureKey k, double? v) {
  if (v == null) return null;
  final m = measures[k]!;
  if (v > m.normalMax) return Level.high;
  if (v < m.normalMin) return Level.low;
  return Level.normal;
}

/// Worst level across a reading: high > low > normal.
Level readingLevel(Reading r) {
  var worst = Level.normal;
  for (final k in measureOrder) {
    final l = levelOf(k, r.valueOf(k));
    if (l == Level.high) return Level.high;
    if (l == Level.low) worst = Level.low;
  }
  return worst;
}

bool isOutOfRange(Reading r) => readingLevel(r) != Level.normal;
