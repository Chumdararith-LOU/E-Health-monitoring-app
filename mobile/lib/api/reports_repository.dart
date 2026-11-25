// Repository pattern + pure adapters for patient reports (Owner: Rith).
// Screens talk to ReportsRepository rather than raw HTTP calls, making it easy
// to swap between live API data and fake test data.

import '../data/stats.dart';
import '../widgets/charts.dart';
import 'api_client.dart';
import 'api_models.dart';

abstract class ReportsRepository {
  Future<LivePatientReport> fetchPatientReport(
    String patientId, {
    required List<String> fieldKeys,
    required int days,
    required String token,
  });
}

class ApiReportsRepository implements ReportsRepository {
  const ApiReportsRepository(this.api);

  final ApiClient api;

  @override
  Future<LivePatientReport> fetchPatientReport(
    String patientId, {
    required List<String> fieldKeys,
    required int days,
    required String token,
  }) {
    return api.getPatientReport(patientId, fieldKeys: fieldKeys, days: days, token: token);
  }
}

class FakeReportsRepository implements ReportsRepository {
  const FakeReportsRepository(this.handler);

  final Future<LivePatientReport> Function(
    String patientId,
    List<String> fieldKeys,
    int days,
    String token,
  ) handler;

  @override
  Future<LivePatientReport> fetchPatientReport(
    String patientId, {
    required List<String> fieldKeys,
    required int days,
    required String token,
  }) =>
      handler(patientId, fieldKeys, days, token);
}

/// Converts API series points into LineChart points sorted ascending by time.
/// Uses the ISO timestamp as the point ID so systolic & diastolic from the same
/// reading stay paired in the chart tooltip and table view.
List<ChartPoint> seriesToChartPoints(PatientSeriesDto series) {
  final seen = <String, int>{};
  final out = <ChartPoint>[];
  for (final pt in series.points) {
    final iso = pt.measuredAt.toIso8601String();
    final count = seen[iso] ?? 0;
    seen[iso] = count + 1;
    final id = count == 0 ? iso : '$iso#$count';
    out.add(ChartPoint(pt.measuredAt, pt.value, id));
  }
  out.sort((a, b) => a.t.compareTo(b.t));
  return out;
}

/// Picks live API series points when available, falling back to local demo data
/// while the readings module returns empty readings.
List<ChartPoint> pickChartPoints(
  Map<String, PatientSeriesDto>? liveSeries,
  String fieldKey,
  List<ChartPoint> fallback,
) {
  final live = liveSeries?[fieldKey];
  if (live == null || live.points.isEmpty) return fallback;
  return seriesToChartPoints(live);
}

/// Picks live summary stats for a field when available, falling back to demo stats.
Stat pickFieldStat(PatientSummaryDto? summary, String fieldKey, Stat fallback) {
  if (summary == null || summary.fields.isEmpty) return fallback;
  for (final f in summary.fields) {
    if (f.fieldKey == fieldKey) {
      return Stat(min: f.min, max: f.max, avg: f.avg, count: f.count);
    }
  }
  return fallback;
}

/// True when at least one fetched series contains live readings from the API.
bool hasLiveSeriesData(Map<String, PatientSeriesDto>? liveSeries) {
  if (liveSeries == null) return false;
  return liveSeries.values.any((s) => s.points.isNotEmpty);
}
