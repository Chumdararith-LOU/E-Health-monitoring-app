// One form for new, OCR-prefilled and edited readings (FR-04..FR-08).
// Error prevention: safe limits block impossible values; normal ranges only
// warn. Errors appear after leaving a field or pressing Save, never while the
// user is still typing.

import 'package:flutter/material.dart';

import '../../data/dates.dart';
import '../../data/ranges.dart';
import '../../data/types.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';

/// What the OCR step hands to the form (the OCR → Readings contract).
class Prefill {
  const Prefill({this.systolic, this.diastolic, this.pulse, this.glucose, this.photoUri, this.lowConfidence = const {}});
  final double? systolic, diastolic, pulse, glucose;
  final String? photoUri;

  /// Fields the OCR was unsure about → highlighted for checking.
  final Set<String> lowConfidence;

  Prefill withPhoto(String uri) => Prefill(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        glucose: glucose,
        photoUri: uri,
        lowConfidence: lowConfidence,
      );
}

enum _Unit { mgdl, mmol }

const _core = ['systolic', 'diastolic', 'pulse', 'glucose'];

MeasureKey _key(String k) => MeasureKey.values.byName(k);

String _fmtInit(double? n) => n == null ? '' : (n == n.roundToDouble() ? '${n.toInt()}' : '$n');

/// null = empty, NaN = not a number.
double? _parse(String s) {
  final x = fromKhmerDigits(s).trim().replaceAll(',', '.');
  if (x.isEmpty) return null;
  return double.tryParse(x) ?? double.nan;
}

class _Check {
  final errors = <String, String>{};
  final warnings = <String, String>{};
  final out = <MeasureKey, double>{};
  final extra = <String, double>{};
  String? form;
  bool get ok => errors.isEmpty && form == null;
}

class ReadingFormScreen extends StatefulWidget {
  const ReadingFormScreen({super.key, this.readingId, this.prefill, this.method = EntryMethod.manual, this.patientId});
  final String? readingId;
  final Prefill? prefill;
  final EntryMethod method;
  final String? patientId;

  @override
  State<ReadingFormScreen> createState() => _ReadingFormScreenState();
}

class _ReadingFormScreenState extends State<ReadingFormScreen> {
  late final AppState _st = AppScope.read(context);
  late final Reading? _existing = widget.readingId == null ? null : _st.readingById(widget.readingId!);
  late final List<CustomField> _fields = _st.data.fields;
  late final Map<String, String> _initial;
  final _ctrl = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  final _note = TextEditingController();
  final _touched = <String>{};
  _Unit _unit = _Unit.mgdl;
  int _dayOffset = 0;
  bool _submitted = false;
  bool _done = false;

  String get _patientId => _existing?.patientId ?? widget.patientId ?? _st.patient?.id ?? '';

  @override
  void initState() {
    super.initState();
    final e = _existing;
    final p = widget.prefill;
    _initial = {
      'systolic': _fmtInit(e?.systolic ?? p?.systolic),
      'diastolic': _fmtInit(e?.diastolic ?? p?.diastolic),
      'pulse': _fmtInit(e?.pulse ?? p?.pulse),
      'glucose': _fmtInit(e?.glucose ?? p?.glucose),
      for (final f in _fields) f.id: _fmtInit(e?.extra[f.id]),
    };
    _initial.forEach((k, v) {
      _ctrl[k] = TextEditingController(text: v);
      _focus[k] = FocusNode()
        ..addListener(() {
          if (!_focus[k]!.hasFocus && mounted) setState(() => _touched.add(k));
        });
    });
    _note.text = e?.note ?? '';
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  String _v(String k) => _ctrl[k]!.text;

  bool get _dirty =>
      _initial.entries.any((e) => _v(e.key) != e.value) ||
      _note.text != (_existing?.note ?? '') ||
      (_existing == null && widget.prefill != null);

  // ---------- validation ----------

  _Check _validate(I18n i18n) {
    final t = i18n.t;
    final c = _Check();
    for (final k in _core) {
      final mk = _key(k);
      final m = measures[mk]!;
      var n = _parse(_v(k));
      if (n == null) continue;
      if (n.isNaN) {
        c.errors[k] = t('errRange', {'min': m.safeMin, 'max': m.safeMax});
        continue;
      }
      if (mk == MeasureKey.glucose && _unit == _Unit.mmol) {
        final mmolMin = (m.safeMin / mmolFactor * 10).round() / 10;
        final mmolMax = (m.safeMax / mmolFactor * 10).round() / 10;
        n = (n * mmolFactor).roundToDouble();
        if (n < m.safeMin || n > m.safeMax) {
          c.errors[k] = t('errRange', {'min': i18n.n(mmolMin, 1), 'max': i18n.n(mmolMax, 1)});
          continue;
        }
      } else if (n < m.safeMin || n > m.safeMax || (mk != MeasureKey.glucose && n != n.roundToDouble())) {
        c.errors[k] = t('errRange', {'min': m.safeMin, 'max': m.safeMax});
        continue;
      }
      c.out[mk] = n;
      final lvl = levelOf(mk, n);
      if (lvl != null && lvl != Level.normal) {
        c.warnings[k] = t('outsideNormal', {'min': m.normalMin, 'max': m.normalMax});
      }
    }

    for (final f in _fields) {
      final n = _parse(_v(f.id));
      if (n == null) continue;
      if (n.isNaN || n < f.min || n > f.max) {
        c.errors[f.id] = t('errRange', {'min': f.min, 'max': f.max});
      } else {
        final p = [1, 10, 100, 1000][f.decimals.clamp(0, 3)];
        c.extra[f.id] = (n * p).round() / p;
      }
    }

    final hasSys = _v('systolic').trim().isNotEmpty;
    final hasDia = _v('diastolic').trim().isNotEmpty;
    if (hasSys != hasDia) c.errors[hasSys ? 'diastolic' : 'systolic'] = t('errBpPair');
    final s = c.out[MeasureKey.systolic], d = c.out[MeasureKey.diastolic];
    if (s != null && d != null && s <= d) c.errors['diastolic'] = t('errSysDia');

    if (!hasSys && !hasDia && _v('glucose').trim().isEmpty && !c.errors.containsKey('glucose')) {
      c.form = t('errEmpty');
    }
    return c;
  }

  // ---------- save ----------

  Future<void> _save(_Check c) async {
    setState(() => _submitted = true);
    final user = _st.user;
    if (!c.ok || user == null) {
      for (final k in [..._core, for (final f in _fields) f.id]) {
        if (c.errors.containsKey(k)) {
          _focus[k]!.requestFocus();
          break;
        }
      }
      return;
    }
    final i18n = _st.i18n;
    final t = i18n.t;
    final e = _existing;
    final now = DateTime.now();
    final takenAt = e?.takenAt ?? addDays(now, _dayOffset);
    final note = _note.text.trim();
    final reading = Reading(
      id: e?.id ?? newId('r'),
      patientId: _patientId,
      takenAt: takenAt,
      systolic: c.out[MeasureKey.systolic],
      diastolic: c.out[MeasureKey.diastolic],
      pulse: c.out[MeasureKey.pulse],
      glucose: c.out[MeasureKey.glucose],
      extra: c.extra,
      enteredBy: e?.enteredBy ?? user.id,
      method: e?.method ?? widget.method,
      note: note.isEmpty ? null : note,
      photoUri: e?.photoUri ?? widget.prefill?.photoUri,
      updatedAt: e == null ? null : now,
    );

    String? replaceId;
    if (e == null && isMorning(takenAt)) {
      // FR-05: one morning reading per day is expected
      Reading? dup;
      for (final r in _st.readingsOf(_patientId)) {
        if (isSameDay(r.takenAt, takenAt) && isMorning(r.takenAt)) {
          dup = r;
          break;
        }
      }
      if (dup != null) {
        final choice = await ask(
          context,
          title: t('dupTitle'),
          body: t('dupBody', {'time': i18n.time(dup.takenAt)}),
          icon: Mdi.calendarAlert,
          buttons: [
            DialogBtn('replace', t('dupReplace'), BtnVariant.primary),
            DialogBtn('both', t('dupKeepBoth')),
            DialogBtn('cancel', t('cancel'), BtnVariant.ghost),
          ],
        );
        if (choice != 'replace' && choice != 'both') return;
        if (choice == 'replace') replaceId = dup.id;
      }
    }

    if (!mounted) return;
    setState(() => _done = true);
    _st.saveReading(reading, replaceId: replaceId);
    showToast(context, '${e != null ? t('updated') : t('saved')} · ${t('lvl_${readingLevel(reading).name}')}');
    if (e != null) {
      Navigator.of(context).pop();
    } else {
      goToTab(context, AppTab.home);
    }
  }

  Future<void> _confirmLeave() async {
    final t = _st.i18n.t;
    final c = await ask(
      context,
      title: t('discardTitle'),
      body: t('discardBody'),
      icon: Mdi.alertOutline,
      iconColor: C.low,
      buttons: [
        DialogBtn('keep', t('keepEditing'), BtnVariant.primary),
        DialogBtn('discard', t('discard')),
      ],
    );
    if (c == 'discard' && mounted) {
      setState(() => _done = true);
      Navigator.of(context).pop();
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final e = _existing;
    final c = _validate(i18n);
    final lowConf = widget.prefill?.lowConfidence ?? const {};
    final photo = e?.photoUri ?? widget.prefill?.photoUri;
    final patientUser = st.userById(_patientId);

    bool show(String k) => _submitted || _touched.contains(k);
    String? errorFor(String k) => show(k) ? c.errors[k] : null;
    String? warnFor(String k) {
      if (lowConf.contains(k) && _v(k) == _initial[k]) return t('checkThis');
      return show(k) ? c.warnings[k] : null;
    }

    Widget numField(String k, String label, String hint, String unit, {bool decimals = false}) => AppField(
          label: label,
          hint: hint,
          large: true,
          controller: _ctrl[k]!,
          focusNode: _focus[k],
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          maxLength: 6,
          error: errorFor(k),
          warning: warnFor(k),
          placeholder: '–',
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          right: AppText(unit, variant: TextVariant.caption, color: C.textMuted),
        );

    final title = e != null
        ? t('formEdit')
        : widget.method == EntryMethod.ocr
            ? t('formFromPhoto')
            : t('formNew');

    return PopScope(
      canPop: !(_dirty && !_done),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: StackPage(
        title: title,
        child: AppScreen(
          footer: [
            if (_submitted && !c.ok) AppBanner(kind: BannerKind.error, text: c.form ?? t('errFixBelow')),
            AppButton(icon: Mdi.contentSave, label: t('saveReading'), onPressed: () => _save(c)),
          ],
          children: [
            if (st.user?.role != Role.patient && patientUser != null)
              Wrap(spacing: Sp.sm, children: [
                AppText('${t('recordingFor')}:', color: C.textMuted),
                AppText(i18n.name(patientUser), weight: W.semibold),
              ]),
            if (photo != null)
              AppCard(padding: const EdgeInsets.all(Sp.sm), children: [
                AppPhoto(uri: photo, label: t('photo')),
                if (widget.method == EntryMethod.ocr && e == null)
                  AppBanner(icon: Mdi.eyeCheckOutline, text: t('formFromPhotoHint')),
              ]),
            AppCard(children: [
              Row(children: [
                Expanded(child: AppText(t('bp'), variant: TextVariant.heading)),
                const AppText('mmHg', variant: TextVariant.caption, color: C.textMuted),
              ]),
              Gap(gap: Sp.md, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: numField('systolic', t('m_systolic'), t('mHint_systolic'), 'SYS')),
                Expanded(child: numField('diastolic', t('m_diastolic'), t('mHint_diastolic'), 'DIA')),
              ]),
              Gap(gap: Sp.md, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: numField('pulse', t('m_pulse'), t('mHint_pulse'), 'bpm')),
                const Expanded(child: SizedBox.shrink()),
              ]),
            ]),
            AppCard(children: [
              AppText(t('m_glucose'), variant: TextVariant.heading),
              AppText(t('glucoseUnit'), variant: TextVariant.label, color: C.textMuted),
              Segmented<_Unit>(
                label: t('glucoseUnit'),
                value: _unit,
                onChanged: (u) => setState(() => _unit = u),
                options: [SegOption(_Unit.mgdl, t('unitMgdl')), SegOption(_Unit.mmol, t('unitMmol'))],
              ),
              numField('glucose', t('m_glucose'), t('mHint_glucose'), _unit == _Unit.mgdl ? 'mg/dL' : 'mmol/L',
                  decimals: _unit == _Unit.mmol),
            ]),
            if (_fields.isNotEmpty)
              AppCard(children: [
                AppText(t('extraFields'), variant: TextVariant.heading),
                for (final f in _fields)
                  numField(f.id, '${i18n.name(f)} (${t('optional')})', '${i18n.n(f.min)}–${i18n.n(f.max)} ${f.unit}', f.unit,
                      decimals: f.decimals > 0),
              ]),
            AppCard(children: [
              AppText(t('takenOn'), variant: TextVariant.heading),
              if (e != null)
                AppText('${i18n.date(e.takenAt)} · ${i18n.time(e.takenAt)}')
              else ...[
                Segmented<int>(
                  label: t('takenOn'),
                  value: _dayOffset,
                  onChanged: (v) => setState(() => _dayOffset = v),
                  options: [SegOption(0, t('today')), SegOption(-1, t('yesterday'))],
                ),
                AppText('${i18n.date(addDays(DateTime.now(), _dayOffset))} · ${i18n.time(DateTime.now())}',
                    variant: TextVariant.label, color: C.textMuted),
              ],
              AppField(
                label: '${t('note')} (${t('optional')})',
                controller: _note,
                placeholder: t('notePlaceholder'),
                multiline: true,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
