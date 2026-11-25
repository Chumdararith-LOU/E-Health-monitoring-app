import 'package:ehealth_mobile/app.dart';
import 'package:ehealth_mobile/data/ranges.dart';
import 'package:ehealth_mobile/data/seed.dart';
import 'package:ehealth_mobile/data/stats.dart';
import 'package:ehealth_mobile/data/types.dart';
import 'package:ehealth_mobile/l10n/en.dart';
import 'package:ehealth_mobile/l10n/km.dart';
import 'package:ehealth_mobile/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Khmer and English have the same string keys', () {
    expect(km.keys.toSet(), en.keys.toSet());
  });

  test('seed random numbers match the JavaScript prototype', () {
    final r = seedRandom(1000);
    final got = [for (var i = 0; i < 5; i++) r().toStringAsFixed(12)];
    expect(got, ['0.795194906881', '0.827687913552', '0.691516105784', '0.880575214280', '0.017807392636']);
  });

  test('demo data matches the demo story', () {
    final now = DateTime(2026, 11, 25, 9);
    final data = makeSeed(now);
    List<Reading> of(String id) => data.readings.where((r) => r.patientId == id).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    // p1 has not recorded today, p3 missed the last 3 days, p4 is flagged for the doctor
    expect(of('p1').first.takenAt.day, isNot(25));
    expect(missedDays(of('p3'), 7, now), greaterThanOrEqualTo(2));
    expect(summarize(of('p4'), now).attentionScore, greaterThan(0));
    expect(makeSeed(now).readings.length, data.readings.length);
  });

  test('levels follow the normal ranges', () {
    expect(levelOf(MeasureKey.systolic, 134), Level.high);
    expect(levelOf(MeasureKey.glucose, 65), Level.low);
    expect(levelOf(MeasureKey.pulse, 72), Level.normal);
  });

  testWidgets('sign in as the demo patient and see today\'s status', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final state = AppState(persist: false);
    await state.load();
    await tester.pumpWidget(EHealthApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('ចូលគណនី'), findsWidgets);
    state.setSettings(state.settings.copyWith(lang: Lang.en));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Patient'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Patient'));
    await tester.pumpAndSettle();
    expect(find.text('Not recorded yet today'), findsOneWidget);
    expect(find.text('Record now'), findsOneWidget);

    await tester.tap(find.text('Record now'));
    await tester.pumpAndSettle();
    expect(find.text('How do you want to record?'), findsOneWidget);
  });
}
