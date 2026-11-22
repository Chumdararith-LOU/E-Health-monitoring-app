// Dev Role Switcher (from claude/ui-component-contract.md): lets anyone on
// the team flip roles and states during demos. Set kShowDevStrip = false
// for a clean build. Labels stay in English on purpose (developer tool).

import 'package:flutter/material.dart';

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDemoSheet(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: const BoxDecoration(color: C.devBg, border: Border(bottom: BorderSide(color: C.devBorder))),
          child: Row(
            children: [
              const Icon(Icons.developer_mode, size: 16, color: C.text),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'DEV · ${roleName(st.role)}${st.offline ? ' · offline' : ''} · OCR: ${st.ocrScenario.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text, height: 1.4),
                ),
              ),
              const Text('tap to change ▾', style: TextStyle(fontSize: 12, color: C.text, height: 1.4)),
            ],
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
    backgroundColor: C.panel,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Demo controls (developers)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.5)),
              const SizedBox(height: 12),
              const DemoControls(),
              const SizedBox(height: 12),
              TactileButton(label: 'Done', variant: BtnVariant.navy, height: 48, onPressed: () => Navigator.of(ctx).pop()),
            ],
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
    const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text, height: 1.5);

    Widget check(String text, bool value, ValueChanged<bool> onChanged, {bool enabled = true}) {
      return InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Checkbox(value: value, onChanged: enabled ? (v) => onChanged(v ?? false) : null),
              Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: enabled ? C.text : C.muted, height: 1.4))),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Role', style: label),
        const SizedBox(height: 4),
        SegmentedToggle<Role>(
          height: 42,
          fontSize: 14,
          options: Role.values.map((r) => SegOption<Role>(r, roleName(r))).toList(),
          selected: st.role,
          onChanged: st.setRole,
        ),
        const SizedBox(height: 10),
        check('Recorded today (active patient)', st.recordedToday(st.activePatientId), st.setRecordedToday, enabled: !st.emptyAccount),
        check('Offline (readings wait to sync)', st.offline, st.setOffline),
        check('New account — no readings (patient)', st.emptyAccount, st.setEmptyAccount, enabled: st.role == Role.patient),
        const SizedBox(height: 6),
        const Text('What the simulated OCR returns', style: label),
        const SizedBox(height: 4),
        SegmentedToggle<OcrScenario>(
          height: 42,
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
        const SizedBox(height: 12),
        TactileButton(label: 'Reset sample data', icon: Icons.restart_alt, height: 48, fontSize: 15, onPressed: st.resetDemo),
      ],
    );
  }
}
