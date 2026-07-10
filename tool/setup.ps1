$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter was not found. Install Flutter 3.41 or newer and add it to PATH."
}

if (-not (Test-Path "android")) {
  Write-Host "Generating the Android platform project..."
  flutter create --platforms=android --org com.tan15hacks --project-name one_bit_game .
}

flutter pub get
flutter doctor
Write-Host "Setup complete. Run: flutter run"
