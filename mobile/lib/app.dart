import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/types.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'widgets/widgets.dart';

class EHealthApp extends StatelessWidget {
  const EHealthApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(builder: (context) {
        final lang = AppScope.of(context).settings.lang;
        return MaterialApp(
          title: 'E-Health',
          debugShowCheckedModeBanner: false,
          locale: Locale(lang.name),
          supportedLocales: const [Locale('km'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: C.primary, primary: C.primary, surface: C.surface),
            scaffoldBackgroundColor: C.bg,
            fontFamily: Fonts.latin,
            fontFamilyFallback: const [Fonts.khmer],
            textSelectionTheme: const TextSelectionThemeData(cursorColor: C.focus, selectionHandleColor: C.focus),
          ),
          // The phone's font size is respected, capped at ×1.3 so layouts don't break.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3)),
              child: ToastHost(child: child!),
            );
          },
          home: const _Root(),
        );
      }),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    if (!st.ready) {
      return const ColoredBox(
        color: C.bg,
        child: Center(child: CircularProgressIndicator(color: C.primary)),
      );
    }
    final user = st.user;
    if (user == null || user.role == Role.admin) return const SignInScreen();
    return const Shell();
  }
}
