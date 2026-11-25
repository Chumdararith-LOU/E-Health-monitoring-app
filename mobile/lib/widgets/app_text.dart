// Every piece of text goes through AppText so typography is consistent.
// Google Sans has no Khmer glyphs, so text that contains Khmer characters is
// set in Noto Sans Khmer, with a taller line height for stacked Khmer vowels
// and subscripts. Everything else, including Western digits, uses Google Sans.

import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';

enum W {
  regular(FontWeight.w400),
  medium(FontWeight.w500),
  semibold(FontWeight.w600),
  bold(FontWeight.w700);

  const W(this.weight);
  final FontWeight weight;
}

final _khmer = RegExp('[ក-៿᧠-᧿]');

bool hasKhmer(String s) => _khmer.hasMatch(s);

W _defaultWeight(TextVariant v) => switch (v) {
      TextVariant.title || TextVariant.heading => W.bold,
      TextVariant.display => W.semibold,
      _ => W.regular,
    };

/// The style AppText uses, for places that need a raw TextStyle (rich text, inputs, charts).
TextStyle appStyle(
  BuildContext context,
  String text, {
  TextVariant variant = TextVariant.body,
  W? weight,
  Color color = C.text,
  double? size,
}) {
  final st = AppScope.of(context);
  final khmer = text.isEmpty ? st.i18n.isKm : hasKhmer(text);
  return TextStyle(
    fontFamily: khmer ? Fonts.khmer : Fonts.latin,
    fontFamilyFallback: [khmer ? Fonts.latin : Fonts.khmer],
    fontSize: (size ?? variant.size) * st.settings.textScale,
    fontWeight: (weight ?? _defaultWeight(variant)).weight,
    height: khmer ? 1.6 : 1.3,
    color: color,
  );
}

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = TextVariant.body,
    this.weight,
    this.color = C.text,
    this.align,
    this.maxLines,
    this.header = false,
  });

  final String text;
  final TextVariant variant;
  final W? weight;
  final Color color;
  final TextAlign? align;
  final int? maxLines;

  /// Marks the text as a heading for screen readers.
  final bool header;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      text,
      style: appStyle(context, text, variant: variant, weight: weight, color: color),
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
    return header ? Semantics(header: true, child: t) : t;
  }
}
