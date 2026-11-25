// Merged Khmer strings (default language).
// Edit strings in your module file under `lib/l10n/modules/` instead of here.

import 'modules/accounts.dart';
import 'modules/ocr.dart';
import 'modules/readings.dart';
import 'modules/reports.dart';
import 'modules/shared.dart';

const Map<String, String> km = {
  ...sharedKm,
  ...accountsKm,
  ...readingsKm,
  ...ocrKm,
  ...reportsKm,
};
