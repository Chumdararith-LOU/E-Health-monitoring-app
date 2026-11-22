// All visible text, Khmer first, English second (NFR-01: no hard-coded
// strings in screens). Khmer validation / OCR copy is taken word for word
// from claude/design-tokens-copy.md.
//
// Usage: final l = L.of(context); Text(l.recordCta)

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';

class L {
  const L({required this.km, required this.kmDigits});

  final bool km;
  final bool kmDigits;

  static L of(BuildContext context) {
    final s = AppScope.of(context);
    return L(km: s.lang == AppLang.km, kmDigits: s.khmerDigits);
  }

  String _t(String k, String e) => km ? k : e;

  // ---------- Numbers & dates (NFR-02) ----------

  static const _kd = <String>['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
  static const _kmMonths = <String>['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
  static const _enMonths = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// Shows digits as Khmer (១២៣) or Arabic (123), following Settings.
  /// Stored values are always plain numbers.
  String n(Object v) {
    final s = v.toString();
    if (!kmDigits) return s;
    final b = StringBuffer();
    for (final unit in s.codeUnits) {
      if (unit >= 48 && unit <= 57) {
        b.write(_kd[unit - 48]);
      } else {
        b.writeCharCode(unit);
      }
    }
    return b.toString();
  }

  static String _2(int v) => v.toString().padLeft(2, '0');

  String month(int m) => km ? _kmMonths[m - 1] : _enMonths[m - 1];
  String day(DateTime d) => n('${d.day} ${month(d.month)}');
  String dayY(DateTime d) => n('${d.day} ${month(d.month)} ${d.year}');
  String time(DateTime d) => n('${_2(d.hour)}:${_2(d.minute)}');
  String dayTime(DateTime d) => '${day(d)} · ${time(d)}';
  String tod(TimeOfDay t) => n('${_2(t.hour)}:${_2(t.minute)}');
  String numericDate(DateTime d) => n('${_2(d.day)}/${_2(d.month)}/${d.year}');
  String dayRange(DateTime a, DateTime b) {
    if (a.month == b.month && a.year == b.year) return n('${a.day}–${b.day} ${month(b.month)}');
    return '${day(a)} – ${day(b)}';
  }

  // ---------- Common ----------

  String get appName => 'E-Health';
  String get back => _t('ត្រឡប់', 'Back');
  String get cancel => _t('បោះបង់', 'Cancel');
  String get close => _t('បិទ', 'Close');
  String get ok => _t('យល់ព្រម', 'OK');
  String get languageGroup => _t('ភាសា', 'Language');

  // Tabs
  String get tabHome => _t('ទំព័រដើម', 'Home');
  String get tabRecord => _t('កត់ត្រា', 'Record');
  String get tabReports => _t('របាយការណ៍', 'Reports');
  String get tabLinks => _t('ការភ្ជាប់', 'Links');

  // Roles
  String get roleSelf => _t('ខ្លួនឯង', 'self');
  String get roleCaretaker => _t('អ្នកថែទាំ', 'Caretaker');
  String get roleFamily => _t('សមាជិកគ្រួសារ', 'Family member');
  String get roleDoctor => _t('គ្រូពេទ្យ', 'Doctor');
  String get rolePatient => _t('អ្នកជំងឺ', 'Patient');

  String linkRole(LinkRole r) {
    switch (r) {
      case LinkRole.doctor:
        return roleDoctor;
      case LinkRole.caretaker:
        return roleCaretaker;
      case LinkRole.family:
        return roleFamily;
    }
  }

  String linkCapability(LinkRole r) {
    switch (r) {
      case LinkRole.doctor:
        return _t('មើល + កំណត់សម្គាល់', 'view + notes');
      case LinkRole.caretaker:
        return _t('មើល + កត់ត្រា', 'view + record');
      case LinkRole.family:
        return _t('មើលតែប៉ុណ្ណោះ', 'view only');
    }
  }

  // ---------- Sync strip ----------

  String syncedAt(String t) => _t('បានធ្វើសមកាលកម្ម · ចុងក្រោយ $t', 'Synced · last update $t');
  String offlinePending(int c) => _t('គ្មានអ៊ីនធឺណិត · ការវាស់ ${n(c)} កំពុងរង់ចាំបញ្ជូន', 'Offline · ${n(c)} reading(s) waiting to sync');
  String get offlineNone => _t('គ្មានអ៊ីនធឺណិត · កំពុងបង្ហាញទិន្នន័យដែលបានរក្សាទុក', 'Offline mode — showing saved data');
  String get syncing => _t('កំពុងធ្វើសមកាលកម្ម...', 'Syncing...');

  // ---------- Home ----------

  String get todayStatus => _t('ស្ថានភាពព្រឹកនេះ', "This morning's status");
  String todayStatusFor(String name) => _t('ស្ថានភាពព្រឹកនេះ · $name', "This morning · $name");
  String get notRecorded => _t('មិនទាន់បានកត់ត្រាការវាស់ព្រឹកនេះទេ', "This morning's reading is not recorded yet");
  String notRecordedName(String name) => _t('$name មិនទាន់បានកត់ត្រាការវាស់ព្រឹកនេះទេ', '$name has not recorded this morning yet');
  String get recordCta => _t('កត់ត្រាការវាស់ព្រឹកនេះ', 'Record morning reading');
  String recordFor(String name) => _t('កត់ត្រាសម្រាប់ $name', 'Record for $name');
  String get recordHint => _t('ថតរូបអេក្រង់ម៉ាស៊ីន ឬវាយលេខដោយដៃ — ប្រហែល ${n(30)} វិនាទី', 'Photograph the device screen or type the numbers — about ${n(30)} seconds');
  String recordedAt(String t) => _t('បានកត់ត្រារួចហើយ ម៉ោង $t', 'Recorded today at $t');
  String get addAnother => _t('បន្ថែមការវាស់មួយទៀត', 'Add another reading');
  String get latest => _t('ការវាស់ចុងក្រោយ', 'Latest reading');
  String get bp => _t('សម្ពាធឈាម', 'Blood pressure');
  String get pulse => _t('ជីពចរ', 'Pulse');
  String get glucose => _t('ជាតិស្ករ', 'Glucose');
  String get bloodGlucose => _t('ជាតិស្ករក្នុងឈាម', 'Blood glucose');
  String get high => _t('ខ្ពស់', 'High');
  String get low => _t('ទាប', 'Low');
  String recordedBy(String name) => _t('កត់ត្រាដោយ៖ $name', 'Recorded by: $name');
  String get viewPhoto => _t('មើលរូបថត', 'View photo');
  String get doctorNote => _t('កំណត់សម្គាល់ពីគ្រូពេទ្យ', 'Doctor note');
  String get trend7 => _t('និន្នាការ ${n(7)} ថ្ងៃ · សម្ពាធឈាម', '${n(7)}-day trend · blood pressure');
  String get systolic => _t('សម្ពាធឈាមលើ', 'Systolic');
  String get diastolic => _t('សម្ពាធឈាមក្រោម', 'Diastolic');
  String get normalRange => _t('កម្រិតធម្មតា', 'Normal range');
  String get outOfRange => _t('លើសកម្រិតធម្មតា', 'Out of normal range');
  String daysOf(String range) => _t('ថ្ងៃទី $range', range);
  String get fullReport => _t('មើលរបាយការណ៍ពេញ', 'View full report');
  String get pendingSync => _t('រង់ចាំបញ្ជូន', 'Waiting to sync');
  String get savedOnPhone => _t('បានរក្សាទុកនៅលើទូរស័ព្ទនេះ។ នឹងបញ្ជូនដោយស្វ័យប្រវត្តិ ពេលមានអ៊ីនធឺណិតវិញ។', 'Saved on this phone. Will sync automatically when internet returns.');
  String get offlineInfo => _t('អ្នកនៅតែអាចមើលប្រវត្តិ និងរបាយការណ៍ពីទិន្នន័យដែលបានរក្សាទុកនៅលើទូរស័ព្ទ។', 'You can still view history and reports from data saved on this phone.');
  String welcome(String name) => _t('សូមស្វាគមន៍ $name!', 'Welcome, $name!');
  String get noReadingsYet => _t('មិនទាន់មានការវាស់នៅឡើយទេ', 'No readings recorded yet');
  String noReadingsYetBy(String name) => _t('$name មិនទាន់មានការវាស់នៅឡើយទេ', 'No readings recorded yet by $name');
  String get noReadingsHint => _t('បន្ទាប់ពីការវាស់ដំបូង អ្នកនឹងឃើញលេខចុងក្រោយ និងនិន្នាការ ${n(7)} ថ្ងៃនៅទីនេះ។', 'After your first reading, your latest numbers and ${n(7)}-day trend appear here.');
  String get linkCareTitle => _t('ភ្ជាប់គ្រូពេទ្យ ឬអ្នកថែទាំ', 'Link your doctor or caretaker');
  String get linkCareHint => _t('ចែករំលែកលេខកូដ ${n(6)} ខ្ទង់ ដើម្បីឱ្យពួកគេតាមដានការវាស់របស់អ្នក។', 'Share a ${n(6)}-digit code so they can follow your readings.');
  String get openLinks => _t('បើកទំព័រការភ្ជាប់', 'Open Links');

  // Caretaker / family context
  String get recordingFor => _t('កំពុងកត់ត្រាសម្រាប់៖', 'Recording for:');
  String choosePatient(int c) => _t('ជ្រើសរើសអ្នកជំងឺ (${n(c)})', 'Choose patient (${n(c)})');
  String get notRecordedShort => _t('មិនទាន់កត់ត្រាព្រឹកនេះ', 'Not recorded this morning');
  String recordedShort(String t) => _t('បានកត់ត្រា $t', 'Recorded $t');
  String get checkPatientName => _t('សូមពិនិត្យឈ្មោះអ្នកជំងឺឱ្យបានត្រឹមត្រូវ មុនពេលកត់ត្រា។', "Check the patient's name before recording.");
  String viewing(String name) => _t('កំពុងមើល៖ $name', 'Viewing: $name');
  String get readOnly => _t('មើលតែប៉ុណ្ណោះ', 'Read-only');

  // ---------- Record: camera ----------

  String get scanDevice => _t('ថតអេក្រង់ម៉ាស៊ីន', 'Scan device');
  String get deviceType => _t('ប្រភេទម៉ាស៊ីន', 'Device type');
  String get modeBp => _t('សម្ពាធឈាម', 'BP monitor');
  String get modeGlu => _t('ជាតិស្ករ', 'Glucose meter');
  String get ready => _t('រួចរាល់ — អាចថតបាន', 'Ready — take the photo');
  String get cameraGuide => _t('សូមដាក់អេក្រង់លេខម៉ាស៊ីនឱ្យចំក្នុងប្រអប់នេះ។ ផ្អៀងទូរស័ព្ទបន្តិច ប្រសិនបើមានពន្លឺចាំង។', 'Fit the device numbers inside this box. Tilt the phone slightly if light glares.');
  String get flashOff => _t('ភ្លើង Flash: បិទ', 'Flash: OFF');
  String get flashOn => _t('ភ្លើង Flash: បើក', 'Flash: ON');
  String get typeManual => _t('វាយលេខដោយដៃ', 'Type manually');
  String get takePhoto => _t('ថតរូប', 'Take photo');
  String get readingPhoto => _t('កំពុងអានលេខពីរូបភាព...', 'Reading numbers from photo...');
  String get pleaseWait => _t('សូមរង់ចាំបន្តិច', 'Please wait');
  String get timeoutHint => _t('ប្រសិនបើលើសពី ${n(6)} វិនាទី កម្មវិធីនឹងបើកទម្រង់វាយដោយដៃ ដោយរក្សារូបថតទុកនៅខាងលើ។', 'If it takes more than ${n(6)} seconds, the app opens manual entry and keeps the photo on top.');
  String get typeNow => _t('វាយលេខដោយដៃឥឡូវនេះ', 'Type manually now');
  String get photoKept => _t('រូបថតត្រូវបានរក្សាទុករួចហើយ', 'The photo is already saved');
  String get simulatedCamera => _t('កាមេរ៉ាសាកល្បង (គ្មានកាមេរ៉ាពិតនៅឡើយ)', 'Simulated camera (no real camera yet)');

  // ---------- Record: review ----------

  String get reviewTitle => _t('ផ្ទៀងផ្ទាត់ការវាស់', 'Confirm reading');
  String get manualTitle => _t('វាយលេខដោយដៃ', 'Type numbers');
  String get editTitle => _t('កែការវាស់', 'Edit reading');
  String get zoom => _t('ពង្រីក', 'Zoom');
  String get retake => _t('ថតម្ដងទៀត', 'Retake');
  String get ocrOk => _t('អានលេខពីរូបភាពបានជោគជ័យ។ សូមផ្ទៀងផ្ទាត់លេខខាងក្រោមមុនចុចរក្សាទុក។', 'Numbers read from photo. Please verify each value below before saving.');
  String get ocrLow => _t('លេខខ្លះមិនសូវច្បាស់ (ប្រអប់ពណ៌លឿង)។ សូមពិនិត្យ និងកែតម្រូវតាមរូបភាពខាងលើ។', 'Some numbers were unclear (highlighted in yellow). Please check and edit them using the photo above.');
  String get ocrFailed => _t('មិនអាចអានលេខពីរូបភាពបានទេ។ សូមមើលរូបភាពខាងលើ រួចវាយបញ្ចូលលេខដោយដៃ ឬថតម្ដងទៀត។', 'Could not read numbers from the photo. Please type them using the photo above, or retake the photo.');
  String get ocrOffline => _t('គ្មានអ៊ីនធឺណិត — រូបថតបានរក្សាទុកនៅលើទូរស័ព្ទ។ សូមវាយលេខខាងក្រោម ការវាស់នឹងបញ្ជូនដោយស្វ័យប្រវត្តិពេលក្រោយ។', 'Offline mode — photo saved on phone. Please type the numbers below; your reading will sync automatically later.');
  String get manualInfo => _t('សូមវាយលេខដែលបង្ហាញលើអេក្រង់ម៉ាស៊ីនរបស់អ្នក។', 'Type the numbers shown on your device screen.');
  String get usePhotoInstead => _t('ថតរូបជំនួសវិញ', 'Use a photo instead');
  String get errorBanner => _t('មានលេខមិនត្រឹមត្រូវ។ សូមមើលរូបថតខាងលើ ហើយកែប្រអប់ពណ៌ក្រហមមុនពេលរក្សាទុក។', 'Some numbers are not valid. Check the photo and fix the red boxes before saving.');
  String get errorBannerNoPhoto => _t('មានលេខមិនត្រឹមត្រូវ។ សូមកែប្រអប់ពណ៌ក្រហមមុនពេលរក្សាទុក។', 'Some numbers are not valid. Fix the red boxes before saving.');
  String get badgeCheck => _t('ពិនិត្យ', 'Check');
  String get badgeManual => _t('ដោយដៃ', 'Manual');
  String get badgeEdited => _t('OCR + កែ', 'OCR + edited');
  String get badgeWrong => _t('ខុស', 'Invalid');
  String get badgeEmpty => _t('មិនទាន់មាន', 'Empty');
  String get optional => _t('មិនចាំបាច់', 'Optional');
  String get extraFields => _t('វាលបន្ថែម', 'Extra fields');
  String get extraField => _t('វាលបន្ថែម', 'Extra field');
  String get scanGlucose => _t('ថតម៉ាស៊ីនវាស់ជាតិស្ករ', 'Scan glucose meter');
  String get orTypeHere => _t('ឬវាយលេខនៅទីនេះ', 'or type it here');
  String get glucoseUnit => _t('ឯកតាជាតិស្ករ', 'Glucose unit');
  String get noteLabel => _t('កំណត់សម្គាល់ (មិនចាំបាច់)', 'Note (optional)');
  String get noteHint => _t('ឧ. វិលមុខបន្តិចពេលក្រោកពីដំណេក', 'e.g. Felt slightly dizzy after waking');
  String example(String v) => _t('ឧ. ${n(v)}', 'e.g. ${n(v)}');
  String get save => _t('បញ្ជាក់ និងរក្សាទុក', 'Confirm & save');
  String get fixRedFirst => _t('សូមកែលេខពណ៌ក្រហមជាមុនសិន', 'Fix the red numbers first');
  String get enterSomething => _t('សូមបញ្ចូលសម្ពាធឈាម ឬជាតិស្ករយ៉ាងហោចណាស់មួយ', 'Enter blood pressure or glucose first');
  String get verifyField => _t('សូមផ្ទៀងផ្ទាត់លេខនេះតាមរូបភាពខាងលើ', 'Please verify this number against the photo above');
  String requiredField(String field) => _t('សូមបញ្ចូលតម្លៃ $field មុនពេលរក្សាទុក។', 'Please enter a value for $field before saving.');
  String get numberOnly => _t('សូមវាយបញ្ចូលតែលេខប៉ុណ្ណោះ (ឧ. ${n(120)})។', 'Please enter numbers only (e.g., ${n(120)}).');
  String hardRange(String field, String min, String max, String unit) => _t(
        'តម្លៃ $field មិនត្រឹមត្រូវទេ។ ត្រូវនៅចន្លោះ ${n(min)} ដល់ ${n(max)} $unit។ សូមពិនិត្យលេខឡើងវិញ។',
        'Invalid $field value. Must be between ${n(min)} and ${n(max)} $unit. Please check the number again.',
      );
  String aboveNormal(String min, String max, String unit) => _t(
        'ខ្ពស់ជាងកម្រិតធម្មតា (${n(min)}–${n(max)} $unit)។ សូមផ្ទៀងផ្ទាត់ជាមួយម៉ាស៊ីន ឬរូបភាពមុនពេលរក្សាទុក។',
        'Above normal range (${n(min)}–${n(max)} $unit). Please verify against your device or photo before saving.',
      );
  String belowNormal(String min, String max, String unit) => _t(
        'ទាបជាងកម្រិតធម្មតា (${n(min)}–${n(max)} $unit)។ សូមផ្ទៀងផ្ទាត់ជាមួយម៉ាស៊ីន ឬរូបភាពមុនពេលរក្សាទុក។',
        'Below normal range (${n(min)}–${n(max)} $unit). Please verify against your device or photo before saving.',
      );
  String get bpOrder => _t('សម្ពាធឈាមលើ (Systolic) ត្រូវតែធំជាងសម្ពាធឈាមក្រោម (Diastolic)។ សូមពិនិត្យម្ដងទៀត។', 'Systolic (upper BP) must be higher than Diastolic (lower BP). Please check both numbers.');
  String get swapBp => _t('ប្តូរលេខសម្ពាធឈាម', 'Swap BP numbers');
  String get flagNotice => _t('កំណត់ត្រានេះមានតម្លៃខុសពីកម្រិតធម្មតា ហើយនឹងដាក់សញ្ញាសម្គាល់ជូនគ្រូពេទ្យ។ កម្មវិធីនេះមិនជំនួសការពិនិត្យរបស់គ្រូពេទ្យទេ។', 'This reading has out-of-range values and will be flagged for your doctor. This app does not provide medical advice.');

  // Discard
  String get discardTitle => _t('បោះបង់ការវាស់នេះ?', 'Discard this reading?');
  String get discardBody => _t('លេខដែលអ្នកបានវាយនឹងមិនត្រូវបានរក្សាទុកទេ។', 'The numbers you entered will not be saved.');
  String get discard => _t('បោះបង់ការវាស់', 'Discard');
  String get keepEditing => _t('បន្តកែ', 'Keep editing');

  // Duplicate guard (FR-05)
  String get dupTitle => _t('មានកំណត់ត្រាព្រឹកនេះរួចហើយ', 'Morning Reading Already Recorded');
  String dupBody(String t) => _t('លោកអ្នកបានកត់ត្រារួចហើយនៅម៉ោង $t។ តើលោកអ្នកចង់ជំនួសកំណត់ត្រាចាស់ ឬរក្សាទុកទាំងពីរ?', 'You already recorded a reading at $t. Would you like to replace the earlier entry or keep both?');
  String get dupReplace => _t('ជំនួសកំណត់ត្រាចាស់', 'Replace Earlier Reading');
  String get dupKeep => _t('រក្សាទុកទាំងពីរ', 'Keep Both Readings');
  String get earlier => _t('ចាស់', 'Earlier');
  String get newer => _t('ថ្មី', 'New');

  // ---------- Reports ----------

  String get reportsTitle => _t('របាយការណ៍', 'Reports');
  String get history => _t('ប្រវត្តិ', 'History');
  String get reportOrHistory => _t('របាយការណ៍ ឬប្រវត្តិ', 'Reports or history');
  String get period => _t('រយៈពេល', 'Period');
  String days(int c) => _t('${n(c)} ថ្ងៃ', '${n(c)} days');
  String get custom => _t('កំណត់ខ្លួនឯង', 'Custom');
  String summaryOf(String p) => _t('សង្ខេប $p', '$p summary');
  String readingsCount(int c) => _t('ការវាស់ ${n(c)}', '${n(c)} readings');
  String missedDays(int c) => _t('ខកខាន ${n(c)} ថ្ងៃ', '${n(c)} days missed');
  String flaggedDays(int c) => _t('លើសកម្រិត ${n(c)} ថ្ងៃ', '${n(c)} days out of range');
  String get colMeasure => _t('ការវាស់', 'Measure');
  String get colMin => _t('ទាបបំផុត', 'Min');
  String get colAvg => _t('មធ្យម', 'Avg');
  String get colMax => _t('ខ្ពស់បំផុត', 'Max');
  String normalShort(String a, String b) => _t('ធម្មតា ${n(a)}–${n(b)}', 'normal ${n(a)}–${n(b)}');
  String flaggedTimes(int c) => _t('លើសកម្រិត ${n(c)} ដង', 'Out of range ${n(c)}×');
  String get tapPoint => _t('ចុចលើចំណុចណាមួយ ដើម្បីមើលការវាស់នោះ។', 'Tap any point to see that reading.');
  String get exportPdf => _t('ទាញយករបាយការណ៍ PDF', 'Export PDF report');
  String get exportHint => _t('ទំហំ A4 ស-ខ្មៅ សម្រាប់យកទៅជួបគ្រូពេទ្យ', 'A4 black-and-white, for your clinic visit');
  String get exportDisabled => _t('មិនអាចទាញយកបានទេ ព្រោះគ្មានការវាស់ក្នុងរយៈពេលនេះ', 'Nothing to export — no readings in this period');
  String get pdfLaterTitle => _t('PDF មិនទាន់មាននៅឡើយ', 'PDF export is not built yet');
  String get pdfLaterBody => _t('មុខងារនេះ (US-18) នឹងបន្ថែមពេលក្រោយ។ កំណែនេះប្រើទិន្នន័យគំរូ ហើយមិនទាន់ភ្ជាប់ម៉ាស៊ីនមេទេ។', 'This feature (US-18) comes later. This build uses sample data and has no server yet.');
  String get noReadingsPeriod => _t('មិនមានការវាស់ក្នុងរយៈពេលនេះទេ', 'No readings in this period');

  // History
  String get from => _t('ពី', 'From');
  String get to => _t('ដល់', 'To');
  String get showAll => _t('បង្ហាញគ្រប់ថ្ងៃ', 'Show all dates');
  String newestFirst(int c) => _t('ថ្មីបំផុតនៅខាងលើ · ការវាស់ ${n(c)} ក្នុងរយៈពេលនេះ', 'Newest first · ${n(c)} readings in this range');
  String get missedRow => _t('ខកខាន · គ្មានការវាស់', 'Missed · no reading');
  String get edit => _t('កែ', 'Edit');
  String get delete => _t('លុប', 'Delete');
  String get prev => _t('មុន', 'Previous');
  String get next => _t('បន្ទាប់', 'Next');
  String pageOf(int a, int b, int c) => _t('${n(a)}–${n(b)} នៃ ${n(c)}', '${n(a)}–${n(b)} of ${n(c)}');
  String get bpHigh => _t('សម្ពាធឈាមខ្ពស់', 'High blood pressure');
  String get bpLow => _t('សម្ពាធឈាមទាប', 'Low blood pressure');
  String get gluHigh => _t('ជាតិស្ករខ្ពស់', 'High glucose');
  String get gluLow => _t('ជាតិស្ករទាប', 'Low glucose');
  String get pulseOut => _t('ជីពចរខុសធម្មតា', 'Unusual pulse');
  String noReadingsBetween(String a, String b) => _t('មិនមានការវាស់ចន្លោះ $a ដល់ $b ទេ', 'No readings between $a and $b');
  String get delTitle => _t('លុបការវាស់នេះ?', 'Delete this reading?');
  String get delBody => _t('ការលុបនេះមិនអាចត្រឡប់វិញបានទេ។ របាយការណ៍ និងក្រាហ្វនឹងគណនាឡើងវិញដោយគ្មានការវាស់នេះ។', 'This cannot be undone. Reports and charts will be recalculated without this reading.');
  String get photoTitle => _t('រូបថតម៉ាស៊ីន', 'Device photo');
  String get pinchHint => _t('ប្រើម្រាមដៃពីរ ដើម្បីពង្រីក', 'Pinch with two fingers to zoom');
  String onlyAuthorEdits(String name) => _t('មានតែ $name ទេដែលអាចកែបាន', 'Only $name can edit this');

  // ---------- Links & settings ----------

  String get linksTitle => _t('ការភ្ជាប់ និងការកំណត់', 'Links & Settings');
  String get inviteCode => _t('លេខកូដអញ្ជើញ', 'Invite code');
  String get inviteHint => _t('ផ្ញើលេខកូដនេះទៅគ្រូពេទ្យ អ្នកថែទាំ ឬសមាជិកគ្រួសារ ដើម្បីឱ្យពួកគេមើលការវាស់របស់អ្នក។', 'Send this code to your doctor, caretaker or family so they can see your readings.');
  String expiresIn(String t) => _t('ផុតកំណត់ក្នុងរយៈពេល $t', 'Expires in $t');
  String get expired => _t('លេខកូដផុតកំណត់ហើយ — សូមបង្កើតលេខកូដថ្មី', 'Code expired — make a new code');
  String get copyCode => _t('ចម្លងលេខកូដ', 'Copy code');
  String get copied => _t('បានចម្លង', 'Copied');
  String get newCode => _t('លេខកូដថ្មី', 'New code');
  String whoCanSee(int c) => _t('អ្នកដែលអាចមើលការវាស់របស់អ្នក (${n(c)})', 'People who can see your readings (${n(c)})');
  String get noLinks => _t('មិនទាន់មាននរណាម្នាក់ភ្ជាប់ទេ។ សូមផ្ញើលេខកូដអញ្ជើញខាងលើ។', 'Nobody is linked yet. Send the invite code above.');
  String linkedSince(String d) => _t('ភ្ជាប់តាំងពី $d', 'Linked since $d');
  String get removeAccess => _t('ដកសិទ្ធិ', 'Remove access');
  String removeTitle(String name) => _t('ដកសិទ្ធិពី $name?', 'Remove access for $name?');
  String removeBody(String name) => _t('$name នឹងមិនអាចមើល ឬកត់ត្រាការវាស់របស់អ្នកទៀតទេ ចាប់ពីពេលនេះតទៅ។ ការវាស់ដែលបានកត់ត្រារួច នៅតែមានក្នុងប្រវត្តិ។', '$name will no longer see or record your readings from now on. Readings they already recorded stay in your history.');
  String get patientsYouSee => _t('អ្នកជំងឺដែលអ្នកអាចមើល', 'Patients you can see');
  String get reminder => _t('ការរំលឹកពេលព្រឹក', 'Morning reminder');
  String get reminderOn => _t('បើកការរំលឹករាល់ព្រឹក', 'Remind me every morning');
  String get reminderTime => _t('ម៉ោងរំលឹក', 'Reminder time');
  String get previewLabel => _t('ការជូនដំណឹងនឹងបង្ហាញដូចនេះ៖', 'The notification will look like this:');
  String get reminderMsg => _t('ដល់ពេលវាស់សម្ពាធឈាម និងជាតិស្ករហើយ។ សូមកត់ត្រាការវាស់ព្រឹកនេះ។', "Time to measure your blood pressure and glucose. Please record this morning's reading.");
  String get reminderSkip => _t('នឹងមិនរំលឹកទេ ប្រសិនបើបានកត់ត្រារួចហើយនៅថ្ងៃនោះ។', 'No reminder on days you have already recorded.');
  String get settings => _t('ការកំណត់', 'Settings');
  String get language => _t('ភាសា', 'Language');
  String get numerals => _t('ការបង្ហាញលេខ', 'Number display');
  String get kmDigitsOpt => 'លេខខ្មែរ ១២៣';
  String get arDigitsOpt => _t('លេខអារ៉ាប់ 123', 'Arabic 123');
  String get numeralsHint => _t('ការវាយបញ្ចូលលេខ តែងតែប្រើក្ដារលេខធម្មតា។', 'Number entry always uses the normal keypad.');
  String get signOut => _t('ចាកចេញ', 'Sign out');
  String get signOutTitle => _t('ចាកចេញពីគណនី?', 'Sign out?');
  String get signOutBody => _t('នៅក្នុងកំណែគំរូនេះ ការចាកចេញនឹងកំណត់ទិន្នន័យគំរូឡើងវិញ។', 'In this demo build, signing out resets the sample data.');
}
