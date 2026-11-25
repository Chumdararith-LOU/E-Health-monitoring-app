// Step 1 of recording: choose the method. Photo first (fastest, NFR-05),
// typing always available.

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'ocr_screen.dart';
import 'reading_form_screen.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final patient = st.patient;
    if (patient == null || !st.canRecord(patient.id)) {
      return AppScreen(children: [EmptyState(icon: Mdi.lockOutline, title: t('cannotRecord'))]);
    }
    final today = st.todayReadingOf(patient.id);
    return AppScreen(children: [
      const PatientSwitcher(labelKey: 'recordingFor'),
      Gap(children: [
        Icon(today != null ? Mdi.checkCircle : Mdi.clockAlertOutline, size: 22, color: today != null ? C.ok : C.low),
        Flexible(
          child: AppText(
            today != null ? t('recordedToday', {'time': i18n.time(today.takenAt)}) : t('notRecordedToday'),
            weight: W.semibold,
            color: today != null ? C.ok : C.low,
          ),
        ),
      ]),
      AppText(t('recordQuestion'), variant: TextVariant.title, header: true),
      _Option(
        primary: true,
        icon: Mdi.camera,
        title: t('methodPhotoBp'),
        hint: t('methodPhotoBpHint'),
        onTap: () => push(context, const OcrScreen(device: OcrDevice.bp)),
      ),
      _Option(
        primary: true,
        icon: Mdi.cameraOutline,
        title: t('methodPhotoGlu'),
        hint: t('methodPhotoGluHint'),
        onTap: () => push(context, const OcrScreen(device: OcrDevice.glucose)),
      ),
      _Option(
        icon: Mdi.keyboardOutline,
        title: t('methodManual'),
        hint: t('methodManualHint'),
        onTap: () => push(context, ReadingFormScreen(patientId: patient.id)),
      ),
      AppBanner(icon: Mdi.lightbulbOnOutline, text: t('recordTip')),
    ]);
  }
}

class _Option extends StatefulWidget {
  const _Option({required this.icon, required this.title, required this.hint, required this.onTap, this.primary = false});
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.hint}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(Sp.lg),
          decoration: BoxDecoration(
            color: _down ? C.primarySoft : C.surface,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(
              color: _down ? C.primary : (widget.primary ? C.optionBorder : C.border),
              width: 1.5,
            ),
          ),
          child: Gap(gap: Sp.md, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: widget.primary ? C.primary : C.primarySoft, shape: BoxShape.circle),
              child: Icon(widget.icon, size: 34, color: widget.primary ? C.onPrimary : C.primary),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(widget.title, variant: TextVariant.heading, weight: W.semibold),
                AppText(widget.hint, variant: TextVariant.label, color: C.textMuted),
              ]),
            ),
            const Icon(Mdi.chevronRight, size: 28, color: C.textMuted),
          ]),
        ),
      ),
    );
  }
}
