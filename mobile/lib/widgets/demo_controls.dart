// Dev Role Switcher (from claude/ui-component-contract.md): lets anyone on
// the team flip roles and states during demos. Set kShowDevStrip = false
// for a clean build. Labels stay in English on purpose (developer tool).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'segmented_toggle.dart';
import 'tactile_button.dart';

const bool kShowDevStrip = true;

String roleName(Role r) {
  switch (r) {
    case Role.patient:
      return 'Patient';
    case Role.caretaker:
      return 'Caretaker';
    case Role.family:
      return 'Family';
  }
}

class DevStrip extends StatelessWidget {
  const DevStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    return Semantics(
      button: true,
      label: 'Developer demo controls',
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF1E293B),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            showDemoSheet(context);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEV',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${roleName(st.role)}${st.offline ? ' · Offline' : ''} · OCR: ${st.ocrScenario.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2E8F0),
                      height: 1.35,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: D.radiusPill,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Demo',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.tune_rounded, size: 13, color: Colors.white),
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
}

Future<void> showDemoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: C.scrim,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Align(
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
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: C.navyTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune_rounded, size: 20, color: C.navyBase),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Demo controls (developers)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: C.text,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const DemoControls(),
                  const SizedBox(height: 16),
                  TactileButton(
                    label: 'Done',
                    variant: BtnVariant.navy,
                    height: 50,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The switches themselves (also shown at the bottom of Links & Settings).
class DemoControls extends StatelessWidget {
  const DemoControls({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    const sectionLabel = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: C.text2,
      height: 1.4,
    );

    Widget toggleRow(String text, bool value, ValueChanged<bool> onChanged, {bool enabled = true}) {
      return InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: enabled ? C.text : C.muted,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                activeTrackColor: C.navyBase,
                onChanged: enabled
                    ? (v) {
                        HapticFeedback.selectionClick();
                        onChanged(v);
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Role', style: sectionLabel),
        const SizedBox(height: 6),
        SegmentedToggle<Role>(
          height: 44,
          fontSize: 14,
          options: Role.values.map((r) => SegOption<Role>(r, roleName(r))).toList(),
          selected: st.role,
          onChanged: st.setRole,
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: C.panelHeader,
            borderRadius: D.radius,
            border: Border.all(color: C.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              children: [
                toggleRow(
                  'Recorded today (active patient)',
                  st.recordedToday(st.activePatientId),
                  st.setRecordedToday,
                  enabled: !st.emptyAccount,
                ),
                const Divider(height: 1, color: C.divider),
                toggleRow(
                  'Offline (readings wait to sync)',
                  st.offline,
                  st.setOffline,
                ),
                const Divider(height: 1, color: C.divider),
                toggleRow(
                  'New account — no readings (patient)',
                  st.emptyAccount,
                  st.setEmptyAccount,
                  enabled: st.role == Role.patient,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Simulated OCR outcome', style: sectionLabel),
        const SizedBox(height: 6),
        SegmentedToggle<OcrScenario>(
          height: 44,
          fontSize: 13,
          options: const [
            SegOption(OcrScenario.clear, 'Clear'),
            SegOption(OcrScenario.partial, 'Partial'),
            SegOption(OcrScenario.failed, 'Failed'),
            SegOption(OcrScenario.misread, 'Misread'),
          ],
          selected: st.ocrScenario,
          onChanged: st.setScenario,
        ),
        const SizedBox(height: 14),
        TactileButton(
          label: 'Reset sample data',
          icon: Icons.restart_alt_rounded,
          height: 48,
          fontSize: 15,
          onPressed: st.resetDemo,
        ),
      ],
    );
  }
}
