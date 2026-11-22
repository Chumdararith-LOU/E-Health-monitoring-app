import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.navyBase,
    primary: C.navyBase,
    onPrimary: Colors.white,
    surface: C.panel,
    onSurface: C.text,
    error: C.errBorder,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: T.f,
    scaffoldBackgroundColor: C.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.focus,
      selectionColor: Color(0x551976D2),
      selectionHandleColor: C.focus,
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: C.borderStrong, width: 1.5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? C.navyBase : Colors.white),
    ),
  );
}

/// Fast, plain page change (under 150 ms, no sliding — NFR-07 "zero gimmicks").
Route<T> fastRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 140),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
  );
}
