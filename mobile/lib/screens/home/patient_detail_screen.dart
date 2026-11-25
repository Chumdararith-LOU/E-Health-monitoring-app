// Patient page for caretaker, family and doctor. The doctor adds clinical
// notes here (US-19).

import 'package:flutter/material.dart';

import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'patient_overview.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final p = st.userById(patientId);
    if (p == null || !st.canView(patientId)) {
      return StackPage(
        title: '',
        child: AppScreen(children: [EmptyState(icon: Mdi.lockOutline, title: t('noData'))]),
      );
    }
    void go(AppTab tab) {
      st.selectPatient(patientId);
      goToTab(context, tab);
    }

    return StackPage(
      title: i18n.name(p),
      child: AppScreen(children: [
        AppCard(children: [
          Gap(gap: Sp.md, children: [
            const Icon(Mdi.accountCircle, size: 48, color: C.primary),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(i18n.name(p), variant: TextVariant.heading),
                AppText(
                  '${t('age', {'n': p.age ?? 0})} · ${(i18n.isKm ? p.conditionsKm : p.conditionsEn) ?? ''}',
                  variant: TextVariant.label,
                  color: C.textMuted,
                ),
                AppText(i18n.digits(p.phone), variant: TextVariant.label, color: C.textMuted),
              ]),
            ),
          ]),
          Gap(children: [
            Expanded(
              child: AppButton(
                variant: BtnVariant.secondary,
                icon: Mdi.history,
                label: t('openHistory'),
                onPressed: () => go(AppTab.history),
              ),
            ),
            Expanded(
              child: AppButton(
                variant: BtnVariant.secondary,
                icon: Mdi.chartLine,
                label: t('openReports'),
                onPressed: () => go(AppTab.reports),
              ),
            ),
          ]),
          if (st.user?.role == Role.doctor)
            AppButton(
              icon: Mdi.notePlusOutline,
              label: t('addNote'),
              onPressed: () => push(context, AddNoteScreen(patientId: patientId)),
            ),
        ]),
        if (st.user?.role == Role.family) AppBanner(icon: Mdi.eyeOutline, text: t('readOnly')),
        PatientOverview(patientId: patientId),
      ]),
    );
  }
}

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key, required this.patientId});
  final String patientId;

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final t = st.i18n.t;
    final text = _text.text.trim();
    return StackPage(
      title: t('addNote'),
      child: AppScreen(
        footer: [
          AppButton(
            icon: Mdi.contentSave,
            label: t('save'),
            disabled: text.isEmpty,
            onPressed: () {
              st.addNote(widget.patientId, text);
              showToast(context, t('noteSaved'));
              Navigator.of(context).pop();
            },
          ),
        ],
        children: [
          AppText(st.i18n.name(st.userById(widget.patientId)), color: C.textMuted),
          AppField(
            label: t('note'),
            controller: _text,
            placeholder: t('notePlaceholderDoctor'),
            multiline: true,
            autofocus: true,
            maxLength: 1000,
            minHeight: 160,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
