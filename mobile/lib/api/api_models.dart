// Typed API models (DTOs) matching docs/api/reports.yaml and packages/types/src/reports.ts.
// Owner: Rith (shared/platform + reports).

import '../data/types.dart';

class AuthUserDto {
  const AuthUserDto({required this.id, required this.role, required this.name});

  final String id;
  final Role role;
  final String name;

  factory AuthUserDto.fromJson(Map<String, dynamic> json) => AuthUserDto(
        id: json['id'] as String,
        role: Role.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => Role.patient,
        ),
        name: json['name'] as String,
      );
}

class DevLoginResult {
  const DevLoginResult({required this.token, required this.user});

  final String token;
  final AuthUserDto user;

  factory DevLoginResult.fromJson(Map<String, dynamic> json) => DevLoginResult(
        token: json['token'] as String,
        user: AuthUserDto.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class FieldSummaryDto {
  const FieldSummaryDto({
    required this.fieldKey,
    required this.min,
    required this.max,
    required this.avg,
    required this.count,
    this.latestValue,
    this.latestMeasuredAt,
  });

  final String fieldKey;
  final double min;
  final double max;
  final double avg;
  final int count;
  final double? latestValue;
  final DateTime? latestMeasuredAt;

  factory FieldSummaryDto.fromJson(Map<String, dynamic> json) {
    final latest = json['latest'] as Map<String, dynamic>?;
    return FieldSummaryDto(
      fieldKey: json['fieldKey'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      avg: (json['avg'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
      latestValue: (latest?['value'] as num?)?.toDouble(),
      latestMeasuredAt: latest?['measuredAt'] == null ? null : DateTime.parse(latest!['measuredAt'] as String),
    );
  }
}

class PatientSummaryDto {
  const PatientSummaryDto({
    required this.patientId,
    required this.from,
    required this.to,
    required this.fields,
    required this.missedDays,
    required this.outOfRangeCount,
  });

  final String patientId;
  final String from;
  final String to;
  final List<FieldSummaryDto> fields;
  final int missedDays;
  final int outOfRangeCount;

  factory PatientSummaryDto.fromJson(Map<String, dynamic> json) => PatientSummaryDto(
        patientId: json['patientId'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        fields: [
          for (final item in (json['fields'] as List<dynamic>? ?? const []))
            FieldSummaryDto.fromJson(item as Map<String, dynamic>),
        ],
        missedDays: (json['missedDays'] as num).toInt(),
        outOfRangeCount: (json['outOfRangeCount'] as num).toInt(),
      );
}

class SeriesPointDto {
  const SeriesPointDto({required this.measuredAt, required this.value});

  final DateTime measuredAt;
  final double value;

  factory SeriesPointDto.fromJson(Map<String, dynamic> json) => SeriesPointDto(
        measuredAt: DateTime.parse(json['measuredAt'] as String),
        value: (json['value'] as num).toDouble(),
      );
}

class PatientSeriesDto {
  const PatientSeriesDto({
    required this.patientId,
    required this.fieldKey,
    required this.from,
    required this.to,
    required this.points,
  });

  final String patientId;
  final String fieldKey;
  final String from;
  final String to;
  final List<SeriesPointDto> points;

  factory PatientSeriesDto.fromJson(Map<String, dynamic> json) => PatientSeriesDto(
        patientId: json['patientId'] as String,
        fieldKey: json['fieldKey'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        points: [
          for (final item in (json['points'] as List<dynamic>? ?? const []))
            SeriesPointDto.fromJson(item as Map<String, dynamic>),
        ],
      );
}

class LivePatientReport {
  const LivePatientReport({required this.summary, required this.series});

  final PatientSummaryDto summary;
  final Map<String, PatientSeriesDto> series;
}
