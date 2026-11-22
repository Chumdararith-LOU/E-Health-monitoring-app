@echo off
REM One-time setup on Windows. Double-click or run from this folder:  setup.bat
echo 1/3  Creating the Android + iOS project files (your lib\ code is kept)...
call flutter create --org com.kongvong --project-name ehealth_mobile --platforms=android,ios .
if errorlevel 1 goto :fail
echo 2/3  Downloading packages...
call flutter pub get
if errorlevel 1 goto :fail
echo 3/3  Setting the app name to E-Health...
call dart run tool/set_app_name.dart
echo.
echo Done. Plug in your phone (USB debugging on) and run:  flutter run
goto :eof
:fail
echo Setup stopped. Run "flutter doctor" and fix what it reports, then try again.
