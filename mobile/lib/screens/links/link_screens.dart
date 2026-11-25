// US-03 patient links. Patient: sees every link, approves requests, removes
// anyone (access ends at once), invites by 6-digit code or phone.
// Caretaker / family / doctor: sees their patients and links with a code.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/dates.dart';
import '../../data/types.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';

const _relIcon = {
  LinkRelation.doctor: Mdi.stethoscope,
  LinkRelation.caretaker: Mdi.handHeart,
  LinkRelation.family: Mdi.accountGroup,
};

Role _roleOf(LinkRelation r) => Role.values.byName(r.name);

class CareTeamScreen extends StatelessWidget {
  const CareTeamScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, Link l, {bool cancelInvite = false}) async {
    final st = AppScope.read(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final u = st.userById(l.userId);
    final c = await ask(
      context,
      title: cancelInvite ? t('cancelInvite') : t('removeConfirmTitle', {'name': i18n.name(u)}),
      body: cancelInvite ? null : t('removeConfirmBody'),
      icon: Mdi.accountRemoveOutline,
      iconColor: C.danger,
      buttons: [
        DialogBtn('remove', cancelInvite ? t('cancelInvite') : t('remove'), BtnVariant.danger),
        DialogBtn('cancel', t('cancel')),
      ],
    );
    if (c == 'remove' && context.mounted) {
      st.removeLink(l.id);
      showToast(context, '${t('removed')}: ${i18n.name(u)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final user = st.user;
    if (user == null) return const SizedBox.shrink();

    if (user.role != Role.patient) {
      final mine = st.data.links.where((l) => l.userId == user.id).toList();
      return StackPage(
        title: t('linkedPatients'),
        child: AppScreen(
          footer: [
            AppButton(
              icon: Mdi.linkVariantPlus,
              label: t('linkPatient'),
              onPressed: () => push(context, const LinkPatientScreen()),
            ),
          ],
          children: [
            SectionTitle(t('linkedPatients')),
            if (mine.isEmpty)
              EmptyState(icon: Mdi.accountMultiplePlusOutline, title: t('noLinkedPatients'), body: t('noLinkedPatientsHint')),
            for (final l in mine)
              AppCard(children: [
                Gap(children: [
                  const Icon(Mdi.accountCircle, size: 36, color: C.primary),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText(i18n.name(st.userById(l.patientId)), weight: W.semibold),
                      AppText(
                        l.status == LinkStatus.active
                            ? t('linkedSince', {'date': i18n.dateShort(l.createdAt)})
                            : t('pendingPatient'),
                        variant: TextVariant.caption,
                        color: l.status == LinkStatus.active ? C.textMuted : C.low,
                      ),
                    ]),
                  ),
                ]),
              ]),
          ],
        ),
      );
    }

    final links = st.data.links.where((l) => l.patientId == user.id).toList();
    final requests = links.where((l) => l.status == LinkStatus.pending && !l.initiatedByPatient).toList();
    final active = links.where((l) => l.status == LinkStatus.active).toList();
    final waiting = links.where((l) => l.status == LinkStatus.pending && l.initiatedByPatient).toList();

    return StackPage(
      title: t('careTeam'),
      child: AppScreen(
        footer: [
          AppButton(icon: Mdi.accountPlus, label: t('invite'), onPressed: () => push(context, const InviteScreen())),
        ],
        children: [
          AppBanner(icon: Mdi.shieldAccountOutline, text: t('careTeamHint')),
          if (requests.isNotEmpty) ...[
            SectionTitle(t('requests')),
            for (final l in requests)
              AppCard(tone: CardTone.low, children: [
                Gap(children: [
                  Icon(_relIcon[l.relation], size: 28, color: C.low),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AppText(i18n.name(st.userById(l.userId)), weight: W.semibold),
                      AppText(t('requestBody', {'role': i18n.role(_roleOf(l.relation))}), variant: TextVariant.label),
                    ]),
                  ),
                ]),
                Gap(children: [
                  Expanded(
                    child: AppButton(
                      variant: BtnVariant.secondary,
                      icon: Mdi.close,
                      label: t('decline'),
                      onPressed: () {
                        st.removeLink(l.id);
                        showToast(context, t('declined'));
                      },
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      icon: Mdi.check,
                      label: t('approve'),
                      onPressed: () {
                        st.approveLink(l.id);
                        showToast(context, '${t('approved')}: ${i18n.name(st.userById(l.userId))}');
                      },
                    ),
                  ),
                ]),
              ]),
          ],
          SectionTitle(t('careTeam')),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
            children: [
              if (active.isEmpty) AppText(t('none'), color: C.textMuted),
              for (var i = 0; i < active.length; i++)
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (i > 0) ...[const AppDivider(), const SizedBox(height: Sp.sm)],
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Gap(children: [
                      Icon(_relIcon[active[i].relation], size: 28, color: C.primary),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AppText(i18n.name(st.userById(active[i].userId)), weight: W.semibold),
                          AppText(
                            '${i18n.role(_roleOf(active[i].relation))} · ${t('linkedSince', {'date': i18n.dateShort(active[i].createdAt)})}',
                            variant: TextVariant.caption,
                            color: C.textMuted,
                          ),
                        ]),
                      ),
                      AppButton(
                        compact: true,
                        variant: BtnVariant.dangerGhost,
                        label: t('remove'),
                        onPressed: () => _confirmRemove(context, active[i]),
                      ),
                    ]),
                  ),
                ]),
            ],
          ),
          if (waiting.isNotEmpty) ...[
            SectionTitle(t('pendingInvites')),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.sm),
              children: [
                for (final l in waiting)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Gap(children: [
                      const Icon(Mdi.timerSand, size: 26, color: C.low),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AppText(i18n.name(st.userById(l.userId)), weight: W.semibold),
                          AppText(i18n.role(_roleOf(l.relation)), variant: TextVariant.caption, color: C.textMuted),
                        ]),
                      ),
                      AppButton(
                        compact: true,
                        variant: BtnVariant.ghost,
                        label: t('cancel'),
                        onPressed: () => _confirmRemove(context, l, cancelInvite: true),
                      ),
                    ]),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _makeCode() => '${100000 + math.Random().nextInt(900000)}';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  LinkRelation _rel = LinkRelation.doctor;
  String _code = _makeCode();
  final _created = DateTime.now();
  final _phone = TextEditingController();
  String? _phoneErr;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _sendByPhone() {
    final st = AppScope.read(context);
    final user = st.user;
    if (user == null) return;
    final digits = fromKhmerDigits(_phone.text).replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      setState(() => _phoneErr = st.i18n.t('errPhoneRequired'));
      return;
    }
    AppUser? target;
    for (final u in st.data.users) {
      if (u.phone.replaceAll(RegExp(r'\D'), '') == digits) target = u;
    }
    if (target != null && !st.data.links.any((l) => l.patientId == user.id && l.userId == target!.id)) {
      st.addLink(user.id, target.id, _rel, initiatedByPatient: true, status: LinkStatus.pending);
    }
    showToast(context, st.i18n.t('inviteSent'));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final t = i18n.t;
    final expires = addDays(_created, 1);
    return StackPage(
      title: t('inviteTitle'),
      child: AppScreen(children: [
        AppText(t('inviteAs'), variant: TextVariant.label, weight: W.semibold),
        Segmented<LinkRelation>(
          label: t('inviteAs'),
          value: _rel,
          onChanged: (v) => setState(() => _rel = v),
          options: [
            SegOption(LinkRelation.doctor, t('role_doctor')),
            SegOption(LinkRelation.caretaker, t('role_caretaker')),
            SegOption(LinkRelation.family, t('role_family')),
          ],
        ),
        AppCard(crossAxisAlignment: CrossAxisAlignment.center, children: [
          AppText(t('inviteCode'), variant: TextVariant.label, color: C.textMuted),
          Semantics(
            label: '${t('inviteCode')}: ${_code.split('').join(' ')}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.sm),
              child: Wrap(spacing: Sp.sm, children: [
                for (final d in _code.split(''))
                  Container(
                    width: 44,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.surfaceAlt,
                      borderRadius: BorderRadius.circular(R.sm),
                      border: Border.all(color: C.borderStrong, width: 1.5),
                    ),
                    child: AppText(i18n.digits(d), variant: TextVariant.title, weight: W.bold),
                  ),
              ]),
            ),
          ),
          AppText(t('expiresAt', {'date': i18n.dateShort(expires), 'time': i18n.time(expires)}),
              variant: TextVariant.caption, color: C.textMuted, align: TextAlign.center),
          AppText(t('inviteCodeHint'), variant: TextVariant.label, align: TextAlign.center),
          Gap(children: [
            Expanded(
              child: AppButton(
                variant: BtnVariant.secondary,
                icon: Mdi.refresh,
                label: t('newCode'),
                onPressed: () => setState(() => _code = _makeCode()),
              ),
            ),
            Expanded(
              child: AppButton(
                icon: Mdi.shareVariant,
                label: t('shareCode'),
                onPressed: () => SharePlus.instance.share(ShareParams(text: t('shareMessage', {'code': _code}))),
              ),
            ),
          ]),
        ]),
        SectionTitle(t('orPhone')),
        AppCard(children: [
          AppField(
            label: t('phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            placeholder: '023 900 200',
            error: _phoneErr,
            onChanged: (_) {
              if (_phoneErr != null) setState(() => _phoneErr = null);
            },
          ),
          AppButton(variant: BtnVariant.secondary, icon: Mdi.send, label: t('sendInvite'), onPressed: _sendByPhone),
        ]),
      ]),
    );
  }
}

/// Caretaker / family / doctor enters the patient's 6-digit code. The code is
/// the patient's consent, so the link is active at once.
class LinkPatientScreen extends StatefulWidget {
  const LinkPatientScreen({super.key});

  @override
  State<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends State<LinkPatientScreen> {
  final _code = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final st = AppScope.read(context);
    final t = st.i18n.t;
    final user = st.user;
    if (user == null) return;
    final c = fromKhmerDigits(_code.text).replaceAll(RegExp(r'\D'), '');
    if (c.length != 6) return setState(() => _err = t('errCode'));
    if (c != '246810') return setState(() => _err = t('errCodeInvalid'));
    // Demo: the code belongs to the first patient this user is not linked to yet
    final linked = {for (final l in st.data.links) if (l.userId == user.id) l.patientId};
    AppUser? target;
    for (final u in st.data.users) {
      if (u.role == Role.patient && !linked.contains(u.id)) {
        target = u;
        break;
      }
    }
    if (target == null) return setState(() => _err = t('alreadyLinked'));
    final relation = switch (user.role) {
      Role.doctor => LinkRelation.doctor,
      Role.caretaker => LinkRelation.caretaker,
      _ => LinkRelation.family,
    };
    st.addLink(target.id, user.id, relation, initiatedByPatient: true, status: LinkStatus.active);
    showToast(context, t('linkedTo', {'name': st.i18n.name(target)}));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).i18n.t;
    return StackPage(
      title: t('linkPatient'),
      child: AppScreen(
        footer: [AppButton(icon: Mdi.linkVariant, label: t('linkPatient'), onPressed: _submit)],
        children: [
          AppField(
            label: t('enterCode'),
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            large: true,
            centered: true,
            letterSpacing: 8,
            placeholder: '––––––',
            error: _err,
            hint: t('demoCodeHint'),
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_err != null) setState(() => _err = null);
            },
          ),
        ],
      ),
    );
  }
}
