import 'dart:convert';

import 'package:ehealth_mobile/api/api_client.dart';
import 'package:ehealth_mobile/api/api_models.dart';
import 'package:ehealth_mobile/api/reports_repository.dart';
import 'package:ehealth_mobile/app.dart';
import 'package:ehealth_mobile/data/stats.dart';
import 'package:ehealth_mobile/data/types.dart';
import 'package:ehealth_mobile/l10n/strings.dart';
import 'package:ehealth_mobile/state/app_state.dart';
import 'package:ehealth_mobile/widgets/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiClient.devLogin sends role and parses JWT + user', () async {
    late String seenMethod;
    late Uri seenUri;
    late String? seenBody;

    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1/',
      transport: (method, uri, headers, body) async {
        seenMethod = method;
        seenUri = uri;
        seenBody = body;
        return ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'token': 'jwt-123',
            'user': {'id': 'u-doc', 'role': 'doctor', 'name': 'Dr. Keo'},
          }),
        );
      },
    );

    final res = await api.devLogin(Role.doctor);
    expect(seenMethod, 'POST');
    expect(seenUri.toString(), 'http://example.test/api/v1/dev/login');
    expect(jsonDecode(seenBody!), {'role': 'doctor'});
    expect(res.token, 'jwt-123');
    expect(res.user.role, Role.doctor);
  });

  test('ApiClient.getPatientReport fetches summary and unique series with Bearer token', () async {
    final calls = <Uri>[];
    final authHeaders = <String?>[];

    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (method, uri, headers, body) async {
        calls.add(uri);
        authHeaders.add(headers['Authorization']);
        if (uri.path.endsWith('/summary')) {
          return ApiHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'patientId': 'p1',
              'from': '2026-11-01',
              'to': '2026-11-25',
              'fields': [
                {'fieldKey': 'systolic', 'min': 118, 'max': 134, 'avg': 126, 'count': 10},
              ],
              'missedDays': 2,
              'outOfRangeCount': 1,
            }),
          );
        }
        final field = uri.queryParameters['field'] ?? 'unknown';
        return ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'patientId': 'p1',
            'fieldKey': field,
            'from': '2026-11-01',
            'to': '2026-11-25',
            'points': [
              {'measuredAt': '2026-11-24T06:30:00.000Z', 'value': 128},
            ],
          }),
        );
      },
    );

    final report = await api.getPatientReport(
      'p1',
      fieldKeys: const ['systolic', 'diastolic', 'systolic'],
      days: 30,
      token: 'tok-abc',
    );

    expect(calls.length, 3); // 1 summary + 2 unique series
    expect(authHeaders.every((h) => h == 'Bearer tok-abc'), isTrue);
    expect(report.summary.missedDays, 2);
    expect(report.summary.fields.single.avg, 126);
    expect(report.series.keys.toSet(), {'systolic', 'diastolic'});
    expect(report.series['systolic']!.points.single.value, 128);
  });

  test('ApiClient maps backend ApiError and network failures into ApiClientException', () async {
    final forbiddenApi = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (_, __, ___, ____) async => ApiHttpResponse(
        statusCode: 403,
        body: jsonEncode({
          'error': {'code': 'forbidden', 'messageKey': 'errors.forbidden'},
        }),
      ),
    );

    await expectLater(
      forbiddenApi.getPatientSummary('p2', days: 7, token: 't'),
      throwsA(
        isA<ApiClientException>()
            .having((e) => e.status, 'status', 403)
            .having((e) => e.messageKey, 'messageKey', 'errors.forbidden'),
      ),
    );

    final offlineApi = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (_, __, ___, ____) async => throw Exception('socket closed'),
    );

    await expectLater(
      offlineApi.devLogin(Role.patient),
      throwsA(
        isA<ApiClientException>()
            .having((e) => e.status, 'status', 0)
            .having((e) => e.messageKey, 'messageKey', 'errors.network'),
      ),
    );
  });

  test('seriesToChartPoints sorts ascending and aligns systolic/diastolic IDs by timestamp', () {
    final t1 = DateTime.parse('2026-11-20T06:15:00.000Z');
    final t2 = DateTime.parse('2026-11-22T06:30:00.000Z');
    final sys = seriesToChartPoints(PatientSeriesDto(
      patientId: 'p1',
      fieldKey: 'systolic',
      from: '2026-11-01',
      to: '2026-11-25',
      points: [SeriesPointDto(measuredAt: t2, value: 132), SeriesPointDto(measuredAt: t1, value: 124)],
    ));
    final dia = seriesToChartPoints(PatientSeriesDto(
      patientId: 'p1',
      fieldKey: 'diastolic',
      from: '2026-11-01',
      to: '2026-11-25',
      points: [SeriesPointDto(measuredAt: t1, value: 80)],
    ));

    expect(sys.map((p) => p.v).toList(), [124, 132]);
    expect(sys.first.id, dia.first.id);
    expect(sys.first.t, dia.first.t);
  });

  test('pickChartPoints and pickFieldStat prefer live data and fall back when empty', () {
    final demoPt = [ChartPoint(DateTime(2026, 11, 20), 120, 'demo-1')];
    const demoStat = Stat(min: 110, max: 130, avg: 120, count: 5);

    expect(pickChartPoints(null, 'systolic', demoPt), same(demoPt));
    expect(pickFieldStat(null, 'systolic', demoStat), same(demoStat));
    expect(hasLiveSeriesData(null), isFalse);

    final liveSeries = {
      'systolic': PatientSeriesDto(
        patientId: 'p1',
        fieldKey: 'systolic',
        from: '2026-11-01',
        to: '2026-11-25',
        points: [SeriesPointDto(measuredAt: DateTime.parse('2026-11-25T06:30:00.000Z'), value: 136)],
      ),
    };
    final liveSummary = const PatientSummaryDto(
      patientId: 'p1',
      from: '2026-11-01',
      to: '2026-11-25',
      fields: [FieldSummaryDto(fieldKey: 'systolic', min: 120, max: 136, avg: 128, count: 2)],
      missedDays: 5,
      outOfRangeCount: 1,
    );

    expect(hasLiveSeriesData(liveSeries), isTrue);
    expect(pickChartPoints(liveSeries, 'systolic', demoPt).single.v, 136);
    expect(pickFieldStat(liveSummary, 'systolic', demoStat).avg, 128);
  });

  test('AppState.signIn fetches dev token asynchronously and signOut clears it', () async {
    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (_, __, ___, ____) async => ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode({
          'token': 'dev-jwt-patient',
          'user': {'id': 'u-1', 'role': 'patient', 'name': 'Sok Dara'},
        }),
      ),
    );
    final st = AppState(persist: false, api: api);
    st.signIn('p1');
    await Future<void>.delayed(Duration.zero);

    expect(st.token, 'dev-jwt-patient');
    st.signOut();
    expect(st.token, isNull);
  });

  test('API error translations have identical Khmer and English keys', () {
    expect(apiErrorsKm.keys.toSet(), apiErrorsEn.keys.toSet());
    final kmI18n = I18n(Lang.km, Numerals.western);
    final enI18n = I18n(Lang.en, Numerals.western);
    expect(kmI18n.apiError('errors.forbidden'), apiErrorsKm['errors.forbidden']);
    expect(enI18n.apiError('errors.unknown_xyz'), apiErrorsEn['errors.internal_error']);
  });

  test('ApiClient sends from/to query params when custom range is provided', () async {
    final uris = <Uri>[];
    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (_, uri, __, ___) async {
        uris.add(uri);
        if (uri.path.endsWith('/summary')) {
          return ApiHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'patientId': 'p1',
              'from': '2026-11-10',
              'to': '2026-11-20',
              'fields': [],
              'missedDays': 11,
              'outOfRangeCount': 0,
            }),
          );
        }
        return ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'patientId': 'p1',
            'fieldKey': 'systolic',
            'from': '2026-11-10',
            'to': '2026-11-20',
            'points': [],
          }),
        );
      },
    );

    await api.getPatientReport(
      'p1',
      fieldKeys: const ['systolic'],
      days: 11,
      token: 'tok',
      from: '2026-11-10',
      to: '2026-11-20',
    );

    expect(uris[0].queryParameters, {'from': '2026-11-10', 'to': '2026-11-20'});
    expect(uris[1].queryParameters, {'field': 'systolic', 'from': '2026-11-10', 'to': '2026-11-20'});
  });

  testWidgets('US-14 patient home displays live API 7-day averages from ReportsRepository', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final fakeRepo = FakeReportsRepository((patientId, fieldKeys, days, token, {from, to}) async {
      return LivePatientReport(
        summary: PatientSummaryDto(
          patientId: patientId,
          from: '2026-11-19',
          to: '2026-11-25',
          fields: const [
            FieldSummaryDto(fieldKey: 'systolic', min: 141, max: 141, avg: 141, count: 3),
            FieldSummaryDto(fieldKey: 'diastolic', min: 89, max: 89, avg: 89, count: 3),
            FieldSummaryDto(fieldKey: 'glucose', min: 123, max: 123, avg: 123, count: 3),
          ],
          missedDays: 4,
          outOfRangeCount: 3,
        ),
        series: const {},
      );
    });

    final state = AppState(persist: false, enableLiveApi: false, reportsRepo: fakeRepo);
    await state.load();
    state.setSettings(state.settings.copyWith(lang: Lang.en));
    state.signIn('p1');
    state.token = 'live-test-token';

    await tester.pumpWidget(EHealthApp(state: state));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.textContaining('141/89'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('141/89'), findsOneWidget);
    expect(find.textContaining('123'), findsWidgets);
  });

  testWidgets('US-13 family view is read-only and hides Record tab and button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final state = AppState(persist: false, enableLiveApi: false);
    await state.load();
    state.setSettings(state.settings.copyWith(lang: Lang.en));
    state.signIn('f1');

    await tester.pumpWidget(EHealthApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('View only'), findsOneWidget);
    expect(find.text('Record now'), findsNothing);
    expect(state.visibleTabs.contains(AppTab.record), isFalse);
  });

  test('AppState.saveReading and deleteReading sync CRUD calls to ApiClient and reconcile server ID', () async {
    final log = <String>[];
    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (method, uri, headers, body) async {
        log.add('$method ${uri.path}');
        if (method == 'POST' && uri.path.endsWith('/readings')) {
          return ApiHttpResponse(
            statusCode: 201,
            body: jsonEncode({
              'id': 'server-uuid-42',
              'patientId': 'p1',
              'enteredBy': 'p1',
              'measuredAt': '2026-11-25T00:30:00.000Z',
              'method': 'manual',
              'note': 'Saved live',
              'photoUri': null,
              'values': {'systolic': 122, 'diastolic': 78, 'glucose': 100},
              'createdAt': '2026-11-25T00:30:00.000Z',
              'updatedAt': null,
            }),
          );
        }
        if (method == 'DELETE') {
          return const ApiHttpResponse(statusCode: 204, body: '');
        }
        return ApiHttpResponse(statusCode: 200, body: jsonEncode({'fields': [], 'readings': []}));
      },
    );

    final st = AppState(persist: false, api: api);
    st.userId = 'p1';
    st.token = 'jwt-p1';

    final draft = Reading(
      id: 'local-temp-1',
      patientId: 'p1',
      takenAt: DateTime.parse('2026-11-25T00:30:00.000Z'),
      systolic: 122,
      diastolic: 78,
      glucose: 100,
      enteredBy: 'p1',
      method: EntryMethod.manual,
      note: 'Saved live',
    );

    st.saveReading(draft);
    await Future<void>.delayed(Duration.zero);

    expect(st.readingById('local-temp-1'), isNull);
    expect(st.readingById('server-uuid-42')?.systolic, 122);

    st.deleteReading('server-uuid-42');
    await Future<void>.delayed(Duration.zero);

    expect(log, [
      'POST /api/v1/patients/p1/readings',
      'DELETE /api/v1/patients/p1/readings/server-uuid-42',
    ]);
  });
}
