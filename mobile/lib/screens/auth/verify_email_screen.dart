// US-01 email verification: type the 6-digit code that was emailed. Module: accounts.
// The user is not signed in to the app yet; [onFinished] does that (after a good code or "later").

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'accounts_api.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.token,
    required this.onFinished,
    this.sendOnOpen = false,
  });

  final String email;
  final String token;

  /// Called after the email is verified, or when the user chooses "Do it later".
  final VoidCallback onFinished;

  /// True when the code was not just sent (sign-in of an unverified account).
  final bool sendOnOpen;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  String? _errCode, _errForm;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.sendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final st = AppScope.read(context);
    setState(() {
      _busy = true;
      _errForm = null;
    });
    try {
      await st.api.sendVerificationCode(widget.token);
    } catch (e) {
      if (mounted) setState(() => _errForm = accountErrorText(st.i18n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final st = AppScope.read(context);
    final code = fromKhmerDigits(_code.text).replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _errCode = st.i18n.t('acctErrCode'));
      return;
    }
    setState(() {
      _busy = true;
      _errForm = null;
    });
    try {
      await st.api.confirmEmail(widget.token, code);
      if (!mounted) return;
      showToast(context, st.i18n.t('acctVerified'));
      widget.onFinished();
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
      title: t('acctVerifyTitle'),
      child: AppScreen(children: [
        AppBanner(text: t('acctVerifyIntro', {'email': widget.email})),
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
          onChanged: (_) {
            if (_errCode != null || _errForm != null) setState(() => _errCode = _errForm = null);
          },
          onSubmitted: (_) => _confirm(),
        ),
        AppButton(label: t('acctVerify'), icon: Mdi.checkCircleOutline, loading: _busy, onPressed: _confirm),
        AppButton(
          label: t('acctResendCode'),
          variant: BtnVariant.secondary,
          disabled: _busy,
          onPressed: _send,
        ),
        AppButton(label: t('acctSkip'), variant: BtnVariant.ghost, disabled: _busy, onPressed: widget.onFinished),
      ]),
    );
  }
}
