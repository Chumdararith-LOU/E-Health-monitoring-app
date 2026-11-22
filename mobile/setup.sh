#!/usr/bin/env bash
# One-time setup on macOS / Linux. Run from this folder:  bash setup.sh
set -e
echo "1/3  Creating the Android + iOS project files (your lib/ code is kept)..."
flutter create --org com.kongvong --project-name ehealth_mobile --platforms=android,ios .
echo "2/3  Downloading packages..."
flutter pub get
echo "3/3  Setting the app name to E-Health..."
dart run tool/set_app_name.dart
echo ""
echo "Done. Plug in your phone (USB debugging on) and run:  flutter run"
