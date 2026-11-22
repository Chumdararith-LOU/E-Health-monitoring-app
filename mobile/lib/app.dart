import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/shell_screen.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';

final ThemeData _theme = buildTheme();

class EHealthApp extends StatelessWidget {
  const EHealthApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(builder: (context) {
        final lang = AppScope.of(context).lang;
        return MaterialApp(
          title: 'E-Health',
          debugShowCheckedModeBanner: false,
          theme: _theme,
          locale: lang == AppLang.km ? const Locale('km') : const Locale('en'),
          supportedLocales: const <Locale>[Locale('km'), Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Respect the phone's text size for elderly users, but cap it so
          // the layout never breaks (1.3× is still very large).
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const ShellScreen(),
        );
      }),
    );
  }
}
