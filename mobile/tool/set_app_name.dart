// Run once after `flutter create .` to show "E-Health" under the app icon
// on Android and iPhone:   dart run tool/set_app_name.dart

import 'dart:io';

void _patch(String path, Pattern from, String to) {
  final f = File(path);
  if (!f.existsSync()) {
    stdout.writeln('skip (not found): $path');
    return;
  }
  final before = f.readAsStringSync();
  final after = before.replaceAll(from, to);
  if (before == after) {
    stdout.writeln('already set: $path');
    return;
  }
  f.writeAsStringSync(after);
  stdout.writeln('updated: $path');
}

void main() {
  _patch(
    'android/app/src/main/AndroidManifest.xml',
    RegExp(r'android:label="[^"]*"'),
    'android:label="E-Health"',
  );
  _patch(
    'ios/Runner/Info.plist',
    RegExp(r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>'),
    '<key>CFBundleDisplayName</key>\n\t<string>E-Health</string>',
  );
  // Portrait only on iPhone too (Android is locked in main.dart).
  _patch(
    'ios/Runner/Info.plist',
    RegExp(r'<key>UISupportedInterfaceOrientations</key>\s*<array>[\s\S]*?</array>'),
    '<key>UISupportedInterfaceOrientations</key>\n\t<array>\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t</array>',
  );
}
