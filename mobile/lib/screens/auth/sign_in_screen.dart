// US-01 sign in, plus demo role buttons (dev login). Module: accounts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/seed.dart';
import '../../data/types.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'accounts_api.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

const _roleIcons = {
  Role.patient: Mdi.accountHeart,
  Role.caretaker: Mdi.handHeart,
  Role.family: Mdi.accountGroup,
  Role.doctor: Mdi.stethoscope,
};

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _showPw = false;
  bool _busy = false;
  String? _errId, _errPw, _errForm;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _clear() {
    if (_errId != null || _errPw != null || _errForm != null) {
      setState(() => _errId = _errPw = _errForm = null);
    }
  }

  // The API is not running: fall back to the local demo accounts. Returns an error text, or null when signed in.
  String? _signInLocally() {
    final st = AppScope.read(context);
    final t = st.i18n.t;
    String norm(String s) => fromKhmerDigits(s).replaceAll(RegExp(r'\D'), '');
    final typed = norm(_id.text);
    AppUser? u;
    for (final x in st.data.users) {
      if (norm(x.phone).isNotEmpty && norm(x.phone) == typed) u = x;
    }
    if (u == null) return t('errNoAccount');
    if (u.role == Role.admin) return t('errAdminWeb');
    st.signIn(u.id);
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final st = AppScope.read(context);
    final t = st.i18n.t;
    String? eId, ePw, eForm;
    if (_id.text.trim().isEmpty) eId = t('errPhoneRequired');
    if (_pw.text.length < 6) ePw = t('errPasswordShort', {'n': 6});
    if (eId == null && ePw == null) {
      final nav = Navigator.of(context);
      setState(() => _busy = true);
      try {
        final session = await st.api.login(fromKhmerDigits(_id.text.trim()), _pw.text);
        if (!mounted) return;
        final user = session.user;
        if (user.role == Role.admin) {
          eForm = t('errAdminWeb');
        } else if (!user.emailVerified && user.email != null) {
          // Signed in, but the email is not verified yet: offer the code page first.
          nav.push(MaterialPageRoute<void>(
            builder: (_) => VerifyEmailScreen(
              email: user.email!,
              token: session.token,
              sendOnOpen: true,
              onFinished: () {
                nav.popUntil((r) => r.isFirst);
                st.signInWithApi(user.toAppUser(), session.token);
              },
            ),
          ));
          return;
        } else {
          st.signInWithApi(user.toAppUser(), session.token);
          return;
        }
      } catch (e) {
        eForm = isOffline(e) ? _signInLocally() : accountErrorText(st.i18n, e);
        if (eForm == null) return; // signed in with the local demo data
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (!mounted) return;
    setState(() {
      _errId = eId;
      _errPw = ePw;
      _errForm = eForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: C.bg,
        body: SafeArea(
          bottom: false,
          child: AppScreen(children: [
            Gap(children: [
              const Icon(Mdi.translate, size: 22, color: C.textMuted),
              Expanded(
                child: Segmented<Lang>(
                  label: t('language'),
                  value: st.settings.lang,
                  onChanged: (lang) => st.setSettings(st.settings.copyWith(lang: lang)),
                  options: const [SegOption(Lang.km, 'ខ្មែរ'), SegOption(Lang.en, 'English')],
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Sp.md),
              child: Column(children: [
                Container(
                  width: 72,
                  height: 72,
                  margin: const EdgeInsets.only(bottom: Sp.sm + Sp.xs),
                  decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Mdi.heartPulse, size: 40, color: C.onPrimary),
                ),
                AppText(t('appName'), variant: TextVariant.title),
                const SizedBox(height: Sp.xs),
                AppText(t('appTagline'), color: C.textMuted, align: TextAlign.center),
              ]),
            ),
            AppCard(children: [
              AppText(t('signIn'), variant: TextVariant.heading, header: true),
              if (_errForm != null) AppBanner(kind: BannerKind.error, text: _errForm!),
              AppField(
                label: t('phoneOrEmail'),
                controller: _id,
                placeholder: '012 345 678',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                error: _errId,
                onChanged: (_) => _clear(),
              ),
              AppField(
                label: t('password'),
                controller: _pw,
                obscure: !_showPw,
                error: _errPw,
                onChanged: (_) => _clear(),
                onSubmitted: (_) => _submit(),
                right: Semantics(
                  button: true,
                  label: _showPw ? t('hidePassword') : t('showPassword'),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _showPw = !_showPw),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.sm),
                      child: Icon(_showPw ? Mdi.eyeOffOutline : Mdi.eyeOutline, size: 26, color: C.textMuted),
                    ),
                  ),
                ),
              ),
              AppButton(label: t('signIn'), icon: Mdi.login, loading: _busy, onPressed: _submit),
              AppButton(
                label: t('acctForgot'),
                variant: BtnVariant.ghost,
                disabled: _busy,
                onPressed: () => push(context, const ForgotPasswordScreen()),
              ),
              AppButton(
                label: t('acctCreate'),
                variant: BtnVariant.secondary,
                disabled: _busy,
                onPressed: () => push(context, const RegisterScreen()),
              ),
            ]),
            SectionTitle(t('demoAccounts')),
            AppBanner(text: t('demoAccountsHint')),
            for (final role in demoLogins.keys) _RoleCard(role: role),
            AppText(t('errAdminWeb'), variant: TextVariant.caption, color: C.textMuted, align: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role});
  final Role role;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final role = widget.role;
    final u = st.userById(demoLogins[role]);
    return Semantics(
      button: true,
      label: '${i18n.role(role)}, ${i18n.name(u)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () => st.signIn(demoLogins[role]!),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(
            color: _down ? C.primarySoft : C.surface,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: _down ? C.primary : C.border, width: 1.5),
          ),
          child: Gap(gap: Sp.md, children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: C.primarySoft, shape: BoxShape.circle),
              child: Icon(_roleIcons[role], size: 28, color: C.primary),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(i18n.role(role), weight: W.semibold),
                AppText('${i18n.name(u)} · ${i18n.digits(u?.phone ?? '')}', variant: TextVariant.caption, color: C.textMuted),
                AppText(i18n.t('roleDesc_${role.name}'), variant: TextVariant.caption, color: C.textMuted),
              ]),
            ),
            const Icon(Mdi.chevronRight, size: 26, color: C.textMuted),
          ]),
        ),
      ),
    );
  }
}
