import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ehealth_mobile/app.dart';
import 'package:ehealth_mobile/data/models.dart';
import 'package:ehealth_mobile/state/app_state.dart';

void main() {
  testWidgets('Home opens in Khmer with the record button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // Galaxy S22+
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final state = AppState();
    await tester.pumpWidget(EHealthApp(state: state));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('កត់ត្រាការវាស់ព្រឹកនេះ'), findsOneWidget);

    state.setLang(AppLang.en);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Record morning reading'), findsOneWidget);

    // Remove the tree so the invite-code countdown timer is cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('Glucose hard limits follow FR-06', () {
    expect(Fields.glu.inHardLimits(19), isFalse);
    expect(Fields.glu.inHardLimits(600), isTrue);
    expect(Fields.sys.inHardLimits(728), isFalse);
    expect(Fields.sys.status(138), RangeStatus.high);
  });
}
