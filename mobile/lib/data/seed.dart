// Demo data (mirrors the "seed script" in the plan: 4 test patients, 90 days
// of readings, one test user per role). Dates are generated relative to today
// so the demo always looks fresh. Deterministic random numbers, so a reset
// always gives the same data.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'dates.dart';
import 'types.dart';

const seedVersion = 4;

/// mulberry32, bit-for-bit the same as the JavaScript prototype.
@visibleForTesting
double Function() seedRandom(int seed) {
  var a = seed;
  int imul(int x, int y) => ((x & 0xFFFFFFFF) * (y & 0xFFFFFFFF)).toSigned(32);
  int ushr(int x, int n) => (x & 0xFFFFFFFF) >> n;
  return () {
    a = (a + 0x6d2b79f5).toSigned(32);
    var t = imul(a ^ ushr(a, 15), 1 | a);
    t = (t + imul(t ^ ushr(t, 7), 61 | t)).toSigned(32) ^ t;
    return ((t ^ ushr(t, 14)) & 0xFFFFFFFF) / 4294967296;
  };
}

/// JavaScript's Math.round (halves round up).
int _round(double x) => (x + 0.5).floor();

const users = <AppUser>[
  AppUser(
    id: 'p1', role: Role.patient, nameEn: 'Sok Chantha', nameKm: 'សុខ ចន្ថា', phone: '012 345 678', age: 64,
    conditionsEn: 'High blood pressure, type 2 diabetes', conditionsKm: 'លើសសម្ពាធឈាម ទឹកនោមផ្អែមប្រភេទទី២',
  ),
  AppUser(
    id: 'p2', role: Role.patient, nameEn: 'Keo Sreymom', nameKm: 'កែវ ស្រីមុំ', phone: '017 222 310', age: 78,
    conditionsEn: 'Type 2 diabetes', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  ),
  AppUser(
    id: 'p3', role: Role.patient, nameEn: 'Chea Vuthy', nameKm: 'ជា វុទ្ធី', phone: '015 880 112', age: 59,
    conditionsEn: 'Type 2 diabetes', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  ),
  AppUser(
    id: 'p4', role: Role.patient, nameEn: 'Meas Sophea', nameKm: 'មាស សុភា', phone: '010 456 901', age: 81,
    conditionsEn: 'High blood pressure', conditionsKm: 'លើសសម្ពាធឈាម',
  ),
  AppUser(id: 'c1', role: Role.caretaker, nameEn: 'Dara Pich', nameKm: 'ពេជ្រ ដារ៉ា', phone: '011 765 432'),
  AppUser(id: 'f1', role: Role.family, nameEn: 'Sok Sreyleak', nameKm: 'សុខ ស្រីលក្ខ', phone: '096 555 0101'),
  AppUser(id: 'd1', role: Role.doctor, nameEn: 'Dr. Lim Bunthoeun', nameKm: 'វេជ្ជ. លឹម ប៊ុនធឿន', phone: '023 900 100'),
  AppUser(id: 'd2', role: Role.doctor, nameEn: 'Dr. Ouk Malis', nameKm: 'វេជ្ជ. អ៊ុក ម៉ាលីស', phone: '023 900 200'),
  AppUser(id: 'a1', role: Role.admin, nameEn: 'Admin', nameKm: 'អ្នកគ្រប់គ្រង', phone: '-'),
];

/// The signed-in user for each demo role (dev login).
const demoLogins = <Role, String>{
  Role.patient: 'p1',
  Role.caretaker: 'c1',
  Role.family: 'f1',
  Role.doctor: 'd1',
};

class _Profile {
  const _Profile(this.id, this.sys, this.dia, this.pulse, this.glu, this.sysSd, this.gluSd, this.skip, this.enteredBy,
      {this.weight, this.skipLastDays = 0, this.skipToday = false, this.trend = 0});
  final String id;
  final double sys, dia, pulse, glu, sysSd, gluSd;

  /// Chance to miss a day.
  final double skip;
  final String enteredBy;
  final double? weight;
  final int skipLastDays;
  final bool skipToday;

  /// Systolic drift per 30 days (negative = improving).
  final double trend;
}

const _profiles = [
  // Patient demo account: improving BP, not yet recorded today (so Home shows "Record now")
  _Profile('p1', 128, 77, 76, 110, 6, 12, 0.06, 'p1', weight: 68.5, skipToday: true, trend: -5),
  // Elderly, caretaker records; occasional low glucose; recorded today
  _Profile('p2', 114, 72, 72, 98, 5, 10, 0.04, 'c1'),
  // Missed the last 3 days → dashboard "missed" flag
  _Profile('p3', 120, 78, 80, 158, 6, 25, 0.15, 'p3', weight: 74, skipLastDays: 3),
  // Rising BP → dashboard "high" flag
  _Profile('p4', 148, 90, 70, 110, 9, 12, 0.08, 'c1', trend: 8),
];

const _notesEn = ['Felt dizzy', 'After a short walk', 'Forgot medicine yesterday', 'Slept badly'];
const _notesKm = ['មានវិលមុខ', 'ក្រោយដើរលេងបន្តិច', 'ភ្លេចលេបថ្នាំម្សិលមិញ', 'គេងមិនលក់ស្រួល'];

/// Box–Muller.
double _gauss(double Function() r) {
  final u = math.max(r(), 1e-9);
  final v = r();
  return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
}

List<Reading> _makeReadings(DateTime now) {
  final out = <Reading>[];
  final today = startOfDay(now);
  for (var pi = 0; pi < _profiles.length; pi++) {
    final p = _profiles[pi];
    final r = seedRandom(1000 + pi * 77);
    for (var back = 89; back >= 0; back--) {
      final day = addDays(today, -back);
      if (back == 0 && p.skipToday) continue;
      if (back < p.skipLastDays) continue;
      if (back > 0 && r() < p.skip) continue;
      final progress = (89 - back) / 30; // months elapsed
      final drift = p.trend * progress - p.trend * 1.5;
      final sys = _round(p.sys + drift + _gauss(r) * p.sysSd);
      final dia = _round(p.dia + drift * 0.5 + _gauss(r) * (p.sysSd * 0.6));
      final pulse = _round(p.pulse + _gauss(r) * 6);
      var glu = _round(p.glu + _gauss(r) * p.gluSd);
      if (p.id == 'p2' && r() < 0.05) glu = 62 + _round(r() * 5);
      var t = DateTime(day.year, day.month, day.day, 6, _round(r() * 120)); // 6:00–8:00
      if (back == 0 && t.isAfter(now)) t = now.subtract(const Duration(minutes: 5));
      final extra = <String, double>{};
      if (p.weight != null && back % 7 == 0) {
        extra['weight'] = _round((p.weight! + _gauss(r) * 0.6 - progress * 0.3) * 10) / 10;
      }
      final noteIdx = r() < 0.07 ? (r() * _notesEn.length).floor() : -1;
      out.add(Reading(
        id: 'seed-${p.id}-$back',
        patientId: p.id,
        takenAt: t,
        systolic: math.max(80, sys).toDouble(),
        diastolic: math.max(45, math.min(dia, sys - 20)).toDouble(),
        pulse: pulse.toDouble(),
        glucose: math.max(45, glu).toDouble(),
        extra: extra,
        enteredBy: p.enteredBy,
        method: r() < 0.55 ? EntryMethod.ocr : EntryMethod.manual,
        note: noteIdx >= 0 ? (pi.isEven ? _notesKm[noteIdx] : _notesEn[noteIdx]) : null,
      ));
    }
  }
  return out;
}

DataState makeSeed([DateTime? at]) {
  final now = at ?? DateTime.now();
  DateTime ago(int days) => addDays(now, -days);
  Link link(String id, String patientId, String userId, LinkRelation rel, LinkStatus status, int daysAgo,
          {bool byPatient = true}) =>
      Link(
        id: id,
        patientId: patientId,
        userId: userId,
        relation: rel,
        status: status,
        initiatedByPatient: byPatient,
        createdAt: ago(daysAgo),
      );
  return DataState(
    version: seedVersion,
    users: users,
    links: [
      // Patient demo account p1
      link('l1', 'p1', 'd1', LinkRelation.doctor, LinkStatus.active, 120),
      link('l2', 'p1', 'f1', LinkRelation.family, LinkStatus.active, 100),
      link('l3', 'p1', 'd2', LinkRelation.doctor, LinkStatus.pending, 1, byPatient: false), // waiting for p1's approval
      // Caretaker c1 records for p2 and p4
      link('l4', 'p2', 'c1', LinkRelation.caretaker, LinkStatus.active, 200),
      link('l5', 'p4', 'c1', LinkRelation.caretaker, LinkStatus.active, 150),
      // Family f1 follows p1 and p2
      link('l6', 'p2', 'f1', LinkRelation.family, LinkStatus.active, 180),
      // Doctor d1 follows everyone
      link('l7', 'p2', 'd1', LinkRelation.doctor, LinkStatus.active, 300),
      link('l8', 'p3', 'd1', LinkRelation.doctor, LinkStatus.active, 90),
      link('l9', 'p4', 'd1', LinkRelation.doctor, LinkStatus.active, 60),
    ],
    readings: _makeReadings(now),
    fields: const [
      // Added by the admin on the web (FR-15); appears automatically in the form, history and reports
      CustomField(id: 'weight', nameEn: 'Weight', nameKm: 'ទម្ងន់', unit: 'kg', decimals: 1, min: 2, max: 300),
    ],
    notes: [
      DoctorNote(
        id: 'n1', patientId: 'p1', authorId: 'd1', createdAt: ago(6),
        text: 'Blood pressure is improving. Keep taking amlodipine every morning and walk 30 minutes a day.',
      ),
      DoctorNote(
        id: 'n2', patientId: 'p4', authorId: 'd1', createdAt: ago(3),
        text: 'BP trending up. Please come to the clinic this week.',
      ),
    ],
  );
}
