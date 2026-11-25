// Local-only store (no backend). It plays the role the REST API will play
// later: every read goes through canView(), every write through canRecord() /
// canEditReading(), so the screens already behave as they will with the real
// server (NFR-03). Data and settings are saved on the phone.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/reports_repository.dart';
import '../data/dates.dart';
import '../data/seed.dart';
import '../data/types.dart';
import '../l10n/strings.dart';

const _storageKey = 'ehealth-demo-v1';

/// Bottom tabs. Their order and icons never change; roles only hide tabs.
enum AppTab { home, record, history, reports, settings }

final _rand = math.Random();

String newId(String prefix) =>
    '$prefix-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_rand.nextInt(1 << 30).toRadixString(36)}';

class AppState extends ChangeNotifier {
  AppState({
    bool persist = true,
    bool enableLiveApi = true,
    ApiClient? api,
    ReportsRepository? reportsRepo,
  })  : _persist = persist,
        _enableLiveApi = enableLiveApi,
        api = api ?? ApiClient() {
    this.reportsRepo = reportsRepo ?? ApiReportsRepository(this.api);
  }

  final bool _persist;
  final bool _enableLiveApi;
  final ApiClient api;
  late final ReportsRepository reportsRepo;

  bool ready = false;
  DataState data = makeSeed();
  Settings settings = const Settings();
  String? userId;
  String? token;
  String? selectedPatientId;

  /// Current bottom tab (not saved).
  AppTab tab = AppTab.home;

  Timer? _saveTimer;
  I18n? _i18n;
  bool _disposed = false;

  // ---------- load & save ----------

  Future<void> load() async {
    if (_persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final saved = jsonDecode(raw) as Map<String, dynamic>;
          final savedData = saved['data'] as Map<String, dynamic>?;
          final dataOk = savedData?['version'] == seedVersion;
          if (dataOk) {
            data = DataState.fromJson(savedData!);
            userId = saved['userId'] as String?;
            token = saved['token'] as String?;
            selectedPatientId = saved['selectedPatientId'] as String?;
          }
          settings = Settings.fromJson(saved['settings'] as Map<String, dynamic>? ?? {});
        }
      } catch (_) {
        // corrupted storage → start from demo data
      }
    }
    ready = true;
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    if (!_persist) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _storageKey,
          jsonEncode({
            'data': data.toJson(),
            'settings': settings.toJson(),
            'userId': userId,
            'token': token,
            'selectedPatientId': selectedPatientId,
          }),
        );
      } catch (_) {
        // saving is best effort in this demo
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---------- derived ----------

  I18n get i18n {
    final cached = _i18n;
    if (cached != null && cached.lang == settings.lang && cached.numerals == settings.numerals) return cached;
    return _i18n = I18n(settings.lang, settings.numerals);
  }

  AppUser? userById(String? id) {
    for (final u in data.users) {
      if (u.id == id) return u;
    }
    return null;
  }

  AppUser? get user => userById(userId);

  /// Patients this user may see (themselves for a patient).
  List<AppUser> get patients {
    final u = user;
    if (u == null) return const [];
    if (u.role == Role.patient) return [u];
    final ids = {
      for (final l in data.links)
        if (l.userId == u.id && l.status == LinkStatus.active) l.patientId,
    };
    return data.users.where((x) => ids.contains(x.id)).toList();
  }

  /// Patient currently shown in History / Reports / Record.
  AppUser? get patient {
    final ps = patients;
    if (ps.isEmpty) return null;
    return ps.firstWhere((p) => p.id == selectedPatientId, orElse: () => ps.first);
  }

  bool canView(String patientId) => patients.any((p) => p.id == patientId);

  bool canRecord(String patientId) {
    final u = user;
    if (u == null) return false;
    if (u.role == Role.patient) return u.id == patientId;
    return u.role == Role.caretaker && canView(patientId);
  }

  /// A patient can edit any of their own readings; a caretaker only the ones they entered.
  bool canEditReading(Reading r) {
    final u = user;
    if (u == null) return false;
    if (u.role == Role.patient) return r.patientId == u.id;
    if (u.role == Role.caretaker) return r.enteredBy == u.id && canView(r.patientId);
    return false;
  }

  /// Newest first.
  List<Reading> readingsOf(String patientId) {
    if (!canView(patientId)) return const [];
    return data.readings.where((r) => r.patientId == patientId).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Reading? todayReadingOf(String patientId) {
    final now = DateTime.now();
    for (final r in readingsOf(patientId)) {
      if (isSameDay(r.takenAt, now)) return r;
    }
    return null;
  }

  Reading? readingById(String id) {
    for (final r in data.readings) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<AppTab> get visibleTabs {
    final r = user?.role;
    final canRecordRole = r == Role.patient || r == Role.caretaker;
    return [for (final t in AppTab.values) if (t != AppTab.record || canRecordRole) t];
  }

  // ---------- actions ----------

  void signIn(String id) {
    userId = id;
    token = null;
    selectedPatientId = null;
    tab = AppTab.home;
    _changed();
    final target = userById(id);
    if (_enableLiveApi && target != null) {
      unawaited(_fetchDevToken(id, target.role));
    }
  }

  Future<void> _fetchDevToken(String id, Role role) async {
    try {
      final res = await api.devLogin(role);
      if (_disposed || userId != id) return;
      token = res.token;
      _changed();
      unawaited(_hydrateFromApi(id, res.token));
    } catch (_) {
      // API not running — standalone demo mode continues without a token.
    }
  }

  Future<void> _hydrateFromApi(String expectedUserId, String activeToken) async {
    try {
      final fields = await api.listCustomFields(token: activeToken);
      if (_disposed || userId != expectedUserId) return;
      data = data.copyWith(fields: fields);
      _changed();
    } catch (_) {
      // Keep local demo fields if offline.
    }

    for (final p in patients) {
      try {
        final live = await api.listPatientReadings(p.id, token: activeToken);
        if (_disposed || userId != expectedUserId) return;
        if (live.isNotEmpty) {
          data = data.copyWith(readings: [
            for (final r in data.readings)
              if (r.patientId != p.id) r,
            ...live,
          ]);
          _changed();
        }
      } catch (_) {
        // Keep local demo readings for unlinked/offline patients.
      }
    }
  }

  void signOut() {
    userId = null;
    token = null;
    selectedPatientId = null;
    _changed();
  }

  void selectPatient(String id) {
    selectedPatientId = id;
    _changed();
  }

  void setTab(AppTab t) {
    if (tab == t) return;
    tab = t;
    notifyListeners();
  }

  void setSettings(Settings s) {
    settings = s;
    _changed();
  }

  void saveReading(Reading reading, {String? replaceId}) {
    final existed = data.readings.any((r) => r.id == reading.id);
    data = data.copyWith(readings: [
      for (final r in data.readings)
        if (r.id != reading.id && r.id != replaceId) r,
      reading,
    ]);
    _changed();

    final activeToken = token;
    if (_enableLiveApi && activeToken != null) {
      unawaited(_syncSaveReading(reading, existed: existed, replaceId: replaceId, activeToken: activeToken));
    }
  }

  Future<void> _syncSaveReading(
    Reading reading, {
    required bool existed,
    required String? replaceId,
    required String activeToken,
  }) async {
    try {
      if (replaceId != null) {
        await api.deleteReading(reading.patientId, replaceId, token: activeToken);
      }
      final saved = existed
          ? await api.updateReading(reading, token: activeToken)
          : await api.createReading(reading, token: activeToken);
      if (_disposed || token != activeToken) return;
      data = data.copyWith(readings: [
        for (final r in data.readings)
          if (r.id != reading.id && r.id != saved.id) r,
        saved,
      ]);
      _changed();
    } catch (_) {
      // Offline or unlinked → optimistic reading remains stored locally on phone.
    }
  }

  /// Returns the removed reading so it can be restored (Undo).
  Reading? deleteReading(String id) {
    final r = readingById(id);
    data = data.copyWith(readings: data.readings.where((x) => x.id != id).toList());
    _changed();
    final activeToken = token;
    if (_enableLiveApi && activeToken != null && r != null) {
      unawaited(api.deleteReading(r.patientId, r.id, token: activeToken).catchError((Object _) {}));
    }
    return r;
  }

  void restoreReading(Reading r) => saveReading(r);

  void addNote(String patientId, String text) {
    final u = user;
    if (u == null) return;
    data = data.copyWith(notes: [
      ...data.notes,
      DoctorNote(id: newId('n'), patientId: patientId, authorId: u.id, text: text, createdAt: DateTime.now()),
    ]);
    _changed();
  }

  void addLink(String patientId, String userId, LinkRelation relation,
      {required bool initiatedByPatient, required LinkStatus status}) {
    data = data.copyWith(links: [
      ...data.links,
      Link(
        id: newId('l'),
        patientId: patientId,
        userId: userId,
        relation: relation,
        status: status,
        initiatedByPatient: initiatedByPatient,
        createdAt: DateTime.now(),
      ),
    ]);
    _changed();
  }

  void approveLink(String id) {
    data = data.copyWith(links: [for (final l in data.links) l.id == id ? l.copyWith(status: LinkStatus.active) : l]);
    _changed();
  }

  void removeLink(String id) {
    data = data.copyWith(links: data.links.where((l) => l.id != id).toList());
    _changed();
  }

  void resetData() {
    data = makeSeed();
    selectedPatientId = null;
    _changed();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Watches the state: the caller rebuilds on every change.
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state once, for callbacks.
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
