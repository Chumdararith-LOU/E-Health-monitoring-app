// Merged English strings.
// Edit strings in your module file under `lib/l10n/modules/` instead of here.

import 'modules/accounts.dart';
import 'modules/ocr.dart';
import 'modules/readings.dart';
import 'modules/reports.dart';
import 'modules/shared.dart';

const Map<String, String> en = {
  ...sharedEn,
  ...accountsEn,
  ...readingsEn,
  ...ocrEn,
  ...reportsEn,
};
