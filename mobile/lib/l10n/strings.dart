// All user-facing text goes through I18n.t(key). The strings live in
// en.dart and km.dart; Khmer is the default (NFR-01).
// Khmer numerals (១២៣) are a display option only; stored values are always
// plain numbers (NFR-02).

import '../data/types.dart';
import 'en.dart';
import 'km.dart';

const _khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
const _monthsKm = ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
// Index 0 = Sunday, like JavaScript's getDay().
const _daysKm = ['អាទិត្យ', 'ច័ន្ទ', 'អង្គារ', 'ពុធ', 'ព្រហស្បតិ៍', 'សុក្រ', 'សៅរ៍'];
const _daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Translations for API error messageKeys (api/src/shared/errors.ts + network errors).
const Map<String, String> apiErrorsKm = {
  'errors.bad_request': 'សំណើមិនត្រឹមត្រូវទេ។ សូមពិនិត្យព័ត៌មានម្តងទៀត។',
  'errors.validation_failed': 'ទិន្នន័យដែលបានបញ្ចូលមិនត្រឹមត្រូវទេ។',
  'errors.unauthorized': 'សម័យប្រើប្រាស់ផុតកំណត់ ឬមិនទាន់ចូលគណនី។ សូមចូលម្តងទៀត។',
  'errors.forbidden': 'អ្នកមិនមានសិទ្ធិមើលទិន្នន័យនេះទេ។',
  'errors.not_found': 'រកមិនឃើញទិន្នន័យដែលបានស្នើសុំទេ។',
  'errors.conflict': 'ទិន្នន័យនេះមានរួចហើយ។',
  'errors.db_unavailable': 'ប្រព័ន្ធទិន្នន័យមិនអាចភ្ជាប់បានជាបណ្តោះអាសន្ន។ សូមព្យាយាមម្តងទៀត។',
  'errors.internal_error': 'មានបញ្ហាបច្ចេកទេសនៅម៉ាស៊ីនមេ។ សូមព្យាយាមម្តងទៀត។',
  'errors.network': 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត។',
};

const Map<String, String> apiErrorsEn = {
  'errors.bad_request': 'Invalid request. Please check your input and try again.',
  'errors.validation_failed': 'Some fields are invalid. Please check and try again.',
  'errors.unauthorized': 'Session expired or not signed in. Please sign in again.',
  'errors.forbidden': 'You do not have permission to view this data.',
  'errors.not_found': 'The requested record was not found.',
  'errors.conflict': 'This record already exists.',
  'errors.db_unavailable': 'Database is temporarily unavailable. Please try again.',
  'errors.internal_error': 'Something went wrong on the server. Please try again.',
  'errors.network': 'Could not reach the server. Please check your connection.',
};

String toKhmerDigits(String s) => s.replaceAllMapped(RegExp('[0-9]'), (m) => _khmerDigits[int.parse(m[0]!)]);

/// Converts Khmer digits typed on a Khmer keyboard back to plain digits.
String fromKhmerDigits(String s) =>
    s.replaceAllMapped(RegExp('[០-៩]'), (m) => '${_khmerDigits.indexOf(m[0]!)}');

int _sundayFirst(DateTime d) => d.weekday % 7;

class I18n {
  I18n(this.lang, this.numerals) : _dict = lang == Lang.km ? km : en;

  final Lang lang;
  final Numerals numerals;
  final Map<String, String> _dict;

  bool get isKm => lang == Lang.km;

  String t(String key, [Map<String, Object> params = const {}]) {
    var s = _dict[key] ?? en[key] ?? key;
    params.forEach((k, v) {
      s = s.replaceAll('{$k}', v is num ? n(v) : '$v');
    });
    return s;
  }

  String digits(String s) => numerals == Numerals.khmer ? toKhmerDigits(s) : s;

  /// A number for display; '–' when there is no value.
  String n(num? v, [int decimals = 0]) =>
      v == null || v.isNaN ? '–' : digits(v.toStringAsFixed(decimals));

  List<String> get _months => isKm ? _monthsKm : _monthsEn;
  List<String> get _days => isKm ? _daysKm : _daysEn;

  /// Wed 25 Nov 2026
  String date(DateTime d) => '${_days[_sundayFirst(d)]} ${digits('${d.day}')} ${_months[d.month - 1]} ${digits('${d.year}')}';

  /// 25 Nov
  String dateShort(DateTime d) => '${digits('${d.day}')} ${_months[d.month - 1]}';

  /// Today / Yesterday / Mon 23 Nov
  String dateRelative(DateTime d) {
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day - 1);
    bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    if (same(d, now)) return t('today');
    if (same(d, y)) return t('yesterday');
    return '${_days[_sundayFirst(d)]} ${dateShort(d)}';
  }

  /// 6:45 AM / 6:45 ព្រឹក
  String timeOfMinutes(int mins) {
    final h = mins ~/ 60;
    final m = '${mins % 60}'.padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    if (isKm) {
      final part = h < 12 ? 'ព្រឹក' : h < 17 ? 'រសៀល' : 'ល្ងាច';
      return '${digits('$h12:$m')} $part';
    }
    return '${digits('$h12:$m')}${h < 12 ? ' AM' : ' PM'}';
  }

  String time(DateTime d) => timeOfMinutes(d.hour * 60 + d.minute);

  String dayName(DateTime d) => _days[_sundayFirst(d)];

  String monthYear(DateTime d) => '${_months[d.month - 1]} ${digits('${d.year}')}';

  /// Indexed Sunday-first.
  List<String> get weekdayInitials =>
      isKm ? const ['អា', 'ច', 'អ', 'ពុ', 'ព្រ', 'សុ', 'ស'] : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  String weekdayInitial(DateTime d) => weekdayInitials[_sundayFirst(d)];

  String name(Named? u) => u == null ? '' : (isKm ? u.nameKm : u.nameEn);

  String role(Role r) => t('role_${r.name}');

  String apiError(String messageKey) {
    final map = isKm ? apiErrorsKm : apiErrorsEn;
    return map[messageKey] ?? map['errors.internal_error']!;
  }
}
