// Hard-coded sample data. Dates are built relative to "today" so the app
// always looks current. Replace with API calls later; nothing else in the
// UI needs to change.

import 'dart:math';

import 'models.dart';

class _Row {
  const _Row(this.offset, this.sys, this.dia, this.pul, this.glu, this.wt, this.h, this.m, this.author, this.method);
  final int offset; // days before today
  final int sys;
  final int dia;
  final int pul;
  final double glu;
  final double wt;
  final int h;
  final int m;
  final String author;
  final EntryMethod method;
}

class MockData {
  MockData._();

  static const sokha = PatientInfo(
    id: 'sokha',
    name: Bi('សុខា ដារា', 'Sokha Dara'),
    firstName: Bi('សុខា', 'Sokha'),
    phone: '012 555 891',
  );

  static const kim = PatientInfo(
    id: 'kim',
    name: Bi('មាស គឹម', 'Meas Kim'),
    firstName: Bi('គឹម', 'Kim'),
    phone: '092 555 103',
  );

  static const patients = <PatientInfo>[sokha, kim];

  static const caretakerName = Bi('ម៉ី', 'Mey');
  static const familyName = Bi('ពិសិដ្ឋ', 'Piseth');

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime at(DateTime day, int h, int m) => DateTime(day.year, day.month, day.day, h, m);

  static DateTime daysAgo(DateTime today, int n) => DateTime(today.year, today.month, today.day - n);

  // The last 6 days, written by hand to match the design canvas.
  static const _recent = <_Row>[
    _Row(1, 138, 86, 74, 112, 62.4, 7, 8, 'mey', EntryMethod.ocr),
    _Row(2, 120, 78, 72, 98, 62.3, 7, 15, 'self', EntryMethod.manual),
    _Row(3, 130, 82, 75, 109, 62.5, 7, 30, 'self', EntryMethod.ocrEdited),
    // 4 days ago: missed
    _Row(5, 162, 98, 82, 185, 62.9, 7, 10, 'mey', EntryMethod.ocr),
    _Row(6, 143, 91, 76, 124, 62.6, 6, 58, 'self', EntryMethod.ocr),
  ];

  // Days 30 → 7 before today (oldest first). null = missed day.
  static const _sys = <int?>[118, 128, 121, 130, 126, null, 132, 129, 135, 127, 131, 140, 133, 128, null, 136, 142, 138, 134, 145, 139, 150, 141, 137];
  static const _dia = <int?>[74, 80, 76, 82, 79, null, 84, 81, 86, 78, 83, 90, 85, 80, null, 86, 92, 88, 84, 94, 89, 96, 90, 86];
  static const _pul = <int?>[72, 74, 70, 76, 73, null, 75, 71, 78, 74, 72, 80, 76, 73, null, 77, 79, 75, 74, 84, 76, 78, 75, 73];
  static const _glu = <int?>[98, 104, 92, 110, 101, null, 115, 106, 120, 99, 108, 130, 112, 104, null, 118, 126, 114, 109, 140, 121, 135, 117, 111];
  static const _wt = <double?>[62.0, 62.1, 61.8, 62.2, 62.0, null, 62.3, 62.1, 62.4, 62.2, 62.3, 62.6, 62.4, 62.2, null, 62.5, 62.7, 62.5, 62.4, 62.8, 62.6, 63.0, 62.7, 62.5];

  static Reading _make(String patientId, DateTime day, int offset, int sys, int dia, int pul, double glu, double wt, int h, int m, String author, EntryMethod method) {
    final photo = method != EntryMethod.manual;
    return Reading(
      id: '$patientId-$offset',
      patientId: patientId,
      time: at(day, h, m),
      systolic: sys,
      diastolic: dia,
      pulse: pul,
      glucose: glu,
      extra: <String, double>{'wt': wt},
      authorId: author,
      method: method,
      photoBp: photo,
      photoGlucose: photo,
    );
  }

  /// 90 days of readings for Sokha, ending yesterday (today not recorded yet).
  static List<Reading> sokhaReadings(DateTime now) {
    final today = dateOnly(now);
    final list = <Reading>[];

    for (final r in _recent) {
      list.add(_make('sokha', daysAgo(today, r.offset), r.offset, r.sys, r.dia, r.pul, r.glu, r.wt, r.h, r.m, r.author, r.method));
    }

    for (var i = 0; i < _sys.length; i++) {
      final s = _sys[i];
      if (s == null) continue;
      final offset = 30 - i;
      final author = offset % 3 == 0 ? 'mey' : 'self';
      final method = offset % 5 == 0 ? EntryMethod.manual : EntryMethod.ocr;
      list.add(_make('sokha', daysAgo(today, offset), offset, s, _dia[i]!, _pul[i]!, _glu[i]!.toDouble(), _wt[i]!, offset.isEven ? 7 : 6, 5 + (offset * 7) % 50, author, method));
    }

    final rng = Random(42);
    for (var offset = 31; offset < 90; offset++) {
      final sys = 118 + rng.nextInt(23);
      final dia = 74 + rng.nextInt(15);
      final pul = 68 + rng.nextInt(13);
      final glu = (92 + rng.nextInt(34)).toDouble();
      final wt = 61.5 + rng.nextInt(11) / 10;
      final h = rng.nextBool() ? 6 : 7;
      final m = 5 + rng.nextInt(50);
      if (offset % 9 == 0) continue; // missed day
      final author = offset % 3 == 0 ? 'mey' : 'self';
      final method = offset % 5 == 0 ? EntryMethod.manual : EntryMethod.ocr;
      list.add(_make('sokha', daysAgo(today, offset), offset, sys, dia, pul, glu, wt, h, m, author, method));
    }
    return list;
  }

  /// 30 days for Meas Kim (caretaker's second patient), recorded today at 06:45.
  static List<Reading> kimReadings(DateTime now) {
    final today = dateOnly(now);
    final list = <Reading>[
      _make('kim', today, 0, 128, 80, 70, 101, 55.2, 6, 45, 'mey', EntryMethod.ocr),
    ];
    final rng = Random(7);
    for (var offset = 1; offset < 30; offset++) {
      final sys = 116 + rng.nextInt(18);
      final dia = 72 + rng.nextInt(12);
      final pul = 64 + rng.nextInt(12);
      final glu = (90 + rng.nextInt(30)).toDouble();
      final wt = 55.0 + rng.nextInt(6) / 10;
      final m = 30 + rng.nextInt(25);
      if (offset % 11 == 0) continue;
      list.add(_make('kim', daysAgo(today, offset), offset, sys, dia, pul, glu, wt, 6, m, 'mey', EntryMethod.ocr));
    }
    return list;
  }

  /// Reading added by the "Recorded today" demo switch.
  static Reading todayDemo(DateTime now, String patientId, String author) {
    final today = dateOnly(now);
    return Reading(
      id: '$patientId-today-${now.millisecondsSinceEpoch}',
      patientId: patientId,
      time: at(today, 7, 12),
      systolic: 134,
      diastolic: 84,
      pulse: 76,
      glucose: 104,
      extra: const <String, double>{'wt': 62.5},
      authorId: author,
      method: EntryMethod.ocr,
      photoBp: true,
      photoGlucose: true,
    );
  }

  static DoctorNote? noteFor(String patientId, DateTime now) {
    if (patientId != 'sokha') return null;
    final today = dateOnly(now);
    return DoctorNote(
      text: const Bi(
        'សម្ពាធឈាមខ្ពស់បន្តិចក្នុងសប្តាហ៍នេះ។ សូមកាត់បន្ថយអំបិលនៅពេលអាហារពេលល្ងាច ហើយវាស់មុនពេលលេបថ្នាំពេលព្រឹក។',
        'Your blood pressure is slightly high this week. Please reduce salt at dinner and measure before your morning medication.',
      ),
      author: const Bi('វេជ្ជ. វណ្ណាក់', 'Dr. Vannak'),
      time: at(daysAgo(today, 1), 16, 40),
    );
  }

  static List<LinkedPerson> links(DateTime now) {
    final today = dateOnly(now);
    return <LinkedPerson>[
      LinkedPerson(id: 'vannak', name: const Bi('វេជ្ជ. វណ្ណាក់', 'Dr. Vannak'), role: LinkRole.doctor, since: daysAgo(today, 50)),
      LinkedPerson(id: 'mey', name: caretakerName, role: LinkRole.caretaker, since: daysAgo(today, 47)),
      LinkedPerson(id: 'piseth', name: const Bi('ពិសិដ្ឋ (កូនស្រី)', 'Piseth (daughter)'), role: LinkRole.family, since: daysAgo(today, 9)),
    ];
  }
}
