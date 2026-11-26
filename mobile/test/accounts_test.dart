import 'dart:convert';

import 'package:ehealth_mobile/api/api_client.dart';
import 'package:ehealth_mobile/data/types.dart';
import 'package:ehealth_mobile/l10n/en.dart';
import 'package:ehealth_mobile/l10n/strings.dart';
import 'package:ehealth_mobile/screens/auth/accounts_api.dart';
import 'package:ehealth_mobile/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _userJson({bool verified = true}) => {
      'id': 'u-new',
      'role': 'patient',
      'nameEn': 'Dev Test',
      'nameKm': 'Dev Test',
      'email': 'dev@example.com',
      'phone': null,
      'emailVerified': verified,
    };

void main() {
  test('login posts the identifier and password and parses token and user', () async {
    late String seenMethod;
    late String seenPath;
    late String? seenBody;
    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (method, uri, headers, body) async {
        seenMethod = method;
        seenPath = uri.path;
        seenBody = body;
        return ApiHttpResponse(statusCode: 200, body: jsonEncode({'token': 'jwt-1', 'user': _userJson()}));
      },
    );

    final session = await api.login('dev@example.com', 'correct-horse');

    expect(seenMethod, 'POST');
    expect(seenPath, '/api/v1/auth/login');
    expect(jsonDecode(seenBody!), {'identifier': 'dev@example.com', 'password': 'correct-horse'});
    expect(session.token, 'jwt-1');
    expect(session.user.role, Role.patient);
    expect(session.user.emailVerified, isTrue);
    expect(session.user.toAppUser().phone, 'dev@example.com'); // no phone: shows the email
  });

  test('register leaves out an empty phone, forgotPassword and resetPassword accept 204', () async {
    final seen = <String, String?>{};
    final api = ApiClient(
      baseUrl: 'http://example.test/api/v1',
      transport: (method, uri, headers, body) async {
        seen[uri.path] = body;
        if (uri.path.endsWith('/auth/register')) {
          return ApiHttpResponse(
            statusCode: 201,
            body: jsonEncode({'token': 'jwt-2', 'user': _userJson(verified: false)}),
          );
        }
        return const ApiHttpResponse(statusCode: 204, body: '');
      },
    );

    final session = await api.register(
      role: Role.family,
      nameEn: 'Dev Test',
      email: 'dev@example.com',
      phone: '',
      password: 'correct-horse',
    );
    await api.forgotPassword('dev@example.com');
    await api.resetPassword('dev@example.com', '123456', 'brand-new-pass');

    expect(session.user.emailVerified, isFalse);
    final registerBody = jsonDecode(seen['/api/v1/auth/register']!) as Map<String, dynamic>;
    expect(registerBody['role'], 'family');
    expect(registerBody.containsKey('phone'), isFalse);
    expect(registerBody.containsKey('nameKm'), isFalse);
    expect(jsonDecode(seen['/api/v1/auth/password/reset']!), {
      'email': 'dev@example.com',
      'code': '123456',
      'newPassword': 'brand-new-pass',
    });
  });

  test('accountErrorText uses the accounts texts and falls back to the shared API errors', () {
    final i18n = I18n(Lang.en, Numerals.western);
    const wrong = ApiClientException(
      status: 401,
      code: 'invalid_credentials',
      messageKey: 'errors.invalid_credentials',
    );
    const other = ApiClientException(status: 403, code: 'forbidden', messageKey: 'errors.forbidden');
    expect(accountErrorText(i18n, wrong), en['acctErrInvalidCredentials']);
    expect(accountErrorText(i18n, other), i18n.apiError('errors.forbidden'));
    expect(
      isOffline(const ApiClientException(status: 0, code: 'network_error', messageKey: 'errors.network')),
      isTrue,
    );
    expect(isOffline(wrong), isFalse);
  });

  test('signInWithApi adds an unknown user, keeps the token, and signOut clears it', () {
    final st = AppState(persist: false, enableLiveApi: false);
    final user = AccountUser.fromJson(_userJson()).toAppUser();
    expect(st.userById('u-new'), isNull);

    st.signInWithApi(user, 'jwt-3');

    expect(st.userId, 'u-new');
    expect(st.token, 'jwt-3');
    expect(st.user?.role, Role.patient);

    // signing in again does not add the user twice
    st.signInWithApi(user, 'jwt-4');
    expect(st.data.users.where((u) => u.id == 'u-new').length, 1);

    st.signOut();
    expect(st.token, isNull);
  });
}
