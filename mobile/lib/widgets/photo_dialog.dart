import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'device_lcd.dart';
import 'tactile_button.dart';

/// Lightbox for the device photo kept with a reading (pinch to zoom).
Future<void> showPhotoDialog(BuildContext context, {Reading? reading, DeviceMode mode = DeviceMode.bp, String? sys, String? dia, String? pul, String? glu, String unit = 'mg/dL'}) {
  final l = L.of(context);
  final photos = <Widget>[];
  if (reading != null) {
    if (reading.photoBp && reading.hasBp) {
      photos.add(DeviceLcd(mode: DeviceMode.bp, sys: '${reading.systolic}', dia: '${reading.diastolic}', pul: '${reading.pulse ?? '--'}', width: 220));
    }
    if (reading.photoGlucose && reading.glucose != null) {
      photos.add(DeviceLcd(mode: DeviceMode.glucose, glu: reading.glucose!.round().toString(), width: 220));
    }
  } else {
    photos.add(DeviceLcd(mode: mode, sys: sys ?? '--', dia: dia ?? '--', pul: pul ?? '--', glu: glu ?? '--', unit: unit, width: 240));
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l.photoTitle,
    barrierColor: const Color(0xD9000000),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (ctx, a, b) => SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: C.panelHeader,
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_outlined, color: C.text),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reading == null ? l.photoTitle : '${l.photoTitle} · ${l.dayTime(reading.time)}', style: T.h)),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center, children: photos),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  Text(l.pinchHint, style: T.cap.copyWith(color: C.onDark)),
                  const SizedBox(height: 10),
                  TactileButton(label: l.close, icon: Icons.close, onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
