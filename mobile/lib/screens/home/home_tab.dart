// Home tab (FR-13, US-14, US-19, US-13). One screen, many states:
// not recorded / recorded today / caretaker switcher / family read-only /
// offline waiting to sync / empty new account.

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../common/chart_builders.dart';
import '../common/labels.dart';
import '../record/record_flow.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onOpenReports, required this.onOpenLinks});

  final VoidCallback onOpenReports;
  final VoidCallback onOpenLinks;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _pickerOpen = false;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);
    final patient = st.activePatient;
    final readings = st.readings;
    final today = st.todayReading;
    final empty = readings.isEmpty;
    final isCaretaker = st.role == Role.caretaker;
    final isFamily = st.role == Role.family;

    final cards = <Widget>[
      if (empty && st.role == Role.patient) Text(l.welcome(patient.firstName.of(l.km)), style: T.title),
      if (today != null) _recordedPanel(l, st, today, patient) else _notRecordedPanel(l, st, patient),
      if (today == null && !empty) _latestPanel(l, readings.first, patient),
      if (st.offline) StatusAlertBanner(severity: Severity.info, message: l.offlineInfo),
      if (empty) _emptyPanel(l, isFamily ? l.noReadingsYetBy(patient.firstName.of(l.km)) : l.noReadingsYet),
      if (empty && st.role == Role.patient) _linkPanel(l),
      if (!empty && st.doctorNote != null) _notePanel(l, st.doctorNote!),
      if (!empty) _trendPanel(l, st, readings),
    ];

    return Column(
      children: [
        if (isCaretaker) _caretakerBanner(l, st),
        if (isFamily) _familyBanner(l, patient.name.of(l.km)),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView(padding: const EdgeInsets.all(16), children: gapped(cards, 16)),
              ),
              if (_pickerOpen && isCaretaker) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _pickerOpen = false),
                    child: const ColoredBox(color: C.scrimLight),
                  ),
                ),
                Positioned(left: 12, right: 12, top: 6, child: _picker(l, st)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Today ----------

  String _statusTitle(L l, AppState st, PatientInfo p) =>
      st.role == Role.caretaker ? l.todayStatusFor(p.name.of(l.km)) : l.todayStatus;

  Widget _notRecordedPanel(L l, AppState st, PatientInfo p) {
    final other = st.role != Role.patient;
    return BoxedPanel(
      accent: PanelAccent.warn,
      title: _statusTitle(l, st, p),
      trailing: st.role == Role.caretaker ? null : Text(l.dayY(st.today), style: T.cap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.warning_amber_rounded, size: 26, color: C.warnText)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  other ? l.notRecordedName(p.firstName.of(l.km)) : l.notRecorded,
                  style: T.big.copyWith(color: C.warnText),
                ),
              ),
            ],
          ),
          if (st.canRecord) ...[
            const SizedBox(height: 14),
            TactileButton(
              label: st.role == Role.caretaker ? l.recordFor(p.name.of(l.km)) : l.recordCta,
              icon: Icons.add_circle_outline,
              variant: BtnVariant.green,
              height: 64,
              fontSize: 18,
              onPressed: () => openRecord(context),
            ),
          ],
          if (st.role == Role.patient) ...[
            const SizedBox(height: 10),
            Text(l.recordHint, style: T.cap),
          ],
        ],
      ),
    );
  }

  Widget _recordedPanel(L l, AppState st, Reading r, PatientInfo p) {
    return BoxedPanel(
      accent: PanelAccent.ok,
      title: _statusTitle(l, st, p),
      trailing: r.pendingSync
          ? StatusBadge(label: l.pendingSync, tone: BadgeTone.warn, icon: Icons.schedule)
          : (st.role == Role.caretaker ? null : Text(l.dayY(st.today), style: T.cap)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: C.okBorder, borderRadius: D.radius),
                child: const Icon(Icons.check, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l.recordedAt(l.time(r.time)), style: T.big.copyWith(color: C.okText))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: C.divider), bottom: BorderSide(color: C.divider)),
            ),
            child: VitalRow(reading: r, big: true),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(l.recordedBy(authorLabel(l, r, p)), style: T.cap)),
              MethodBadge(method: r.method),
            ],
          ),
          if (r.pendingSync) ...[
            const SizedBox(height: 10),
            StatusAlertBanner(severity: Severity.warn, message: l.savedOnPhone),
          ],
          if (st.canRecord) ...[
            const SizedBox(height: 12),
            TactileButton(label: l.addAnother, icon: Icons.add, height: 48, fontSize: 16, onPressed: () => openRecord(context)),
          ],
        ],
      ),
    );
  }

  Widget _latestPanel(L l, Reading r, PatientInfo p) {
    return BoxedPanel(
      title: l.latest,
      trailing: Text(l.dayTime(r.time), style: T.cap),
      footer: Row(
        children: [
          Expanded(child: Text(l.recordedBy(authorLabel(l, r, p)), style: T.cap)),
          MethodBadge(method: r.method),
          if (r.hasPhoto) ...[
            const SizedBox(width: 8),
            _LinkText(text: l.viewPhoto, onTap: () => showPhotoDialog(context, reading: r)),
          ],
        ],
      ),
      child: VitalRow(reading: r),
    );
  }

  Widget _notePanel(L l, DoctorNote note) {
    return BoxedPanel(
      accent: PanelAccent.memo,
      leadingIcon: Icons.description_outlined,
      title: l.doctorNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text.of(l.km), style: T.body),
          const SizedBox(height: 8),
          Text('${note.author.of(l.km)} · ${l.dayY(note.time)} · ${l.time(note.time)}', style: T.cap),
        ],
      ),
    );
  }

  Widget _trendPanel(L l, AppState st, List<Reading> readings) {
    final end = st.today;
    final start = DateTime(end.year, end.month, end.day - 6);
    final week = readings.where((r) => !r.time.isBefore(start)).toList();
    return BoxedPanel(
      title: l.trend7,
      trailing: Text('mmHg', style: T.cap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bpChart(l, week, start, end, height: 180, today: end),
          const SizedBox(height: 8),
          bpLegend(l, extra: l.daysOf(l.dayRange(start, end))),
          const SizedBox(height: 12),
          TactileButton(label: l.fullReport, trailingIcon: Icons.chevron_right, height: 48, fontSize: 16, onPressed: widget.onOpenReports),
        ],
      ),
    );
  }

  Widget _emptyPanel(L l, String title) {
    return BoxedPanel(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: C.panelHeader, border: Border.all(color: C.border), borderRadius: D.radius),
            child: const Icon(Icons.bar_chart, size: 30, color: C.text2),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: T.h.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(l.noReadingsHint, textAlign: TextAlign.center, style: T.cap.copyWith(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _linkPanel(L l) {
    return BoxedPanel(
      leadingIcon: Icons.link,
      title: l.linkCareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.linkCareHint, style: T.bodySm),
          const SizedBox(height: 12),
          TactileButton(label: l.openLinks, trailingIcon: Icons.chevron_right, height: 48, fontSize: 16, onPressed: widget.onOpenLinks),
        ],
      ),
    );
  }

  // ---------- Caretaker & family context ----------

  Widget _caretakerBanner(L l, AppState st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: C.warnBg, border: Border(bottom: BorderSide(color: C.warnBorder, width: 2))),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 22, color: C.warnText),
          const SizedBox(width: 8),
          Text(l.recordingFor, style: T.bodySm.copyWith(color: C.warnText, fontWeight: FontWeight.w700, height: 1.65)),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              label: '${l.recordingFor} ${st.activePatient.name.of(l.km)}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => setState(() => _pickerOpen = !_pickerOpen),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: D.grayGradient,
                    borderRadius: D.radius,
                    border: Border.all(color: _pickerOpen ? C.focus : C.borderInput, width: _pickerOpen ? 2 : 1),
                    boxShadow: _pickerOpen ? const [BoxShadow(color: C.focusHalo, spreadRadius: 3)] : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          st.activePatient.name.of(l.km),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.bodyB,
                        ),
                      ),
                      Icon(_pickerOpen ? Icons.expand_less : Icons.expand_more, color: C.text),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _picker(L l, AppState st) {
    final pts = st.visiblePatients;
    return Container(
      decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.borderStrong), borderRadius: D.radius, boxShadow: D.modalShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(color: C.panelHeader, border: Border(bottom: BorderSide(color: C.border))),
              child: Text(l.choosePatient(pts.length), style: T.cap.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final p in pts) _pickerRow(l, st, p),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(color: C.warnBg, border: Border(top: BorderSide(color: C.warnDivider))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.info_outline, size: 16, color: C.warnText)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.checkPatientName, style: T.cap.copyWith(color: C.warnText))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerRow(L l, AppState st, PatientInfo p) {
    final selected = p.id == st.activePatientId;
    final today = st.todayReadingOf(p.id);
    return Semantics(
      button: true,
      selected: selected,
      label: p.name.of(l.km),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          st.selectPatient(p.id);
          setState(() => _pickerOpen = false);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: EdgeInsets.fromLTRB(selected ? 10 : 14, 8, 14, 8),
          decoration: BoxDecoration(
            color: selected ? C.navyTint : null,
            border: Border(
              left: BorderSide(color: selected ? C.navyBase : Colors.transparent, width: 4),
              top: const BorderSide(color: C.divider),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 24, child: selected ? const Icon(Icons.check, color: C.navyBase) : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name.of(l.km), style: T.bodyB.copyWith(fontSize: 17)),
                    const SizedBox(height: 2),
                    today == null
                        ? StatusBadge(label: l.notRecordedShort, tone: BadgeTone.warn, icon: Icons.warning_amber_rounded)
                        : StatusBadge(label: l.recordedShort(l.time(today.time)), tone: BadgeTone.ok, icon: Icons.check),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _familyBanner(L l, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: C.infoBg, border: Border(bottom: BorderSide(color: C.infoBorder, width: 2))),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 22, color: C.infoText),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: l.viewing(name), style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' · '),
                TextSpan(text: l.readOnly),
              ]),
              style: T.bodySm.copyWith(color: C.infoText, fontWeight: FontWeight.w600, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              text,
              style: T.cap.copyWith(color: C.link, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: C.link),
            ),
          ),
        ),
      ),
    );
  }
}
