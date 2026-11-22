import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'device_lcd.dart';
import 'tactile_button.dart';

/// Dark full-screen lightbox for the device photo kept with a reading (pinch to zoom).
Future<void> showPhotoDialog(
  BuildContext context, {
  Reading? reading,
  DeviceMode mode = DeviceMode.bp,
  String? sys,
  String? dia,
  String? pul,
  String? glu,
  String unit = 'mg/dL',
}) {
  final l = L.of(context);
  final photos = <Widget>[];
  if (reading != null) {
    if (reading.photoBp && reading.hasBp) {
      photos.add(
        DeviceLcd(
          mode: DeviceMode.bp,
          sys: '${reading.systolic}',
          dia: '${reading.diastolic}',
          pul: '${reading.pulse ?? '--'}',
          width: 240,
        ),
      );
    }
    if (reading.photoGlucose && reading.glucose != null) {
      photos.add(
        DeviceLcd(
          mode: DeviceMode.glucose,
          glu: reading.glucose!.round().toString(),
          width: 240,
        ),
      );
    }
  } else {
    photos.add(
      DeviceLcd(
        mode: mode,
        sys: sys ?? '--',
        dia: dia ?? '--',
        pul: pul ?? '--',
        glu: glu ?? '--',
        unit: unit,
        width: 250,
      ),
    );
  }

  final headerTitle = reading == null
      ? l.photoTitle
      : '${l.photoTitle} · ${l.dayTime(reading.time)}';

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.photoTitle,
    barrierColor: const Color(0xEB0F172A),
    transitionDuration: D.animMed,
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: D.animCurve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, a, b) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: Color(0xCC111827),
                  border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        headerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.h.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: l.close,
                      excludeSemantics: true,
                      child: Material(
                        color: const Color(0x26FFFFFF),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(ctx).pop();
                          },
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(48),
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: photos,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0x24FFFFFF),
                        borderRadius: D.radiusPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pinch_outlined, size: 15, color: C.onDark),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.pinchHint,
                              style: T.capSm.copyWith(color: C.onDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TactileButton(
                        label: l.close,
                        icon: Icons.close_rounded,
                        height: 52,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
