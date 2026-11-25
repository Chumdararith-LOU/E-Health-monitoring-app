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
}
