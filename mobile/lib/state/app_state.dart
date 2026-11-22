// One place for all app state while there is no backend.
// Screens read it with AppScope.of(context) and rebuild when it changes.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';

enum AppLang { km, en }

enum Role { patient, caretaker, family }

/// What the simulated OCR returns (demo control — Phak replaces this
/// with the real OCR module).
enum OcrScenario { clear, partial, failed, misread }

class AppState extends ChangeNotifier {
  AppState() {
    _load();
  }

  // Settings
  AppLang lang = AppLang.km;
  bool khmerDigits = false;
  bool reminderOn = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 6, minute: 30);

  // Demo controls
  Role role = Role.patient;
  OcrScenario ocrScenario = OcrScenario.partial;
  bool offline = false;
  bool syncing = false;
  bool emptyAccount = false;

  // Data
  String activePatientId = 'sokha';
  late DateTime lastSync;
  late String inviteCode;
  late DateTime inviteExpires;
  List<LinkedPerson> links = <LinkedPerson>[];
  final Map<String, List<Reading>> _readings = <String, List<Reading>>{};
  List<Reading> _emptyBackup = <Reading>[];

  Timer? _syncTimer;
  int _seq = 0;
  final Random _rng = Random();

  void _load() {
    final n = DateTime.now();
    _readings
      ..clear()
      ..['sokha'] = MockData.sokhaReadings(n)
      ..['kim'] = MockData.kimReadings(n);
    links = MockData.links(n);
    lastSync = n.subtract(const Duration(minutes: 3));
    inviteCode = '482915';
    inviteExpires = n.add(const Duration(hours: 23, minutes: 41, seconds: 8));
    emptyAccount = false;
    _emptyBackup = <Reading>[];
    offline = false;
    syncing = false;
    activePatientId = 'sokha';
    reminderOn = true;
    reminderTime = const TimeOfDay(hour: 6, minute: 30);
  }

  /// Sign out (demo): reload the sample data, keep language + role.
  void resetDemo() {
    _syncTimer?.cancel();
    _load();
    notifyListeners();
  }

  // ---------- Derived values ----------

  bool get isKm => lang == AppLang.km;

  DateTime get today => MockData.dateOnly(DateTime.now());

  PatientInfo get activePatient => MockData.patients.firstWhere((p) => p.id == activePatientId);

  List<PatientInfo> get visiblePatients => role == Role.caretaker ? MockData.patients : const <PatientInfo>[MockData.sokha];

  /// Who is using the phone, as an author id in the sample data.
  String get currentUserId {
    switch (role) {
      case Role.patient:
        return 'self';
      case Role.caretaker:
        return 'mey';
      case Role.family:
        return 'family';
    }
  }

  bool get canRecord => role != Role.family;

  List<Reading> readingsOf(String patientId) {
    final l = List<Reading>.of(_readings[patientId] ?? const <Reading>[]);
    l.sort((a, b) => b.time.compareTo(a.time));
    return l;
  }

  /// Newest first.
  List<Reading> get readings => readingsOf(activePatientId);

  Reading? get latest {
    final r = readings;
    return r.isEmpty ? null : r.first;
  }

  Reading? todayReadingOf(String patientId) {
    final t = today;
    for (final r in readingsOf(patientId)) {
      if (MockData.dateOnly(r.time) == t) return r;
    }
    return null;
  }

  Reading? get todayReading => todayReadingOf(activePatientId);

  bool recordedToday(String patientId) => todayReadingOf(patientId) != null;

  DoctorNote? get doctorNote => MockData.noteFor(activePatientId, DateTime.now());

  int get pendingCount => _readings.values.expand((l) => l).where((r) => r.pendingSync).length;

  bool canEdit(Reading r) => role != Role.family && r.authorId == currentUserId;

  String newId() => 'new-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  // ---------- Readings ----------

  void addReading(Reading r, {bool replaceToday = false}) {
    final list = _readings.putIfAbsent(r.patientId, () => <Reading>[]);
    if (replaceToday) {
      final t = today;
      list.removeWhere((x) => MockData.dateOnly(x.time) == t);
    }
    list.add(offline ? r.copyWith(pendingSync: true) : r);
    if (!offline) lastSync = DateTime.now();
    notifyListeners();
  }

  void updateReading(Reading r) {
    final list = _readings[r.patientId];
    if (list == null) return;
    final i = list.indexWhere((x) => x.id == r.id);
    if (i < 0) return;
    list[i] = offline ? r.copyWith(pendingSync: true) : r;
    if (!offline) lastSync = DateTime.now();
    notifyListeners();
  }

  void deleteReading(Reading r) {
    _readings[r.patientId]?.removeWhere((x) => x.id == r.id);
    notifyListeners();
  }

  // ---------- Settings ----------

  void setLang(AppLang v) {
    lang = v;
    notifyListeners();
  }

  void setKhmerDigits(bool v) {
    khmerDigits = v;
    notifyListeners();
  }

  void setReminderOn(bool v) {
    reminderOn = v;
    notifyListeners();
  }

  void setReminderTime(TimeOfDay t) {
    reminderTime = t;
    notifyListeners();
  }

  void selectPatient(String id) {
    activePatientId = id;
    notifyListeners();
  }

  // ---------- Links ----------

  void removeLink(String id) {
    links = links.where((p) => p.id != id).toList();
    notifyListeners();
  }

  void newInviteCode() {
    inviteCode = (100000 + _rng.nextInt(900000)).toString();
    inviteExpires = DateTime.now().add(const Duration(hours: 24));
    notifyListeners();
  }

  // ---------- Demo controls ----------

  void setRole(Role v) {
    role = v;
    activePatientId = 'sokha';
    notifyListeners();
  }

  void setScenario(OcrScenario v) {
    ocrScenario = v;
    notifyListeners();
  }

  void setOffline(bool v) {
    if (offline == v) return;
    offline = v;
    _syncTimer?.cancel();
    syncing = false;
    if (!v && pendingCount > 0) {
      syncing = true;
      _syncTimer = Timer(const Duration(milliseconds: 1600), () {
        for (final key in _readings.keys.toList()) {
          _readings[key] = _readings[key]!.map((r) => r.pendingSync ? r.copyWith(pendingSync: false) : r).toList();
        }
        syncing = false;
        lastSync = DateTime.now();
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void setRecordedToday(bool v) {
    final id = activePatientId;
    if (v) {
      if (!recordedToday(id)) {
        addReading(MockData.todayDemo(DateTime.now(), id, role == Role.caretaker ? 'mey' : 'self'));
      }
    } else {
      final t = today;
      _readings[id]?.removeWhere((x) => MockData.dateOnly(x.time) == t);
      notifyListeners();
    }
  }

  void setEmptyAccount(bool v) {
    if (emptyAccount == v) return;
    emptyAccount = v;
    if (v) {
      _emptyBackup = _readings['sokha'] ?? <Reading>[];
      _readings['sokha'] = <Reading>[];
    } else {
      _readings['sokha'] = <Reading>[..._emptyBackup, ...?_readings['sokha']];
      _emptyBackup = <Reading>[];
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Makes AppState available to every widget below it.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Read and rebuild when the state changes.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read once, without rebuilding (use inside callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
