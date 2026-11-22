// Record step 3: split-screen review (collapsible pinned photo dock on top,
// modern grouped form below), also used for "Type manually" and History edits.
// Two-tier validation (FR-06): hard stops block Save, soft flags warn.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'camera_screen.dart';

class _Issue {
  const _Issue(this.sev, this.text);
  final Severity sev;
  final String text;
}

class _Check {
  final Map<String, _Issue> hard = <String, _Issue>{};
  final Map<String, _Issue> soft = <String, _Issue>{};
  bool bpOrder = false;
  bool get hasErrors => hard.isNotEmpty;
  bool get flagged => soft.isNotEmpty;
  bool hasData = false;
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, this.initial, this.editing});

  /// Result from the OCR step (null = typed manually).
  final OcrResult? initial;

  /// Reading being edited from History (US-05).
  final Reading? editing;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pul = TextEditingController();
  final _glu = TextEditingController();
  final _note = TextEditingController();
  final Map<String, TextEditingController> _extra = {
    for (final f in Fields.custom) f.id: TextEditingController(),
  };

  GlucoseUnit _unit = GlucoseUnit.mgdl;
  final Map<String, Conf> _conf = <String, Conf>{};
  final Map<String, String> _ocrValues = <String, String>{};

  bool _bpPhoto = false;
  bool _gluPhoto = false;
  bool _photoCollapsed = false;
  DeviceMode _shown = DeviceMode.bp;
  bool _bpFailed = false;
  bool _gluFailed = false;
  bool _offlineOcr = false;
  bool _changed = false;
  bool _saving = false;
  bool _allowPop = false;

  // What the device screen really showed (the photo). OCR may misread it.
  String _truthSys = '128';
  String _truthDia = '82';
  String _truthPul = '74';
  String _truthGlu = '112';

  bool get _editing => widget.editing != null;
  bool get _hasPhoto => _bpPhoto || _gluPhoto;
  bool get _needsConfirm => !_allowPop && (_changed || (!_editing && _hasPhoto));
  VitalField get _gluField => _unit == GlucoseUnit.mgdl ? Fields.glu : Fields.gluMmol;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _sys.text = e.systolic?.toString() ?? '';
      _dia.text = e.diastolic?.toString() ?? '';
      _pul.text = e.pulse?.toString() ?? '';
      _glu.text = e.glucose == null ? '' : Fields.glu.fmt(e.glucose!);
      for (final f in Fields.custom) {
        final v = e.extra[f.id];
        _extra[f.id]!.text = v == null ? '' : f.fmt(v);
      }
      _note.text = e.note ?? '';
      _bpPhoto = e.photoBp;
      _gluPhoto = e.photoGlucose;
      _shown = (!_bpPhoto && _gluPhoto) ? DeviceMode.glucose : DeviceMode.bp;
      _truthSys = _sys.text;
      _truthDia = _dia.text;
      _truthPul = _pul.text;
      _truthGlu = _glu.text;
    } else if (widget.initial != null) {
      _apply(widget.initial!);
    }
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[_sys, _dia, _pul, _glu, _note, ..._extra.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctl(String id) {
    switch (id) {
      case 'sys':
        return _sys;
      case 'dia':
        return _dia;
      case 'pul':
        return _pul;
      case 'glu':
        return _glu;
      default:
        return _extra[id] ?? _note;
    }
  }

  void _setFromOcr(String id, String? v, Map<String, Conf> conf) {
    final c = _ctl(id);
    if (v != null) {
      c.text = v;
      _ocrValues[id] = v;
      final k = conf[id];
      if (k != null) {
        _conf[id] = k;
      } else {
        _conf.remove(id);
      }
    } else {
      _ocrValues.remove(id);
      _conf.remove(id);
    }
  }

  void _apply(OcrResult r) {
    _offlineOcr = r.offline;
    _photoCollapsed = false;
    if (r.mode == DeviceMode.bp) {
      _bpPhoto = true;
      _shown = DeviceMode.bp;
      _bpFailed = r.failed;
      _truthSys = '128';
      _truthDia = '82';
      _truthPul = '74';
      _setFromOcr('sys', r.systolic, r.conf);
      _setFromOcr('dia', r.diastolic, r.conf);
      _setFromOcr('pul', r.pulse, r.conf);
    } else {
      _gluPhoto = true;
      _shown = DeviceMode.glucose;
      _gluFailed = r.failed;
      _truthGlu = '112';
      _setFromOcr('glu', r.glucose, r.conf);
      if (!r.failed) _unit = r.unit;
    }
  }

  void _edited() {
    if (!_changed) {
      setState(() => _changed = true);
    } else {
      setState(() {});
    }
  }

  bool _fromOcr(String id) => _ocrValues[id] != null && _ocrValues[id] == _ctl(id).text.trim();

  // ---------- Validation ----------

  _Check _validate(L l) {
    final c = _Check();

    void check(VitalField f, String id) {
      final t = _ctl(id).text.trim();
      if (t.isEmpty) return;
      final v = double.tryParse(t);
      if (v == null || (!f.decimal && t.contains('.'))) {
        c.hard[id] = _Issue(Severity.error, l.numberOnly);
        return;
      }
      if (!f.inHardLimits(v)) {
        c.hard[id] = _Issue(
          Severity.error,
          l.hardRange(f.short(l.km), f.fmt(f.hardMin), f.fmt(f.hardMax), f.unit),
        );
        return;
      }
      final s = f.status(v);
      if (s == RangeStatus.high) {
        c.soft[id] = _Issue(Severity.warn, l.aboveNormal(f.fmt(f.normalMin), f.fmt(f.normalMax), f.unit));
      } else if (s == RangeStatus.low) {
        c.soft[id] = _Issue(Severity.warn, l.belowNormal(f.fmt(f.normalMin), f.fmt(f.normalMax), f.unit));
      }
    }

    check(Fields.sys, 'sys');
    check(Fields.dia, 'dia');
    check(Fields.pul, 'pul');
    check(_gluField, 'glu');
    for (final f in Fields.custom) {
      check(f, f.id);
    }

    final sysT = _sys.text.trim();
    final diaT = _dia.text.trim();
    if (sysT.isNotEmpty && diaT.isEmpty) {
      c.hard['dia'] = _Issue(Severity.error, l.requiredField(Fields.dia.short(l.km)));
    }
    if (diaT.isNotEmpty && sysT.isEmpty) {
      c.hard['sys'] = _Issue(Severity.error, l.requiredField(Fields.sys.short(l.km)));
    }

    final s = double.tryParse(sysT);
    final d = double.tryParse(diaT);
    if (s != null && d != null && !c.hard.containsKey('sys') && !c.hard.containsKey('dia') && s <= d) {
      c.bpOrder = true;
      c.hard['sys'] = _Issue(Severity.error, l.bpOrder);
      c.hard['dia'] = _Issue(Severity.error, l.bpOrder);
    }

    c.hasData = (sysT.isNotEmpty && diaT.isNotEmpty) || _glu.text.trim().isNotEmpty;
    return c;
  }

  void _swapBp() {
    HapticFeedback.selectionClick();
    final a = _sys.text;
    _sys.text = _dia.text;
    _dia.text = a;
    _edited();
  }

  // ---------- Actions ----------

  Future<void> _capture(DeviceMode mode) async {
    final r = await Navigator.of(context).push<OcrResult>(fastRoute<OcrResult>(CameraScreen(mode: mode, attach: true)));
    if (!mounted || r == null) return;
    setState(() {
      _apply(r);
      _changed = true;
    });
  }

  Future<bool> _confirmDiscard(L l) async {
    final ok = await showConfirmModal<bool>(
      context,
      title: l.discardTitle,
      message: l.discardBody,
      tone: Severity.warn,
      sideBySide: true,
      actions: [
        ModalAction<bool>(l.keepEditing, false, variant: BtnVariant.navy),
        ModalAction<bool>(l.discard, true, variant: BtnVariant.red),
      ],
    );
    return ok == true;
  }

  Future<void> _save(L l) async {
    final st = AppScope.read(context);
    final sys = int.tryParse(_sys.text.trim());
    final dia = int.tryParse(_dia.text.trim());
    final pul = int.tryParse(_pul.text.trim());
    var glu = double.tryParse(_glu.text.trim());
    if (glu != null && _unit == GlucoseUnit.mmol) glu = (glu * Fields.mmolFactor).roundToDouble();
    final extra = <String, double>{};
    for (final f in Fields.custom) {
      final x = double.tryParse(_extra[f.id]!.text.trim());
      if (x != null) extra[f.id] = x;
    }
    final noteText = _note.text.trim();
    final note = noteText.isEmpty ? null : noteText;
    final edited = _ocrValues.entries.any((e) => _ctl(e.key).text.trim() != e.value);

    if (_editing) {
      final e = widget.editing!;
      final method = e.method == EntryMethod.manual
          ? EntryMethod.manual
          : (_changed ? EntryMethod.ocrEdited : e.method);
      HapticFeedback.mediumImpact();
      st.updateReading(Reading(
        id: e.id,
        patientId: e.patientId,
        time: e.time,
        systolic: sys,
        diastolic: dia,
        pulse: pul,
        glucose: glu,
        extra: extra,
        note: note,
        authorId: e.authorId,
        method: method,
        photoBp: e.photoBp,
        photoGlucose: e.photoGlucose,
      ));
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
      return;
    }

    final method = _hasPhoto ? (edited ? EntryMethod.ocrEdited : EntryMethod.ocr) : EntryMethod.manual;
    final pid = st.activePatientId;
    final now = DateTime.now();
    var replace = false;
    final existing = st.todayReadingOf(pid);
    if (existing != null) {
      final choice = await showConfirmModal<String>(
        context,
        title: l.dupTitle,
        tone: Severity.warn,
        icon: Icons.schedule_rounded,
        body: _dupBody(l, existing, now, sys, dia, pul, glu),
        actions: [
          ModalAction<String>(l.dupReplace, 'replace', variant: BtnVariant.navy),
          ModalAction<String>(l.dupKeep, 'keep'),
          ModalAction<String>(l.cancel, 'cancel', height: 48),
        ],
      );
      if (!mounted || choice == null || choice == 'cancel') return;
      replace = choice == 'replace';
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _saving = true;
      _allowPop = true;
    });
    st.addReading(
      Reading(
        id: st.newId(),
        patientId: pid,
        time: now,
        systolic: sys,
        diastolic: dia,
        pulse: pul,
        glucose: glu,
        extra: extra,
        note: note,
        authorId: st.currentUserId,
        method: method,
        photoBp: _bpPhoto,
        photoGlucose: _gluPhoto,
      ),
      replaceToday: replace,
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _dupBody(L l, Reading old, DateTime now, int? sys, int? dia, int? pul, double? glu) {
    String vals(int? s, int? d, int? p, double? g) {
      final parts = <String>[];
      if (s != null && d != null) parts.add('$s/$d');
      if (p != null) parts.add('$p');
      if (g != null) parts.add(g.round().toString());
      return l.n(parts.join(' · '));
    }

    Widget row(String label, String value, {bool highlight = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: highlight ? C.navyTint.withValues(alpha: 0.35) : C.panelHeader,
          child: Row(
            children: [
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: T.cap.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlight ? C.navyBase : C.text2,
                    fontFeatures: T.tabular,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: T.bodyB.copyWith(fontSize: 15.5, fontFeatures: T.tabular),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.dupBody(l.time(old.time)), style: T.body.copyWith(color: C.text2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: C.border),
            borderRadius: D.radius,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              children: [
                row('${l.earlier} ${l.time(old.time)}', vals(old.systolic, old.diastolic, old.pulse, old.glucose)),
                const Divider(height: 1, color: C.divider),
                row('${l.newer} ${l.time(now)}', vals(sys, dia, pul, glu), highlight: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final st = AppScope.of(context);
    final v = _validate(l);
    final title = _editing ? l.editTitle : (_hasPhoto ? l.reviewTitle : l.manualTitle);
    final anyLow = _conf.entries.any((e) => e.value == Conf.low && _fromOcr(e.key));

    Widget? banner;
    if (v.hasErrors) {
      banner = StatusAlertBanner(
        severity: Severity.error,
        message: _hasPhoto ? l.errorBanner : l.errorBannerNoPhoto,
        action: v.bpOrder
            ? TactileButton(
                label: l.swapBp,
                icon: Icons.swap_vert_rounded,
                height: 44,
                fontSize: 15,
                expand: false,
                onPressed: _swapBp,
              )
            : null,
      );
    } else if (_offlineOcr) {
      banner = StatusAlertBanner(severity: Severity.warn, message: l.ocrOffline, icon: Icons.cloud_off_rounded);
    } else if (_bpFailed || _gluFailed) {
      banner = StatusAlertBanner(severity: Severity.warn, message: l.ocrFailed);
    } else if (anyLow) {
      banner = StatusAlertBanner(severity: Severity.warn, message: l.ocrLow);
    } else if (_hasPhoto && !_editing) {
      banner = StatusAlertBanner(severity: Severity.ok, message: l.ocrOk);
    } else if (!_editing) {
      banner = StatusAlertBanner(
        severity: Severity.info,
        message: l.manualInfo,
        action: TactileButton(
          label: l.usePhotoInstead,
          icon: Icons.photo_camera_outlined,
          height: 44,
          fontSize: 15,
          expand: false,
          onPressed: () => Navigator.of(context).pushReplacement(fastRoute<void>(const CameraScreen(mode: DeviceMode.bp))),
        ),
      );
    }

    final children = <Widget>[
      AnimatedSize(
        duration: D.animMed,
        curve: D.animCurve,
        alignment: Alignment.topCenter,
        child: banner ?? const SizedBox.shrink(),
      ),
      BoxedPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: gapped([
            _field(l, v, Fields.sys, 'sys', l.example('120')),
            _field(l, v, Fields.dia, 'dia', l.example('80')),
            _field(l, v, Fields.pul, 'pul', l.example('72')),
          ], 16),
        ),
      ),
      _glucoseCard(l, v),
      if (Fields.custom.isNotEmpty) ...[
        _separator(l.extraFields),
        BoxedPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: gapped([
              for (final f in Fields.custom) _field(l, v, f, f.id, l.example(f.id == 'wt' ? '62.5' : '0')),
            ], 16),
          ),
        ),
      ],
      BoxedPanel(child: _noteField(l)),
      AnimatedSize(
        duration: D.animMed,
        curve: D.animCurve,
        alignment: Alignment.topCenter,
        child: (v.flagged && !v.hasErrors)
            ? StatusAlertBanner(severity: Severity.info, message: l.flagNotice)
            : const SizedBox.shrink(),
      ),
    ];

    final canSave = !v.hasErrors && v.hasData && !_saving;

    return PopScope<Object?>(
      canPop: !_needsConfirm,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmDiscard(l);
        if (ok && context.mounted) {
          setState(() => _allowPop = true);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: C.canvas,
        body: Column(
          children: [
            AppHeader(title: title, showBack: true),
            if (st.role == Role.caretaker) _caretakerContext(l, st),
            if (_hasPhoto) _photoPane(l),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: gapped(children, 14),
              ),
            ),
            _footer(l, v, canSave),
          ],
        ),
      ),
    );
  }

  Widget _caretakerContext(L l, AppState st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: C.warnBg,
        border: Border(bottom: BorderSide(color: C.warnDivider)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: C.warnDivider),
            ),
            child: const Icon(Icons.person_outline_rounded, size: 16, color: C.warnText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l.recordingFor} ${st.activePatient.name.of(l.km)}',
              style: T.bodySm.copyWith(color: C.warnText, fontWeight: FontWeight.w700, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPane(L l) {
    final paneH = (MediaQuery.of(context).size.height * 0.21).clamp(142.0, 198.0).toDouble();
    final lowPulse = _conf['pul'] == Conf.low;

    Widget thumb({
      required bool selected,
      required Widget child,
      required VoidCallback onTap,
      required String label,
      bool emptySlot = false,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: emptySlot ? const Color(0xFF1F2937) : C.lcd,
          borderRadius: D.radius,
          child: InkWell(
            borderRadius: D.radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: AnimatedContainer(
              duration: D.animFast,
              curve: D.animCurve,
              width: 66,
              height: 62,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? C.frameGreen : const Color(0x3DFFFFFF),
                  width: selected ? 2.5 : 1.25,
                ),
                borderRadius: D.radius,
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      );
    }

    final lcdSmall = TextStyle(
      fontFamily: T.lcdFamily,
      fontSize: 18,
      color: C.lcdText,
      fontFeatures: T.tabular,
    );

    return Container(
      decoration: const BoxDecoration(
        color: C.cameraDeck,
        border: Border(bottom: BorderSide(color: Color(0x26FFFFFF))),
        boxShadow: [BoxShadow(color: Color(0x1F0F172A), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          AnimatedSize(
            duration: D.animMed,
            curve: D.animCurve,
            alignment: Alignment.topCenter,
            child: _photoCollapsed
                ? const SizedBox.shrink()
                : SizedBox(
                    height: paneH,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _zoom,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: C.cameraBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x26FFFFFF)),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: FittedBox(
                                    child: _shown == DeviceMode.bp
                                        ? DeviceLcd(
                                            mode: DeviceMode.bp,
                                            sys: _truthSys,
                                            dia: _truthDia,
                                            pul: _truthPul,
                                            dimPulse: lowPulse,
                                          )
                                        : DeviceLcd(
                                            mode: DeviceMode.glucose,
                                            glu: _truthGlu,
                                            unit: _unit == GlucoseUnit.mgdl ? 'mg/dL' : 'mmol/L',
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              thumb(
                                selected: _shown == DeviceMode.bp && _bpPhoto,
                                label: l.modeBp,
                                emptySlot: !_bpPhoto,
                                onTap: () {
                                  if (_bpPhoto) {
                                    setState(() => _shown = DeviceMode.bp);
                                  } else {
                                    _capture(DeviceMode.bp);
                                  }
                                },
                                child: _bpPhoto
                                    ? Text('BP', style: lcdSmall)
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.favorite_outline_rounded, color: C.onDark, size: 19),
                                          Text(
                                            l.bp,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: T.capSm.copyWith(color: C.onDark, fontSize: 11.5, height: 1.3),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 8),
                              thumb(
                                selected: _shown == DeviceMode.glucose && _gluPhoto,
                                label: l.modeGlu,
                                emptySlot: !_gluPhoto,
                                onTap: () {
                                  if (_gluPhoto) {
                                    setState(() => _shown = DeviceMode.glucose);
                                  } else {
                                    _capture(DeviceMode.glucose);
                                  }
                                },
                                child: _gluPhoto
                                    ? Text(_truthGlu, style: lcdSmall)
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.water_drop_outlined, color: C.onDark, size: 19),
                                          Text(
                                            l.glucose,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: T.capSm.copyWith(color: C.onDark, fontSize: 11.5, height: 1.3),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: _DockActionPill(
                    label: l.zoom,
                    icon: Icons.zoom_in_rounded,
                    onTap: _zoom,
                  ),
                ),
                if (!_editing) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DockActionPill(
                      label: l.retake,
                      icon: Icons.refresh_rounded,
                      onTap: () => _capture(_shown),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: _shown == DeviceMode.bp ? l.modeBp : l.modeGlu,
                  excludeSemantics: true,
                  child: Material(
                    color: const Color(0xFF1F2937),
                    borderRadius: D.radius,
                    child: InkWell(
                      borderRadius: D.radius,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _photoCollapsed = !_photoCollapsed);
                      },
                      child: Container(
                        width: 44,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: D.radius,
                          border: Border.all(color: const Color(0x2EFFFFFF)),
                        ),
                        child: Icon(
                          _photoCollapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _zoom() {
    HapticFeedback.selectionClick();
    showPhotoDialog(
      context,
      mode: _shown,
      sys: _truthSys,
      dia: _truthDia,
      pul: _truthPul,
      glu: _truthGlu,
      unit: _unit == GlucoseUnit.mgdl ? 'mg/dL' : 'mmol/L',
    );
  }

  Widget? _badge(L l, String id, _Check v) {
    if (v.hard.containsKey(id)) return StatusBadge(label: l.badgeWrong, tone: BadgeTone.crit, icon: Icons.error_rounded);
    final fromOcr = _fromOcr(id);
    if (fromOcr && _conf[id] == Conf.low) {
      return StatusBadge(label: l.badgeCheck, tone: BadgeTone.warn, icon: Icons.warning_rounded);
    }
    if (fromOcr) return const StatusBadge(label: 'OCR', tone: BadgeTone.ok, icon: Icons.check_rounded);
    if (_ocrValues.containsKey(id) && _ctl(id).text.trim().isNotEmpty) {
      return StatusBadge(label: l.badgeEdited, icon: Icons.edit_outlined);
    }
    return null;
  }

  FieldState _state(String id, _Check v) {
    if (v.hard.containsKey(id)) return FieldState.error;
    if (_fromOcr(id)) return _conf[id] == Conf.low ? FieldState.low : FieldState.ok;
    return FieldState.none;
  }

  Widget? _messages(L l, String id, _Check v) {
    final hints = <Widget>[];
    final hard = v.hard[id];
    if (hard != null) {
      hints.add(FieldHint(severity: Severity.error, text: hard.text, icon: Icons.error_rounded));
    } else {
      if (_fromOcr(id) && _conf[id] == Conf.low) {
        hints.add(FieldHint(severity: Severity.warn, text: l.verifyField, icon: Icons.info_outline_rounded));
      }
      final soft = v.soft[id];
      if (soft != null) hints.add(FieldHint(severity: Severity.warn, text: soft.text));
    }
    if (hints.isEmpty) return null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: gapped(hints, 3));
  }

  Widget _field(L l, _Check v, VitalField f, String id, String hint) {
    Widget? badge = _badge(l, id, v);
    if (badge == null && f.optional) badge = StatusBadge(label: l.optional);
    return VitalInputGroup(
      label: f.label(l.km),
      controller: _ctl(id),
      unit: f.unit,
      decimal: f.decimal,
      hint: hint,
      badge: badge,
      state: _state(id, v),
      message: _messages(l, id, v),
      onChanged: (_) => _edited(),
    );
  }

  Widget _glucoseCard(L l, _Check v) {
    final f = _gluField;
    Widget? badge = _badge(l, 'glu', v);
    if (badge == null && _glu.text.trim().isEmpty && _bpPhoto) badge = StatusBadge(label: l.badgeEmpty);
    return BoxedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_gluPhoto && !_editing) ...[
            TactileButton(
              label: l.scanGlucose,
              icon: Icons.photo_camera_outlined,
              variant: BtnVariant.navy,
              height: 50,
              fontSize: 15.5,
              onPressed: () => _capture(DeviceMode.glucose),
            ),
            const SizedBox(height: 14),
          ],
          VitalInputGroup(
            label: f.label(l.km),
            controller: _glu,
            unit: f.unit,
            decimal: true,
            hint: _gluPhoto ? l.example(_unit == GlucoseUnit.mgdl ? '110' : '6.1') : l.orTypeHere,
            badge: badge,
            state: _state('glu', v),
            message: _messages(l, 'glu', v),
            onChanged: (_) => _edited(),
          ),
          const SizedBox(height: 10),
          SegmentedToggle<GlucoseUnit>(
            semanticLabel: l.glucoseUnit,
            height: 44,
            options: const [SegOption(GlucoseUnit.mgdl, 'mg/dL'), SegOption(GlucoseUnit.mmol, 'mmol/L')],
            selected: _unit,
            onChanged: (u) => setState(() {
              _unit = u;
              _changed = true;
            }),
          ),
        ],
      ),
    );
  }

  Widget _separator(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Expanded(child: Divider(color: C.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text, style: T.cap.copyWith(fontWeight: FontWeight.w700, color: C.hint)),
          ),
          const Expanded(child: Divider(color: C.border, height: 1)),
        ],
      ),
    );
  }

  Widget _noteField(L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.noteLabel, style: T.label),
        const SizedBox(height: 6),
        TextField(
          controller: _note,
          minLines: 3,
          maxLines: 5,
          maxLength: 200,
          onChanged: (_) => _edited(),
          style: T.body,
          cursorColor: C.focus,
          decoration: InputDecoration(
            hintText: l.noteHint,
            hintStyle: T.body.copyWith(color: C.muted),
            filled: true,
            fillColor: C.inputUnit,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: const OutlineInputBorder(
              borderRadius: D.radius,
              borderSide: BorderSide(color: C.border, width: 1.25),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: D.radius,
              borderSide: BorderSide(color: C.focus, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer(L l, _Check v, bool canSave) {
    String? why;
    if (v.hasErrors) {
      why = l.fixRedFirst;
    } else if (!v.hasData) {
      why = l.enterSomething;
    }
    return Container(
      decoration: const BoxDecoration(
        color: C.panel,
        border: Border(top: BorderSide(color: C.divider)),
        boxShadow: D.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TactileButton(
                label: l.save,
                icon: Icons.check_rounded,
                variant: BtnVariant.green,
                height: 58,
                fontSize: 17.5,
                loading: _saving,
                onPressed: canSave ? () => _save(l) : null,
              ),
              AnimatedSize(
                duration: D.animFast,
                curve: D.animCurve,
                child: why != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          why,
                          textAlign: TextAlign.center,
                          style: T.cap.copyWith(
                            color: v.hasErrors ? C.errText : C.text2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockActionPill extends StatelessWidget {
  const _DockActionPill({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF1F2937),
        borderRadius: D.radius,
        child: InkWell(
          borderRadius: D.radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: D.radius,
              border: Border.all(color: const Color(0x2EFFFFFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.button.copyWith(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
