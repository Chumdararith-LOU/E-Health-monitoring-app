// Shared HTTP API client for the mobile app (Owner: Rith).
// Uses Dart's built-in dart:io HttpClient so zero extra packages are required.
// Teammates can call `api.requestJson(...)` to wire their own endpoints.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../data/types.dart';
import 'api_models.dart';

/// Raw HTTP response returned by [ApiTransport].
class ApiHttpResponse {
  const ApiHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// Injectable transport function so tests can fake HTTP without touching the network.
typedef ApiTransport = Future<ApiHttpResponse> Function(
  String method,
  Uri uri,
  Map<String, String> headers,
  String? body,
);

/// Structured API error matching `{ error: { code, messageKey } }` from the backend.
class ApiClientException implements Exception {
  const ApiClientException({
    required this.status,
    required this.code,
    required this.messageKey,
  });

  final int status;
  final String code;
  final String messageKey;

  @override
  String toString() => 'ApiClientException($status, $code, $messageKey)';
}

/// Default API base URL.
/// Override when running on a physical phone on Wi-Fi:
///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1`
String defaultApiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) {
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }
  // On Android emulators, 10.0.2.2 routes to the host computer's localhost.
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000/api/v1';
  }
  return 'http://localhost:3000/api/v1';
}

Future<ApiHttpResponse> _dartIoTransport(
  String method,
  Uri uri,
  Map<String, String> headers,
  String? body,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final req = await client.openUrl(method, uri).timeout(const Duration(seconds: 8));
    headers.forEach(req.headers.set);
    if (body != null) {
      req.add(utf8.encode(body));
    }
    final res = await req.close().timeout(const Duration(seconds: 8));
    final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
    return ApiHttpResponse(statusCode: res.statusCode, body: text);
  } finally {
    client.close(force: true);
  }
}

class ApiClient {
  ApiClient({String? baseUrl, ApiTransport? transport})
      : baseUrl = (baseUrl ?? defaultApiBaseUrl()).replaceFirst(RegExp(r'/+$'), ''),
        _transport = transport ?? _dartIoTransport;

  final String baseUrl;
  final ApiTransport _transport;

  /// Sends a JSON HTTP request and parses the JSON object response.
  /// Throws [ApiClientException] with the backend's `messageKey` on failure.
  Future<Map<String, dynamic>> requestJson(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
      encodedBody = jsonEncode(body);
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    ApiHttpResponse res;
    try {
      res = await _transport(method, uri, headers, encodedBody);
    } on ApiClientException {
      rethrow;
    } catch (_) {
      throw const ApiClientException(
        status: 0,
        code: 'network_error',
        messageKey: 'errors.network',
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      var code = 'http_error';
      var messageKey = 'errors.internal_error';
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final err = decoded['error'];
          if (err is Map<String, dynamic>) {
            code = (err['code'] as String?) ?? code;
            messageKey = (err['messageKey'] as String?) ?? messageKey;
          }
        }
      } catch (_) {
        // non-JSON error body → fall back to generic messageKey
      }
      throw ApiClientException(status: res.statusCode, code: code, messageKey: messageKey);
    }

    if (res.statusCode == 204 || res.body.trim().isEmpty) {
      return const {};
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Dev-only login (`POST /dev/login`) returning a signed JWT for the chosen role.
  Future<DevLoginResult> devLogin(Role role) async {
    final json = await requestJson('POST', '/dev/login', body: {'role': role.name});
    return DevLoginResult.fromJson(json);
  }

  /// `GET /patients/:patientId/summary?days=...` (or `?from=YYYY-MM-DD&to=YYYY-MM-DD`)
  Future<PatientSummaryDto> getPatientSummary(
    String patientId, {
    required int days,
    required String token,
    String? from,
    String? to,
  }) async {
    final encodedId = Uri.encodeComponent(patientId);
    final query = from != null && to != null
        ? 'from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}'
        : 'days=$days';
    final json = await requestJson('GET', '/patients/$encodedId/summary?$query', token: token);
    return PatientSummaryDto.fromJson(json);
  }

  /// `GET /patients/:patientId/series?field=...&days=...` (or `&from=...&to=...`)
  Future<PatientSeriesDto> getPatientSeries(
    String patientId, {
    required String field,
    required int days,
    required String token,
    String? from,
    String? to,
  }) async {
    final encodedId = Uri.encodeComponent(patientId);
    final encodedField = Uri.encodeQueryComponent(field);
    final rangeQuery = from != null && to != null
        ? 'from=${Uri.encodeQueryComponent(from)}&to=${Uri.encodeQueryComponent(to)}'
        : 'days=$days';
    final json = await requestJson(
      'GET',
      '/patients/$encodedId/series?field=$encodedField&$rangeQuery',
      token: token,
    );
    return PatientSeriesDto.fromJson(json);
  }

  /// Fetches summary and all requested field series in parallel.
  Future<LivePatientReport> getPatientReport(
    String patientId, {
    required List<String> fieldKeys,
    required int days,
    required String token,
    String? from,
    String? to,
  }) async {
    final uniqueFields = fieldKeys.toSet().toList();
    final summaryFuture = getPatientSummary(patientId, days: days, token: token, from: from, to: to);
    final seriesFutures = [
      for (final f in uniqueFields)
        getPatientSeries(patientId, field: f, days: days, token: token, from: from, to: to),
    ];

    final summary = await summaryFuture;
    final seriesList = await Future.wait(seriesFutures);
    return LivePatientReport(
      summary: summary,
      series: {for (final s in seriesList) s.fieldKey: s},
    );
  }

  /// `GET /fields` — returns active non-built-in custom fields for forms and reports.
  Future<List<CustomField>> listCustomFields({required String token}) async {
    final json = await requestJson('GET', '/fields', token: token);
    final raw = json['fields'] as List<dynamic>? ?? const [];
    return [
      for (final item in raw.cast<Map<String, dynamic>>())
        if (item['builtIn'] != true) customFieldFromApiJson(item),
    ];
  }

  /// `GET /patients/:patientId/readings`
  Future<List<Reading>> listPatientReadings(
    String patientId, {
    required String token,
    int limit = 200,
  }) async {
    final encodedId = Uri.encodeComponent(patientId);
    final json = await requestJson('GET', '/patients/$encodedId/readings?limit=$limit', token: token);
    final raw = json['readings'] as List<dynamic>? ?? const [];
    return [for (final item in raw.cast<Map<String, dynamic>>()) readingFromApiJson(item)];
  }

  /// `POST /patients/:patientId/readings`
  Future<Reading> createReading(Reading reading, {required String token}) async {
    final encodedId = Uri.encodeComponent(reading.patientId);
    final json = await requestJson(
      'POST',
      '/patients/$encodedId/readings',
      token: token,
      body: {
        'measuredAt': reading.takenAt.toUtc().toIso8601String(),
        'method': reading.method.name,
        'note': reading.note,
        'photoUri': reading.photoUri,
        'values': readingToValues(reading),
      },
    );
    return readingFromApiJson(json);
  }

  /// `PUT /patients/:patientId/readings/:readingId`
  Future<Reading> updateReading(Reading reading, {required String token}) async {
    final encodedPid = Uri.encodeComponent(reading.patientId);
    final encodedRid = Uri.encodeComponent(reading.id);
    final json = await requestJson(
      'PUT',
      '/patients/$encodedPid/readings/$encodedRid',
      token: token,
      body: {
        'measuredAt': reading.takenAt.toUtc().toIso8601String(),
        'note': reading.note,
        'values': readingToValues(reading),
      },
    );
    return readingFromApiJson(json);
  }

  /// `DELETE /patients/:patientId/readings/:readingId`
  Future<void> deleteReading(String patientId, String readingId, {required String token}) async {
    final encodedPid = Uri.encodeComponent(patientId);
    final encodedRid = Uri.encodeComponent(readingId);
    await requestJson('DELETE', '/patients/$encodedPid/readings/$encodedRid', token: token);
  }
}

/// Converts a mobile [Reading] into the API `values` map (`{ systolic, diastolic, ... }`).
Map<String, double> readingToValues(Reading r) => {
      if (r.systolic != null) 'systolic': r.systolic!,
      if (r.diastolic != null) 'diastolic': r.diastolic!,
      if (r.pulse != null) 'pulse': r.pulse!,
      if (r.glucose != null) 'glucose': r.glucose!,
      ...r.extra,
    };

/// Parses a `ReadingDto` JSON object from the API into a mobile [Reading].
Reading readingFromApiJson(Map<String, dynamic> j) {
  final rawVals = (j['values'] as Map<String, dynamic>? ?? const {});
  double? val(String k) => (rawVals[k] as num?)?.toDouble();
  final extra = <String, double>{
    for (final e in rawVals.entries)
      if (e.key != 'systolic' && e.key != 'diastolic' && e.key != 'pulse' && e.key != 'glucose')
        e.key: (e.value as num).toDouble(),
  };
  return Reading(
    id: j['id'] as String,
    patientId: j['patientId'] as String,
    takenAt: DateTime.parse(j['measuredAt'] as String).toLocal(),
    systolic: val('systolic'),
    diastolic: val('diastolic'),
    pulse: val('pulse'),
    glucose: val('glucose'),
    extra: extra,
    enteredBy: j['enteredBy'] as String,
    method: EntryMethod.values.firstWhere((m) => m.name == j['method'], orElse: () => EntryMethod.manual),
    note: j['note'] as String?,
    photoUri: j['photoUri'] as String?,
    updatedAt: j['updatedAt'] == null ? null : DateTime.parse(j['updatedAt'] as String).toLocal(),
  );
}

/// Parses a `CustomFieldDto` JSON object from the API into a mobile [CustomField].
CustomField customFieldFromApiJson(Map<String, dynamic> j) => CustomField(
      id: j['id'] as String,
      nameEn: j['nameEn'] as String,
      nameKm: j['nameKm'] as String,
      unit: j['unit'] as String,
      decimals: (j['decimals'] as num).toInt(),
      min: (j['minValue'] as num).toDouble(),
      max: (j['maxValue'] as num).toDouble(),
    );
