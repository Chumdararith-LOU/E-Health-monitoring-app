// Links & Settings (FR-03, US-03, US-15, US-17, NFR-02).
// Patients manage invite codes and linked people; caretakers and family
// see which patients they follow. Everyone gets reminder + settings.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class LinksTab extends StatefulWidget {
  const LinksTab({super.key, required this.onSignedOut});

  final VoidCallback onSignedOut;

  @override
  State<LinksTab> createState() => _LinksTabState();
}

class _LinksTabState extends State<LinksTab> {
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy(String code) async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _remove(L l, AppState st, LinkedPerson p) async {
    final name = p.name.of(l.km);
    final ok = await showConfirmModal<bool>(
      context,
      title: l.removeTitle(name),
      tone: Severity.error,
      icon: Icons.person_remove_outlined,
      sideBySide: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.panelHeader,
          border: Border.all(color: C.border),
          borderRadius: D.radius,
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(name, style: T.bodyB),
            StatusBadge(label: '${l.linkRole(p.role)} · ${l.linkCapability(p.role)}'),
          ],
        ),
      ),
      message: l.removeBody(name),
      actions: [
        ModalAction<bool>(l.cancel, false),
        ModalAction<bool>(l.removeAccess, true, variant: BtnVariant.red),
      ],
    );
    if (ok == true) st.removeLink(p.id);
  }

  Future<void> _signOut(L l, AppState st) async {
    final ok = await showConfirmModal<bool>(
      context,
      title: l.signOutTitle,
      message: l.signOutBody,
      tone: Severity.warn,
      icon: Icons.logout_rounded,
      sideBySide: true,
      actions: [
        ModalAction<bool>(l.cancel, false),
        ModalAction<bool>(l.signOut, true, variant: BtnVariant.navy),
      ],
    );
    if (ok == true) {
      st.resetDemo();
      widget.onSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);
    final isPatient = st.role == Role.patient;

    final children = <Widget>[
      if (isPatient) _invitePanel(l, st),
      if (isPatient) _peoplePanel(l, st),
      if (!isPatient) _patientsPanel(l, st),
      if (isPatient) _reminderPanel(l, st),
      _settingsPanel(l, st),
      if (kShowDevStrip)
        const BoxedPanel(
          leadingIcon: Icons.tune_rounded,
          title: 'Demo controls (developers)',
          child: DemoControls(),
        ),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: gapped(children, 14),
    );
  }

  // ---------- Invite code (US-03) ----------

  Widget _invitePanel(L l, AppState st) {
    final code = st.inviteCode;
    final pretty = '${code.substring(0, 3)} ${code.substring(3)}';
    return BoxedPanel(
      leadingIcon: Icons.person_add_alt_1_rounded,
      title: l.inviteCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.inviteHint, style: T.bodySm.copyWith(color: C.text2)),
          const SizedBox(height: 14),
          Semantics(
            label: '${l.inviteCode} ${code.split('').join(' ')}',
            excludeSemantics: true,
            child: CustomPaint(
              painter: _DashedRRectPainter(
                color: C.navyBase.withValues(alpha: 0.45),
                radius: 16,
              ),
              child: Container(
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.infoBg,
                  borderRadius: D.radiusLg,
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.n(pretty),
                      style: const TextStyle(
                        fontFamily: T.f,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 7,
                        color: C.navyDark,
                        height: 1.3,
                        fontFeatures: T.tabular,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: _Countdown(expires: st.inviteExpires)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TactileButton(
                  label: _copied ? l.copied : l.copyCode,
                  icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                  variant: _copied ? BtnVariant.green : BtnVariant.navy,
                  height: 50,
                  fontSize: 15.5,
                  onPressed: () => _copy(code),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TactileButton(
                  label: l.newCode,
                  icon: Icons.refresh_rounded,
                  height: 50,
                  fontSize: 15.5,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    st.newInviteCode();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Linked people ----------

  IconData _roleIcon(LinkRole r) {
    switch (r) {
      case LinkRole.doctor:
        return Icons.medical_services_outlined;
      case LinkRole.caretaker:
        return Icons.favorite_outline_rounded;
      case LinkRole.family:
        return Icons.visibility_outlined;
    }
  }

  Widget _avatar(IconData icon) => Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: C.navyTint,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: C.navyBase, size: 21),
      );

  Widget _peoplePanel(L l, AppState st) {
    final people = st.links;
    final rows = <Widget>[];
    for (var i = 0; i < people.length; i++) {
      final p = people[i];
      rows.add(Container(
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: C.divider))),
        child: Row(
          children: [
            _avatar(_roleIcon(p.role)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name.of(l.km), style: T.bodyB),
                  const SizedBox(height: 3),
                  StatusBadge(label: '${l.linkRole(p.role)} · ${l.linkCapability(p.role)}'),
                  const SizedBox(height: 3),
                  Text(l.linkedSince(l.dayY(p.since)), style: T.capSm),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TactileButton(
              label: l.removeAccess,
              variant: BtnVariant.dangerOutline,
              height: 44,
              fontSize: 14,
              expand: false,
              horizontalPadding: 12,
              onPressed: () => _remove(l, st, p),
            ),
          ],
        ),
      ));
    }
    return BoxedPanel(
      leadingIcon: Icons.group_outlined,
      title: l.whoCanSee(people.length),
      padding: EdgeInsets.zero,
      child: rows.isEmpty
          ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noLinks, style: T.bodySm.copyWith(color: C.text2)))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  Widget _patientsPanel(L l, AppState st) {
    final cap = st.role == Role.caretaker ? l.linkCapability(LinkRole.caretaker) : l.linkCapability(LinkRole.family);
    final pts = st.visiblePatients;
    final rows = <Widget>[];
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      rows.add(Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: C.divider))),
        child: Row(
          children: [
            _avatar(Icons.person_outline_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name.of(l.km), style: T.bodyB),
                  Text(l.n(p.phone), style: T.capSm),
                  const SizedBox(height: 4),
                  StatusBadge(label: cap, tone: BadgeTone.info),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    return BoxedPanel(
      leadingIcon: Icons.group_outlined,
      title: l.patientsYouSee,
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  // ---------- Reminder (US-17) ----------

  Widget _reminderPanel(L l, AppState st) {
    final on = st.reminderOn;
    return BoxedPanel(
      leadingIcon: Icons.notifications_outlined,
      title: l.reminder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: C.panelHeader,
            borderRadius: D.radius,
            child: InkWell(
              borderRadius: D.radius,
              onTap: () {
                HapticFeedback.selectionClick();
                st.setReminderOn(!on);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: D.radius,
                  border: Border.all(color: C.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(l.reminderOn, style: T.label)),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: on,
                      activeTrackColor: C.saveBase,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        st.setReminderOn(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(l.reminderTime, style: T.label.copyWith(color: on ? C.text : C.muted)),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            enabled: on,
            label: '${l.reminderTime} ${l.tod(st.reminderTime)}',
            excludeSemantics: true,
            child: AnimatedOpacity(
              duration: D.animFast,
              opacity: on ? 1.0 : 0.45,
              child: Material(
                color: C.inputUnit,
                borderRadius: D.radius,
                child: InkWell(
                  borderRadius: D.radius,
                  onTap: on
                      ? () async {
                          HapticFeedback.selectionClick();
                          final t = await showTimePicker(context: context, initialTime: st.reminderTime);
                          if (t != null) st.setReminderTime(t);
                        }
                      : null,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: C.border),
                      borderRadius: D.radius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: C.navyBase, size: 21),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.tod(st.reminderTime),
                            style: T.input.copyWith(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: C.text2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(l.previewLabel, style: T.cap.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          AnimatedOpacity(
            duration: D.animFast,
            opacity: on ? 1.0 : 0.45,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.panelHeader,
                border: Border.all(color: C.border),
                borderRadius: D.radiusLg,
                boxShadow: D.panelShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: D.navyGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.appName,
                                style: T.capSm.copyWith(color: C.text, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(l.tod(st.reminderTime), style: T.capSm),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(l.reminderMsg, style: T.bodySm.copyWith(color: C.text2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l.reminderSkip, style: T.cap),
        ],
      ),
    );
  }

  // ---------- Settings ----------

  Widget _settingsPanel(L l, AppState st) {
    late final Bi name;
    late final String phone;
    late final String role;
    switch (st.role) {
      case Role.patient:
        name = MockData.sokha.name;
        phone = MockData.sokha.phone;
        role = l.rolePatient;
        break;
      case Role.caretaker:
        name = MockData.caretakerName;
        phone = '097 555 220';
        role = l.roleCaretaker;
        break;
      case Role.family:
        name = MockData.familyName;
        phone = '088 555 417';
        role = l.roleFamily;
        break;
    }

    return BoxedPanel(
      leadingIcon: Icons.settings_outlined,
      title: l.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.language, style: T.label),
          const SizedBox(height: 6),
          SegmentedToggle<AppLang>(
            semanticLabel: l.language,
            options: const [SegOption(AppLang.km, 'ខ្មែរ'), SegOption(AppLang.en, 'English')],
            selected: st.lang,
            onChanged: st.setLang,
          ),
          const SizedBox(height: 16),
          Text(l.numerals, style: T.label),
          const SizedBox(height: 6),
          SegmentedToggle<bool>(
            semanticLabel: l.numerals,
            fontSize: 14,
            options: [SegOption(true, l.kmDigitsOpt), SegOption(false, l.arDigitsOpt)],
            selected: st.khmerDigits,
            onChanged: st.setKhmerDigits,
          ),
          const SizedBox(height: 6),
          Text(l.numeralsHint, style: T.cap),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: C.panelHeader,
              border: Border.all(color: C.border),
              borderRadius: D.radius,
            ),
            child: Row(
              children: [
                _avatar(Icons.person_outline_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.of(l.km), style: T.bodyB),
                      Text('${l.n(phone)} · $role', style: T.cap),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TactileButton(
            label: l.signOut,
            icon: Icons.logout_rounded,
            height: 50,
            fontSize: 15.5,
            onPressed: () => _signOut(l, st),
          ),
        ],
      ),
    );
  }
}

/// Live 24-hour countdown for the invite code. Only this badge rebuilds
/// every second.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.expires});
  final DateTime expires;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final left = widget.expires.difference(DateTime.now());
    if (left.isNegative) {
      return StatusBadge(label: l.expired, tone: BadgeTone.crit, icon: Icons.timer_off_outlined);
    }
    String two(int v) => v.toString().padLeft(2, '0');
    final text = '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
    return StatusBadge(label: l.expiresIn(l.n(text)), tone: BadgeTone.info, icon: Icons.schedule_rounded);
  }
}

/// Lightweight dashed rounded border for the hero 6-digit invite code card.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + dash) > metric.length ? metric.length : d + dash;
        canvas.drawPath(metric.extractPath(d, end), paint);
        d = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
