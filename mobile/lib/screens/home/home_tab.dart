// Home tab (FR-13, US-14, US-19, US-13). One screen, many states:
// not recorded / recorded today / caretaker switcher / family read-only /
// offline waiting to sync / empty new account.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../common/chart_builders.dart';
import '../common/labels.dart';
import '../record/record_flow.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onOpenReports, required this.onOpenLinks});

  final VoidCallback onOpenReports;
  final VoidCallback onOpenLinks;

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

    final statusKey = ValueKey<String>(
      '${patient.id}_${today?.time.millisecondsSinceEpoch ?? 'none'}_${today?.pendingSync ?? false}_${st.role.name}',
    );

    final cards = <Widget>[
      if (empty && st.role == Role.patient)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l.welcome(patient.firstName.of(l.km)), style: T.title),
        ),
      AnimatedSwitcher(
        duration: D.animMed,
        switchInCurve: D.animCurve,
        switchOutCurve: D.animCurve,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SizeTransition(
            sizeFactor: anim,
            axisAlignment: -1,
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: statusKey,
          child: today != null
              ? _recordedPanel(context, l, st, today, patient)
              : _notRecordedPanel(context, l, st, patient),
        ),
      ),
      if (today == null && !empty) _latestPanel(context, l, readings.first, patient),
      if (st.offline) StatusAlertBanner(severity: Severity.info, message: l.offlineInfo),
      if (empty) _emptyPanel(l, isFamily ? l.noReadingsYetBy(patient.firstName.of(l.km)) : l.noReadingsYet),
      if (empty && st.role == Role.patient) _linkPanel(l),
      if (!empty && st.doctorNote != null) _notePanel(l, st.doctorNote!),
      if (!empty) _trendPanel(l, st, readings),
    ];

    return Column(
      children: [
        if (isCaretaker) _caretakerBanner(context, l, st),
        if (isFamily) _familyBanner(l, patient.name.of(l.km)),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: gapped(cards, 14),
          ),
        ),
      ],
    );
  }

  // ---------- Today ----------

  String _statusTitle(L l, AppState st, PatientInfo p) =>
      st.role == Role.caretaker ? l.todayStatusFor(p.name.of(l.km)) : l.todayStatus;

  Widget _notRecordedPanel(BuildContext context, L l, AppState st, PatientInfo p) {
    final other = st.role != Role.patient;
    return BoxedPanel(
      accent: PanelAccent.warn,
      leadingIcon: Icons.wb_sunny_outlined,
      title: _statusTitle(l, st, p),
      trailing: st.role == Role.caretaker
          ? null
          : Text(l.dayY(st.today), style: T.cap.copyWith(fontWeight: FontWeight.w600)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: C.warnBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.warnDivider),
                ),
                child: const Icon(Icons.schedule_rounded, size: 22, color: C.warnText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  other ? l.notRecordedName(p.firstName.of(l.km)) : l.notRecorded,
                  style: T.big.copyWith(color: C.warnText),
                ),
              ),
            ],
          ),
          if (st.canRecord) ...[
            const SizedBox(height: 16),
            TactileButton(
              label: st.role == Role.caretaker ? l.recordFor(p.name.of(l.km)) : l.recordCta,
              icon: Icons.add_circle_outline_rounded,
              variant: BtnVariant.green,
              height: 60,
              fontSize: 17.5,
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

  Widget _recordedPanel(BuildContext context, L l, AppState st, Reading r, PatientInfo p) {
    return BoxedPanel(
      accent: PanelAccent.ok,
      leadingIcon: Icons.check_circle_outline_rounded,
      title: _statusTitle(l, st, p),
      trailing: r.pendingSync
          ? StatusBadge(label: l.pendingSync, tone: BadgeTone.warn, icon: Icons.schedule_rounded)
          : (st.role == Role.caretaker
              ? null
              : Text(l.dayY(st.today), style: T.cap.copyWith(fontWeight: FontWeight.w600))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: C.okBorder, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.recordedAt(l.time(r.time)),
                  style: T.big.copyWith(color: C.okText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: C.panelHeader,
              borderRadius: D.radius,
              border: Border.all(color: C.divider),
            ),
            child: VitalRow(reading: r, big: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l.recordedBy(authorLabel(l, r, p)), style: T.cap)),
              MethodBadge(method: r.method),
            ],
          ),
          if (r.pendingSync) ...[
            const SizedBox(height: 12),
            StatusAlertBanner(severity: Severity.warn, message: l.savedOnPhone),
          ],
          if (st.canRecord) ...[
            const SizedBox(height: 14),
            TactileButton(
              label: l.addAnother,
              icon: Icons.add_rounded,
              height: 48,
              fontSize: 15.5,
              onPressed: () => openRecord(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _latestPanel(BuildContext context, L l, Reading r, PatientInfo p) {
    return BoxedPanel(
      leadingIcon: Icons.monitor_heart_outlined,
      title: l.latest,
      trailing: Text(l.dayTime(r.time), style: T.cap),
      footer: Row(
        children: [
          Expanded(child: Text(l.recordedBy(authorLabel(l, r, p)), style: T.cap)),
          MethodBadge(method: r.method),
          if (r.hasPhoto) ...[
            const SizedBox(width: 8),
            _PhotoPill(
              text: l.viewPhoto,
              onTap: () => showPhotoDialog(context, reading: r),
            ),
          ],
        ],
      ),
      child: VitalRow(reading: r),
    );
  }

  Widget _notePanel(L l, DoctorNote note) {
    return BoxedPanel(
      accent: PanelAccent.memo,
      leadingIcon: Icons.medical_information_outlined,
      title: l.doctorNote,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text.of(l.km), style: T.body),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: C.memoIcon),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${note.author.of(l.km)} · ${l.dayY(note.time)} · ${l.time(note.time)}',
                  style: T.cap.copyWith(color: C.memoIcon),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendPanel(L l, AppState st, List<Reading> readings) {
    final end = st.today;
    final start = DateTime(end.year, end.month, end.day - 6);
    final week = readings.where((r) => !r.time.isBefore(start)).toList();
    return BoxedPanel(
      leadingIcon: Icons.show_chart_rounded,
      title: l.trend7,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: C.inputUnit,
          borderRadius: D.radiusPill,
        ),
        child: Text('mmHg', style: T.capSm.copyWith(fontWeight: FontWeight.w600)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bpChart(l, week, start, end, height: 186, today: end),
          const SizedBox(height: 10),
          bpLegend(l, extra: l.daysOf(l.dayRange(start, end))),
          const SizedBox(height: 14),
          TactileButton(
            label: l.fullReport,
            trailingIcon: Icons.chevron_right_rounded,
            height: 48,
            fontSize: 15.5,
            onPressed: onOpenReports,
          ),
        ],
      ),
    );
  }

  Widget _emptyPanel(L l, String title) {
    return BoxedPanel(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: C.navyTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bar_chart_rounded, size: 32, color: C.navyBase),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: T.h.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          Text(l.noReadingsHint, textAlign: TextAlign.center, style: T.cap.copyWith(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _linkPanel(L l) {
    return BoxedPanel(
      leadingIcon: Icons.link_rounded,
      title: l.linkCareTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.linkCareHint, style: T.bodySm.copyWith(color: C.text2)),
          const SizedBox(height: 14),
          TactileButton(
            label: l.openLinks,
            trailingIcon: Icons.chevron_right_rounded,
            height: 48,
            fontSize: 15.5,
            onPressed: onOpenLinks,
          ),
        ],
      ),
    );
  }

  // ---------- Caretaker & family context ----------

  Widget _caretakerBanner(BuildContext context, L l, AppState st) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: C.warnBg,
        border: Border(bottom: BorderSide(color: C.warnDivider)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: C.warnDivider),
            ),
            child: const Icon(Icons.person_outline_rounded, size: 19, color: C.warnText),
          ),
          const SizedBox(width: 10),
          Text(
            l.recordingFor,
            style: T.bodySm.copyWith(color: C.warnText, fontWeight: FontWeight.w700, height: 1.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: '${l.recordingFor} ${st.activePatient.name.of(l.km)}',
              excludeSemantics: true,
              child: Material(
                color: C.panel,
                borderRadius: D.radiusPill,
                child: InkWell(
                  borderRadius: D.radiusPill,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showPatientPicker(context, l, st);
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                    decoration: BoxDecoration(
                      borderRadius: D.radiusPill,
                      border: Border.all(color: C.warnBorder.withValues(alpha: 0.45)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0F0F172A), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            st.activePatient.name.of(l.km),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.bodyB.copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: C.text2, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPatientPicker(BuildContext context, L l, AppState st) {
    final pts = st.visiblePatients;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: C.scrim,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: const BoxDecoration(
                color: C.panel,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                boxShadow: D.modalShadow,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: C.borderStrong,
                            borderRadius: D.radiusPill,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(l.choosePatient(pts.length), style: T.big),
                      const SizedBox(height: 12),
                      ...gapped(
                        pts.map((p) => _pickerRow(ctx, l, st, p)).toList(),
                        10,
                      ),
                      const SizedBox(height: 14),
                      StatusAlertBanner(
                        severity: Severity.warn,
                        icon: Icons.info_outline_rounded,
                        message: l.checkPatientName,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pickerRow(BuildContext ctx, L l, AppState st, PatientInfo p) {
    final selected = p.id == st.activePatientId;
    final today = st.todayReadingOf(p.id);

    return Semantics(
      button: true,
      selected: selected,
      label: p.name.of(l.km),
      child: Material(
        color: selected ? C.navyTint.withValues(alpha: 0.55) : C.panelHeader,
        borderRadius: D.radius,
        child: InkWell(
          borderRadius: D.radius,
          onTap: () {
            HapticFeedback.lightImpact();
            st.selectPatient(p.id);
            Navigator.of(ctx).pop();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: D.radius,
              border: Border.all(
                color: selected ? C.navyBase : C.border,
                width: selected ? 1.75 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? C.navyBase : C.panel,
                    shape: BoxShape.circle,
                    border: selected ? null : Border.all(color: C.border),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.person_outline_rounded,
                    color: selected ? Colors.white : C.text2,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name.of(l.km), style: T.bodyB.copyWith(fontSize: 16.5)),
                      const SizedBox(height: 4),
                      today == null
                          ? StatusBadge(
                              label: l.notRecordedShort,
                              tone: BadgeTone.warn,
                              icon: Icons.schedule_rounded,
                            )
                          : StatusBadge(
                              label: l.recordedShort(l.time(today.time)),
                              tone: BadgeTone.ok,
                              icon: Icons.check_rounded,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _familyBanner(L l, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: C.infoBg,
        border: Border(bottom: BorderSide(color: Color(0xFFBAE6FD))),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: C.infoBorder.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.visibility_outlined, size: 17, color: C.infoText),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: l.viewing(name), style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: ' · '),
                TextSpan(text: l.readOnly),
              ]),
              style: T.bodySm.copyWith(color: C.infoText, fontWeight: FontWeight.w600, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPill extends StatelessWidget {
  const _PhotoPill({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: C.navyTint,
        borderRadius: D.radiusPill,
        child: InkWell(
          borderRadius: D.radiusPill,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_outlined, size: 16, color: C.navyBase),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: T.cap.copyWith(
                    color: C.navyBase,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
