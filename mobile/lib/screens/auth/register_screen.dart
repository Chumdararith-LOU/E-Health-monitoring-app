// US-01 create an account. Module: accounts.
// The API emails a code, so the next page is the email verification.

import 'package:flutter/material.dart';

import '../../data/types.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'accounts_api.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pw = TextEditingController();
  Role _role = Role.patient;
  bool _showPw = false;
  bool _busy = false;
  String? _errName, _errEmail, _errPhone, _errPw, _errForm;

  static const _minPassword = 8;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _clear() {
    if (_errName != null || _errEmail != null || _errPhone != null || _errPw != null || _errForm != null) {
      setState(() => _errName = _errEmail = _errPhone = _errPw = _errForm = null);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    final st = AppScope.read(context);
    final t = st.i18n.t;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = fromKhmerDigits(_phone.text).trim();
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');

    String? eName, eEmail, ePhone, ePw;
    if (name.isEmpty) eName = t('acctErrName');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) eEmail = t('acctErrEmail');
    if (phone.isNotEmpty && (phoneDigits.length < 8 || phoneDigits.length > 16)) ePhone = t('acctErrPhone');
    if (_pw.text.length < _minPassword) ePw = t('acctErrNewPassword', {'n': _minPassword});
    if (eName != null || eEmail != null || ePhone != null || ePw != null) {
      setState(() {
        _errName = eName;
        _errEmail = eEmail;
        _errPhone = ePhone;
        _errPw = ePw;
      });
      return;
    }

    final nav = Navigator.of(context);
    final isKhmer = RegExp(r'[ក-៿]').hasMatch(name);
    setState(() => _busy = true);
    try {
      final session = await st.api.register(
        role: _role,
        nameKm: isKhmer ? name : null,
        nameEn: isKhmer ? null : name,
        email: email,
        phone: phone,
        password: _pw.text,
      );
      if (!mounted) return;
      // The account exists and a code was emailed. Verify, then sign in.
      nav.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => VerifyEmailScreen(
          email: email,
          token: session.token,
          onFinished: () {
            nav.popUntil((r) => r.isFirst);
            st.signInWithApi(session.user.toAppUser(), session.token);
          },
        ),
      ));
    } catch (e) {
      if (mounted) setState(() => _errForm = accountErrorText(st.i18n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).i18n.t;
    return StackPage(
      title: t('acctRegisterTitle'),
      child: AppScreen(children: [
        if (_errForm != null) AppBanner(kind: BannerKind.error, text: _errForm!),
        AppText(t('acctIAm'), variant: TextVariant.label, weight: W.semibold),
        Segmented<Role>(
          label: t('acctIAm'),
          value: _role,
          onChanged: (r) => setState(() => _role = r),
          options: [
            SegOption(Role.patient, t('role_patient')),
            SegOption(Role.caretaker, t('role_caretaker')),
            SegOption(Role.family, t('role_family')),
          ],
        ),
        AppField(
          label: t('acctName'),
          controller: _name,
          textInputAction: TextInputAction.next,
          error: _errName,
          onChanged: (_) => _clear(),
        ),
        AppField(
          label: t('acctEmail'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          error: _errEmail,
          onChanged: (_) => _clear(),
        ),
        AppField(
          label: t('acctPhoneOptional'),
          controller: _phone,
          placeholder: '012 345 678',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          error: _errPhone,
          onChanged: (_) => _clear(),
        ),
        AppField(
          label: t('password'),
          hint: t('acctPasswordHint'),
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
        AppButton(label: t('acctRegister'), icon: Mdi.login, loading: _busy, onPressed: _submit),
      ]),
    );
  }
}
