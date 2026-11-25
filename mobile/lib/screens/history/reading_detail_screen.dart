// One reading: values, each measure against its normal range (why is it
// flagged?), method, author, note, photo. Edit / delete with Undo (US-05).

import 'package:flutter/material.dart';

import '../../data/ranges.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../record/reading_form_screen.dart';
import '../shell.dart';

class ReadingDetailScreen extends StatelessWidget {
  const ReadingDetailScreen({super.key, required this.id});
  final String id;

  Future<void> _delete(BuildContext context, Reading r) async {
    final st = AppScope.read(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final c = await ask(
      context,
      title: t('deleteConfirmTitle'),
      body: t('deleteConfirmBody', {'date': '${i18n.date(r.takenAt)} ${i18n.time(r.takenAt)}'}),
      icon: Mdi.trashCanOutline,
      iconColor: C.danger,
      buttons: [
        DialogBtn('delete', t('deleteReading'), BtnVariant.danger),
        DialogBtn('cancel', t('cancel')),
      ],
    );
    if (c != 'delete' || !context.mounted) return;
    final removed = st.deleteReading(r.id);
    showToast(context, t('deleted'), actionLabel: t('undo'), onAction: () {
      if (removed != null) st.restoreReading(removed);
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final r = st.readingById(id);
    if (r == null || !st.canView(r.patientId)) {
      return StackPage(
        title: t('readingDetail'),
        child: AppScreen(children: [EmptyState(icon: Mdi.fileHidden, title: t('noData'))]),
      );
    }
    final editable = st.canEditReading(r);
    final author = st.userById(r.enteredBy);
    final keys = [for (final k in measureOrder) if (r.valueOf(k) != null) k];

    return StackPage(
      title: '${i18n.dateRelative(r.takenAt)} · ${i18n.time(r.takenAt)}',
      child: AppScreen(
        footer: [
          if (editable)
            Gap(children: [
              Expanded(
                child: AppButton(
                  variant: BtnVariant.secondary,
                  icon: Mdi.trashCanOutline,
                  label: t('delete'),
                  onPressed: () => _delete(context, r),
                ),
              ),
              Expanded(
                child: AppButton(
                  icon: Mdi.pencil,
                  label: t('edit'),
                  onPressed: () => push(context, ReadingFormScreen(readingId: r.id)),
                ),
              ),
            ]),
        ],
        children: [
          AppCard(children: [
            Row(children: [
              Expanded(
                child: AppText('${i18n.date(r.takenAt)} · ${i18n.time(r.takenAt)}', variant: TextVariant.label, color: C.textMuted),
              ),
              StatusBadge(badgeOf(readingLevel(r))),
            ]),
            ReadingBlock(r),
          ]),
          // Each measure against its normal range: explains WHY something is flagged
          AppCard(children: [
            for (var i = 0; i < keys.length; i++)
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (i > 0) ...[const AppDivider(), const SizedBox(height: Sp.sm)],
                Gap(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText(t('m_${keys[i].name}'), weight: W.medium),
                      AppText(
                        '${t('normalRange')}: ${i18n.n(measures[keys[i]]!.normalMin)}–${i18n.n(measures[keys[i]]!.normalMax)} ${measures[keys[i]]!.unit}',
                        variant: TextVariant.caption,
                        color: C.textMuted,
                      ),
                    ]),
                  ),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: i18n.n(r.valueOf(keys[i]))),
                      TextSpan(
                        text: ' ${measures[keys[i]]!.unit}',
                        style: appStyle(context, 'mmHg', variant: TextVariant.caption, color: C.textMuted),
                      ),
                    ]),
                    style: appStyle(context, '0', weight: W.bold),
                  ),
                  SizedBox(
                    width: 92,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: StatusBadge(badgeOf(levelOf(keys[i], r.valueOf(keys[i]))!), small: true),
                    ),
                  ),
                ]),
              ]),
          ]),
          AppCard(children: [
            Gap(children: [
              Icon(r.method == EntryMethod.ocr ? Mdi.cameraOutline : Mdi.keyboardOutline, size: 22, color: C.textMuted),
              Expanded(child: AppText(t('method_${r.method.name}'))),
            ]),
            Gap(children: [
              const Icon(Mdi.accountEditOutline, size: 22, color: C.textMuted),
              Expanded(
                child: AppText('${t('enteredBy')}: ${i18n.name(author)} (${author != null ? i18n.role(author.role) : ''})'),
              ),
            ]),
            if (r.note != null)
              Gap(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Mdi.noteTextOutline, size: 22, color: C.textMuted),
                ),
                Expanded(child: AppText(r.note!)),
              ]),
            if (r.photoUri != null) AppPhoto(uri: r.photoUri!, label: t('photo')),
          ]),
          if (!editable && st.user?.role == Role.caretaker)
            AppText(t('cannotEditOthers'), variant: TextVariant.caption, color: C.textMuted, align: TextAlign.center),
        ],
      ),
    );
  }
}
