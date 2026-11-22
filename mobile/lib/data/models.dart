// Data models used by the UI. When the real API arrives, each owner maps
// their JSON into these classes and the screens keep working.

/// A piece of text in both languages (names, notes).
class Bi {
  const Bi(this.km, this.en);
  final String km;
  final String en;
  String of(bool isKm) => isKm ? km : en;
}

enum RangeStatus { normal, high, low }

enum EntryMethod { manual, ocr, ocrEdited }

enum DeviceMode { bp, glucose }

enum GlucoseUnit { mgdl, mmol }

enum Conf { high, low }

enum LinkRole { doctor, caretaker, family }

/// One tracked measure. Core vitals and Admin custom fields (US-16) share
/// this schema, so forms, history and reports render them the same way.
class VitalField {
  const VitalField({
    required this.id,
    required this.km,
    required this.en,
    required this.shortKm,
    required this.shortEn,
    required this.unit,
    required this.hardMin,
    required this.hardMax,
    required this.normalMin,
    required this.normalMax,
    this.decimal = false,
    this.optional = false,
    this.custom = false,
  });

  final String id;
  final String km;
  final String en;
  final String shortKm;
  final String shortEn;
  final String unit;
  final double hardMin;
  final double hardMax;
  final double normalMin;
  final double normalMax;
  final bool decimal;
  final bool optional;
  final bool custom;

  String label(bool isKm) => isKm ? km : en;
  String short(bool isKm) => isKm ? shortKm : shortEn;

  bool inHardLimits(double v) => v >= hardMin && v <= hardMax;

  RangeStatus status(double v) {
    if (v > normalMax) return RangeStatus.high;
    if (v < normalMin) return RangeStatus.low;
    return RangeStatus.normal;
  }

  String fmt(double v) => decimal ? v.toStringAsFixed(1) : v.round().toString();
}

/// The field schema. Placeholder normal ranges until the team picks a
/// reference (WHO / Cambodian MoH) — see the open questions in T3.
class Fields {
  Fields._();

  static const sys = VitalField(
    id: 'sys',
    km: 'សម្ពាធឈាមលើ (Systolic)',
    en: 'Systolic (upper BP)',
    shortKm: 'សម្ពាធឈាមលើ',
    shortEn: 'Systolic',
    unit: 'mmHg',
    hardMin: 50,
    hardMax: 260,
    normalMin: 90,
    normalMax: 120,
  );

  static const dia = VitalField(
    id: 'dia',
    km: 'សម្ពាធឈាមក្រោម (Diastolic)',
    en: 'Diastolic (lower BP)',
    shortKm: 'សម្ពាធឈាមក្រោម',
    shortEn: 'Diastolic',
    unit: 'mmHg',
    hardMin: 30,
    hardMax: 150,
    normalMin: 60,
    normalMax: 80,
  );

  static const pul = VitalField(
    id: 'pul',
    km: 'ជីពចរ',
    en: 'Pulse',
    shortKm: 'ជីពចរ',
    shortEn: 'Pulse',
    unit: 'bpm',
    hardMin: 30,
    hardMax: 220,
    normalMin: 60,
    normalMax: 100,
  );

  static const glu = VitalField(
    id: 'glu',
    km: 'ជាតិស្ករក្នុងឈាម',
    en: 'Blood glucose',
    shortKm: 'ជាតិស្ករ',
    shortEn: 'Glucose',
    unit: 'mg/dL',
    hardMin: 20,
    hardMax: 600,
    normalMin: 70,
    normalMax: 125,
  );

  static const gluMmol = VitalField(
    id: 'glu',
    km: 'ជាតិស្ករក្នុងឈាម',
    en: 'Blood glucose',
    shortKm: 'ជាតិស្ករ',
    shortEn: 'Glucose',
    unit: 'mmol/L',
    hardMin: 1.1,
    hardMax: 33.3,
    normalMin: 3.9,
    normalMax: 6.9,
    decimal: true,
  );

  /// Admin-defined custom fields (US-16). Hard-coded for now.
  static const weight = VitalField(
    id: 'wt',
    km: 'ទម្ងន់ខ្លួន',
    en: 'Body weight',
    shortKm: 'ទម្ងន់ខ្លួន',
    shortEn: 'Body weight',
    unit: 'kg',
    hardMin: 20,
    hardMax: 250,
    normalMin: 45,
    normalMax: 85,
    decimal: true,
    optional: true,
    custom: true,
  );

  static const custom = <VitalField>[weight];

  /// mg/dL per mmol/L for glucose.
  static const mmolFactor = 18.0;
}

class Reading {
  const Reading({
    required this.id,
    required this.patientId,
    required this.time,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.glucose,
    this.extra = const <String, double>{},
    this.note,
    required this.authorId,
    required this.method,
    this.pendingSync = false,
    this.photoBp = false,
    this.photoGlucose = false,
  });

  final String id;
  final String patientId;
  final DateTime time;
  final int? systolic;
  final int? diastolic;
  final int? pulse;

  /// Always stored in mg/dL.
  final double? glucose;

  /// Custom field values by field id (e.g. 'wt').
  final Map<String, double> extra;
  final String? note;

  /// 'self' (the patient) or 'mey' (the caretaker) in the sample data.
  final String authorId;
  final EntryMethod method;
  final bool pendingSync;
  final bool photoBp;
  final bool photoGlucose;

  bool get hasPhoto => photoBp || photoGlucose;
  bool get hasBp => systolic != null && diastolic != null;
  String get bpText => '$systolic/$diastolic';

  RangeStatus? get sysStatus => systolic == null ? null : Fields.sys.status(systolic!.toDouble());
  RangeStatus? get diaStatus => diastolic == null ? null : Fields.dia.status(diastolic!.toDouble());
  RangeStatus? get pulseStatus => pulse == null ? null : Fields.pul.status(pulse!.toDouble());
  RangeStatus? get gluStatus => glucose == null ? null : Fields.glu.status(glucose!);

  RangeStatus? get bpStatus {
    if (!hasBp) return null;
    if (sysStatus == RangeStatus.high || diaStatus == RangeStatus.high) return RangeStatus.high;
    if (sysStatus == RangeStatus.low || diaStatus == RangeStatus.low) return RangeStatus.low;
    return RangeStatus.normal;
  }

  bool get bpFlagged => bpStatus != null && bpStatus != RangeStatus.normal;
  bool get gluFlagged => gluStatus != null && gluStatus != RangeStatus.normal;
  bool get pulseFlagged => pulseStatus != null && pulseStatus != RangeStatus.normal;
  bool get flagged => bpFlagged || gluFlagged || pulseFlagged;

  Reading copyWith({bool? pendingSync}) => Reading(
        id: id,
        patientId: patientId,
        time: time,
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        glucose: glucose,
        extra: extra,
        note: note,
        authorId: authorId,
        method: method,
        pendingSync: pendingSync ?? this.pendingSync,
        photoBp: photoBp,
        photoGlucose: photoGlucose,
      );
}

class PatientInfo {
  const PatientInfo({required this.id, required this.name, required this.firstName, required this.phone});
  final String id;
  final Bi name;
  final Bi firstName;
  final String phone;
}

class LinkedPerson {
  const LinkedPerson({required this.id, required this.name, required this.role, required this.since});
  final String id;
  final Bi name;
  final LinkRole role;
  final DateTime since;
}

class DoctorNote {
  const DoctorNote({required this.text, required this.author, required this.time});
  final Bi text;
  final Bi author;
  final DateTime time;
}

/// What the OCR module hands to the review screen (Phak → Seyla contract).
class OcrResult {
  const OcrResult({
    required this.mode,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.glucose,
    this.unit = GlucoseUnit.mgdl,
    this.conf = const <String, Conf>{},
    this.failed = false,
    this.offline = false,
  });

  final DeviceMode mode;
  final String? systolic;
  final String? diastolic;
  final String? pulse;
  final String? glucose;
  final GlucoseUnit unit;

  /// Confidence per field id ('sys', 'dia', 'pul', 'glu').
  final Map<String, Conf> conf;
  final bool failed;
  final bool offline;
}
