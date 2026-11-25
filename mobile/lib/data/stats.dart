import 'dart:math' as math;

import 'dates.dart';
import 'ranges.dart';
import 'types.dart';

class DayRange {
  const DayRange(this.from, this.to, this.days);

  /// Start of the first day.
  final DateTime from;

  /// End of the last day.
  final DateTime to;
  final int days;
}

DayRange lastNDays(int n, [DateTime? now]) {
  final today = startOfDay(now ?? DateTime.now());
  final to = DateTime(today.year, today.month, today.day + 1).subtract(const Duration(milliseconds: 1));
  return DayRange(DateTime(today.year, today.month, today.day - (n - 1)), to, n);
}

DayRange customRange(DateTime a, DateTime b) {
  final from = startOfDay(a.isBefore(b) ? a : b);
  final last = startOfDay(a.isBefore(b) ? b : a);
  final to = DateTime(last.year, last.month, last.day + 1).subtract(const Duration(milliseconds: 1));
  return DayRange(from, to, (last.difference(from).inHours / 24).round() + 1);
}

List<Reading> inRange(List<Reading> readings, DayRange r) =>
    readings.where((x) => !x.takenAt.isBefore(r.from) && !x.takenAt.isAfter(r.to)).toList();

class Stat {
  const Stat({this.min, this.max, this.avg, this.count = 0});
  final double? min;
  final double? max;
  final double? avg;
  final int count;
}

/// FR-10. Readings without the measure are ignored (not counted as 0).
Stat statOf(List<Reading> readings, double? Function(Reading) get) {
  final vals = [for (final r in readings) get(r)].whereType<double>().where((v) => !v.isNaN).toList();
  if (vals.isEmpty) return const Stat();
  final sum = vals.fold<double>(0, (a, b) => a + b);
  return Stat(min: vals.reduce(math.min), max: vals.reduce(math.max), avg: sum / vals.length, count: vals.length);
}

int daysWithReadings(List<Reading> readings) => {for (final r in readings) dayKey(r.takenAt)}.length;

/// Days in the last n days (not counting today) without any reading.
int missedDays(List<Reading> readings, [int n = 7, DateTime? now]) {
  final keys = {for (final r in readings) dayKey(r.takenAt)};
  final today = now ?? DateTime.now();
  var missed = 0;
  for (var i = 1; i <= n; i++) {
    if (!keys.contains(dayKey(addDays(today, -i)))) missed++;
  }
  return missed;
}

class PatientSummary {
  const PatientSummary({
    this.latest,
    this.avgSystolic,
    this.avgDiastolic,
    this.avgGlucose,
    required this.outOfRange7,
    required this.missed7,
    this.latestLevel,
    required this.attentionScore,
  });

  final Reading? latest;
  final double? avgSystolic;
  final double? avgDiastolic;
  final double? avgGlucose;
  final int outOfRange7;
  final int missed7;
  final Level? latestLevel;
  final int attentionScore;
}

/// What GET /patients/{id}/summary will return (FR-12).
PatientSummary summarize(List<Reading> readingsNewestFirst, [DateTime? now]) {
  final week = inRange(readingsNewestFirst, lastNDays(7, now));
  final latest = readingsNewestFirst.isEmpty ? null : readingsNewestFirst.first;
  final outOfRange7 = week.where(isOutOfRange).length;
  final missed7 = missedDays(readingsNewestFirst, 7, now);
  final latestLevel = latest == null ? null : readingLevel(latest);
  final latestFlagged = latestLevel != null && latestLevel != Level.normal;
  // Needs attention: latest reading out of range, 3+ out-of-range readings this week, or 2+ missed days
  final flagged = latestFlagged || outOfRange7 >= 3 || missed7 >= 2;
  final score = flagged ? (latestFlagged ? 100 : 0) + outOfRange7 * 10 + missed7 * 8 + 1 : 0;
  return PatientSummary(
    latest: latest,
    avgSystolic: statOf(week, (r) => r.systolic).avg,
    avgDiastolic: statOf(week, (r) => r.diastolic).avg,
    avgGlucose: statOf(week, (r) => r.glucose).avg,
    outOfRange7: outOfRange7,
    missed7: missed7,
    latestLevel: latestLevel,
    attentionScore: score,
  );
}
