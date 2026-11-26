// Accounts API calls for the sign-in, register, verify and reset screens (Owner: Phayuk).
// An extension on the shared ApiClient, so api/api_client.dart stays untouched.

import '../../api/api_client.dart';
import '../../data/types.dart';
import '../../l10n/strings.dart';

/// The user returned by the accounts routes (`UserDto` in packages/types).
class AccountUser {
  const AccountUser({
    required this.id,
    required this.role,
    required this.nameEn,
    required this.nameKm,
    required this.email,
    required this.phone,
    required this.emailVerified,
  });

  final String id;
  final Role role;
  final String nameEn;
  final String nameKm;
  final String? email;
  final String? phone;
  final bool emailVerified;

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
        id: json['id'] as String,
        role: Role.values.firstWhere((r) => r.name == json['role'], orElse: () => Role.patient),
        nameEn: json['nameEn'] as String,
        nameKm: json['nameKm'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
      );

  /// The shape the rest of the app uses for people.
  AppUser toAppUser() => AppUser(
        id: id,
        role: role,
        nameEn: nameEn,
        nameKm: nameKm,
        phone: phone ?? email ?? '',
      );
}

class AccountSession {
  const AccountSession({required this.token, required this.user});

  final String token;
  final AccountUser user;

  factory AccountSession.fromJson(Map<String, dynamic> json) => AccountSession(
        token: json['token'] as String,
        user: AccountUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

extension AccountsApi on ApiClient {
  /// `POST /auth/login`. [identifier] is an email or a phone number.
  Future<AccountSession> login(String identifier, String password) async => AccountSession.fromJson(
        await requestJson('POST', '/auth/login', body: {'identifier': identifier, 'password': password}),
      );

  /// `POST /auth/register`. The API emails a verification code.
  Future<AccountSession> register({
    required Role role,
    String? nameKm,
    String? nameEn,
    required String email,
    String? phone,
    required String password,
  }) async =>
      AccountSession.fromJson(
        await requestJson('POST', '/auth/register', body: {
          'role': role.name,
          if (nameKm != null) 'nameKm': nameKm,
          if (nameEn != null) 'nameEn': nameEn,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'password': password,
        }),
      );

  /// `POST /auth/verify-email/send`: a new code to the signed-in user's email.
  Future<void> sendVerificationCode(String token) async {
    await requestJson('POST', '/auth/verify-email/send', token: token);
  }

  /// `POST /auth/verify-email/confirm`.
  Future<AccountUser> confirmEmail(String token, String code) async => AccountUser.fromJson(
        await requestJson('POST', '/auth/verify-email/confirm', token: token, body: {'code': code}),
      );

  /// `POST /auth/password/forgot`. Always succeeds, whether or not the email has an account.
  Future<void> forgotPassword(String email) async {
    await requestJson('POST', '/auth/password/forgot', body: {'email': email});
  }

  /// `POST /auth/password/reset`.
  Future<void> resetPassword(String email, String code, String newPassword) async {
    await requestJson('POST', '/auth/password/reset',
        body: {'email': email, 'code': code, 'newPassword': newPassword});
  }
}

/// Error text for the accounts routes. Other errors use the shared API error texts.
String accountErrorText(I18n i18n, Object error) {
  if (error is! ApiClientException) return i18n.apiError('errors.internal_error');
  final key = switch (error.code) {
    'invalid_credentials' => 'acctErrInvalidCredentials',
    'invalid_code' => 'acctErrInvalidCode',
    'email_taken' => 'acctErrEmailTaken',
    'phone_taken' => 'acctErrPhoneTaken',
    'too_many_requests' => 'acctErrTooMany',
    'code_cooldown' => 'acctErrCooldown',
    'mail_failed' => 'acctErrMailFailed',
    _ => null,
  };
  return key != null ? i18n.t(key) : i18n.apiError(error.messageKey);
}

bool isOffline(Object error) => error is ApiClientException && error.status == 0;
