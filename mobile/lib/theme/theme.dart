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
    splashFactory: InkRipple.splashFactory,
    splashColor: const Color(0x140F5C7A),
    highlightColor: const Color(0x0A0F5C7A),
    dividerColor: C.divider,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.focus,
      selectionColor: C.focusHalo,
      selectionHandleColor: C.focus,
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: C.borderStrong, width: 1.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? C.navyBase : Colors.white,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: C.panel,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: C.navyBase,
      headerForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: C.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Crisp, smooth page transition (200 ms fade + subtle lift — responsive on mid-range phones).
Route<T> fastRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
