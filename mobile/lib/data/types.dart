// Data types. These mirror what the API will return later (docs/api.yaml).

enum Role { patient, caretaker, family, doctor, admin }

enum Lang { km, en }

enum Numerals { khmer, western }

enum LinkRelation { doctor, caretaker, family }

enum LinkStatus { active, pending }

enum EntryMethod { manual, ocr }

enum MeasureKey { systolic, diastolic, pulse, glucose }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

/// Anything with a Khmer and an English name (users, custom fields).
abstract class Named {
  String get nameEn;
  String get nameKm;
}

class AppUser implements Named {
  const AppUser({
    required this.id,
    required this.role,
    required this.nameEn,
    required this.nameKm,
    required this.phone,
    this.age,
    this.conditionsEn,
    this.conditionsKm,
  });

  final String id;
  final Role role;
  @override
  final String nameEn;
  @override
  final String nameKm;
  final String phone;

  /// Patients only.
  final int? age;
  final String? conditionsEn;
  final String? conditionsKm;

  Map<String, Object?> toJson() => {
        'id': id,
        'role': role.name,
        'nameEn': nameEn,
        'nameKm': nameKm,
        'phone': phone,
        'age': age,
        'conditionsEn': conditionsEn,
        'conditionsKm': conditionsKm,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        role: _enumByName(Role.values, j['role'], Role.patient),
        nameEn: j['nameEn'] as String,
        nameKm: j['nameKm'] as String,
        phone: j['phone'] as String,
        age: j['age'] as int?,
        conditionsEn: j['conditionsEn'] as String?,
        conditionsKm: j['conditionsKm'] as String?,
      );
}

class Link {
  const Link({
    required this.id,
    required this.patientId,
    required this.userId,
    required this.relation,
    required this.status,
    required this.initiatedByPatient,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String userId;
  final LinkRelation relation;
  final LinkStatus status;

  /// True when the patient started it (invite code / phone); false for a
  /// request waiting for the patient's approval.
  final bool initiatedByPatient;
  final DateTime createdAt;

  Link copyWith({LinkStatus? status}) => Link(
        id: id,
        patientId: patientId,
        userId: userId,
        relation: relation,
        status: status ?? this.status,
        initiatedByPatient: initiatedByPatient,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'patientId': patientId,
        'userId': userId,
        'relation': relation.name,
        'status': status.name,
        'initiatedByPatient': initiatedByPatient,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Link.fromJson(Map<String, dynamic> j) => Link(
        id: j['id'] as String,
        patientId: j['patientId'] as String,
        userId: j['userId'] as String,
        relation: _enumByName(LinkRelation.values, j['relation'], LinkRelation.family),
        status: _enumByName(LinkStatus.values, j['status'], LinkStatus.pending),
        initiatedByPatient: j['initiatedByPatient'] as bool,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class Reading {
  const Reading({
    required this.id,
    required this.patientId,
    required this.takenAt,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.glucose,
    this.extra = const {},
    required this.enteredBy,
    required this.method,
    this.note,
    this.photoUri,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime takenAt;
  final double? systolic;
  final double? diastolic;
  final double? pulse;

  /// Always stored in mg/dL.
  final double? glucose;

  /// Admin-defined fields, by field id.
  final Map<String, double> extra;

  /// User id.
  final String enteredBy;
  final EntryMethod method;
  final String? note;
  final String? photoUri;
  final DateTime? updatedAt;

  bool get hasBp => systolic != null && diastolic != null;

  double? valueOf(MeasureKey k) => switch (k) {
        MeasureKey.systolic => systolic,
        MeasureKey.diastolic => diastolic,
        MeasureKey.pulse => pulse,
        MeasureKey.glucose => glucose,
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'patientId': patientId,
        'takenAt': takenAt.toIso8601String(),
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'glucose': glucose,
        'extra': extra,
        'enteredBy': enteredBy,
        'method': method.name,
        'note': note,
        'photoUri': photoUri,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Reading.fromJson(Map<String, dynamic> j) {
    double? d(Object? v) => (v as num?)?.toDouble();
    return Reading(
      id: j['id'] as String,
      patientId: j['patientId'] as String,
      takenAt: DateTime.parse(j['takenAt'] as String),
      systolic: d(j['systolic']),
      diastolic: d(j['diastolic']),
      pulse: d(j['pulse']),
      glucose: d(j['glucose']),
      extra: (j['extra'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      enteredBy: j['enteredBy'] as String,
      method: _enumByName(EntryMethod.values, j['method'], EntryMethod.manual),
      note: j['note'] as String?,
      photoUri: j['photoUri'] as String?,
      updatedAt: j['updatedAt'] == null ? null : DateTime.parse(j['updatedAt'] as String),
    );
  }
}

/// Admin-defined field (FR-15). Created on the web admin; the app only reads them.
class CustomField implements Named {
  const CustomField({
    required this.id,
    required this.nameEn,
    required this.nameKm,
    required this.unit,
    required this.decimals,
    required this.min,
    required this.max,
  });

  final String id;
  @override
  final String nameEn;
  @override
  final String nameKm;
  final String unit;
  final int decimals;

  /// Safe input limits.
  final double min;
  final double max;

  Map<String, Object?> toJson() =>
      {'id': id, 'nameEn': nameEn, 'nameKm': nameKm, 'unit': unit, 'decimals': decimals, 'min': min, 'max': max};

  factory CustomField.fromJson(Map<String, dynamic> j) => CustomField(
        id: j['id'] as String,
        nameEn: j['nameEn'] as String,
        nameKm: j['nameKm'] as String,
        unit: j['unit'] as String,
        decimals: j['decimals'] as int,
        min: (j['min'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
      );
}

class DoctorNote {
  const DoctorNote({
    required this.id,
    required this.patientId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() =>
      {'id': id, 'patientId': patientId, 'authorId': authorId, 'text': text, 'createdAt': createdAt.toIso8601String()};

  factory DoctorNote.fromJson(Map<String, dynamic> j) => DoctorNote(
        id: j['id'] as String,
        patientId: j['patientId'] as String,
        authorId: j['authorId'] as String,
        text: j['text'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class Settings {
  const Settings({
    this.lang = Lang.km,
    this.numerals = Numerals.western,
    this.textScale = 1,
    this.reminderOn = true,
    this.reminderMinutes = 6 * 60 + 30,
  });

  final Lang lang;
  final Numerals numerals;

  /// 1, 1.15 or 1.3.
  final double textScale;
  final bool reminderOn;

  /// Minutes after midnight.
  final int reminderMinutes;

  Settings copyWith({Lang? lang, Numerals? numerals, double? textScale, bool? reminderOn, int? reminderMinutes}) =>
      Settings(
        lang: lang ?? this.lang,
        numerals: numerals ?? this.numerals,
        textScale: textScale ?? this.textScale,
        reminderOn: reminderOn ?? this.reminderOn,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      );

  Map<String, Object?> toJson() => {
        'lang': lang.name,
        'numerals': numerals.name,
        'textScale': textScale,
        'reminderOn': reminderOn,
        'reminderMinutes': reminderMinutes,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    const d = Settings();
    return Settings(
      lang: _enumByName(Lang.values, j['lang'], d.lang),
      numerals: _enumByName(Numerals.values, j['numerals'], d.numerals),
      textScale: (j['textScale'] as num?)?.toDouble() ?? d.textScale,
      reminderOn: j['reminderOn'] as bool? ?? d.reminderOn,
      reminderMinutes: j['reminderMinutes'] as int? ?? d.reminderMinutes,
    );
  }
}

class DataState {
  const DataState({
    required this.version,
    required this.users,
    required this.links,
    required this.readings,
    required this.fields,
    required this.notes,
  });

  final int version;
  final List<AppUser> users;
  final List<Link> links;
  final List<Reading> readings;
  final List<CustomField> fields;
  final List<DoctorNote> notes;

  DataState copyWith({
    List<AppUser>? users,
    List<Link>? links,
    List<Reading>? readings,
    List<CustomField>? fields,
    List<DoctorNote>? notes,
  }) =>
      DataState(
        version: version,
        users: users ?? this.users,
        links: links ?? this.links,
        readings: readings ?? this.readings,
        fields: fields ?? this.fields,
        notes: notes ?? this.notes,
      );

  Map<String, Object?> toJson() => {
        'version': version,
        'users': [for (final u in users) u.toJson()],
        'links': [for (final l in links) l.toJson()],
        'readings': [for (final r in readings) r.toJson()],
        'fields': [for (final f in fields) f.toJson()],
        'notes': [for (final n in notes) n.toJson()],
      };

  factory DataState.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
        [for (final x in j[k] as List<dynamic>) f(x as Map<String, dynamic>)];
    return DataState(
      version: j['version'] as int,
      users: list('users', AppUser.fromJson),
      links: list('links', Link.fromJson),
      readings: list('readings', Reading.fromJson),
      fields: list('fields', CustomField.fromJson),
      notes: list('notes', DoctorNote.fromJson),
    );
  }
}
