// Forgot password: ask for a code by email, then set a new password with it. Module: accounts.

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'accounts_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pw = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  String? _errEmail, _errCode, _errPw, _errForm;

  static const _minPassword = 8;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _clear() {
    if (_errEmail != null || _errCode != null || _errPw != null || _errForm != null) {
      setState(() => _errEmail = _errCode = _errPw = _errForm = null);
    }
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    final st = AppScope.read(context);
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _errEmail = st.i18n.t('acctErrEmail'));
      return;
    }
    setState(() {
      _busy = true;
      _errForm = null;
    });
    try {
      await st.api.forgotPassword(email);
      if (mounted) setState(() => _codeStep = true);
    } catch (e) {
      if (mounted) setState(() => _errForm = accountErrorText(st.i18n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy) return;
    final st = AppScope.read(context);
    final t = st.i18n.t;
    final code = fromKhmerDigits(_code.text).replaceAll(RegExp(r'\s'), '');
    String? eCode, ePw;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) eCode = t('acctErrCode');
    if (_pw.text.length < _minPassword) ePw = t('acctErrNewPassword', {'n': _minPassword});
    if (eCode != null || ePw != null) {
      setState(() {
        _errCode = eCode;
        _errPw = ePw;
      });
      return;
    }
    setState(() {
      _busy = true;
      _errForm = null;
    });
    try {
      await st.api.resetPassword(_email.text.trim(), code, _pw.text);
      if (!mounted) return;
      showToast(context, t('acctResetDone'));
      Navigator.of(context).pop();
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
      title: t('acctResetTitle'),
      child: AppScreen(children: [
        if (!_codeStep) ...[
          AppText(t('acctResetIntro'), color: C.textMuted),
          if (_errForm != null) AppBanner(kind: BannerKind.error, text: _errForm!),
          AppField(
            label: t('acctEmail'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            error: _errEmail,
            onChanged: (_) => _clear(),
            onSubmitted: (_) => _sendCode(),
          ),
          AppButton(label: t('acctSendCode'), icon: Mdi.login, loading: _busy, onPressed: _sendCode),
        ] else ...[
          AppBanner(text: t('acctCodeSent', {'email': _email.text.trim()})),
          if (_errForm != null) AppBanner(kind: BannerKind.error, text: _errForm!),
          AppField(
            label: t('acctCode'),
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            centered: true,
            large: true,
            autofocus: true,
            error: _errCode,
            onChanged: (_) => _clear(),
          ),
          AppField(
            label: t('acctNewPassword'),
            hint: t('acctPasswordHint'),
            controller: _pw,
            obscure: true,
            error: _errPw,
            onChanged: (_) => _clear(),
            onSubmitted: (_) => _reset(),
          ),
          AppButton(label: t('acctSetPassword'), icon: Mdi.login, loading: _busy, onPressed: _reset),
          AppButton(
            label: t('acctResendCode'),
            variant: BtnVariant.secondary,
            disabled: _busy,
            onPressed: _sendCode,
          ),
        ],
        AppButton(
          label: t('acctBackToSignIn'),
          variant: BtnVariant.ghost,
          disabled: _busy,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}
