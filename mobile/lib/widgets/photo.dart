import 'dart:io';

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Demo photos are stored as `demo:name` so they survive app restarts;
/// real photos are file paths.
const _demo = {
  'demo:bp': 'assets/images/demo-bp.png',
  'demo:bp-blurry': 'assets/images/demo-bp-blurry.png',
  'demo:glucose': 'assets/images/demo-glucose.png',
};

class AppPhoto extends StatelessWidget {
  const AppPhoto({super.key, required this.uri, this.height = 220, this.radius = R.md, this.label});
  final String uri;
  final double height;
  final double radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final asset = _demo[uri];
    final image = asset != null
        ? Image.asset(asset, fit: BoxFit.contain)
        : Image.file(File(uri), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink());
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(height: height, width: double.infinity, color: C.border, child: image),
      ),
    );
  }
}
