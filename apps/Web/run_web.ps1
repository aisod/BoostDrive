# Helper script to run Flutter Web while bypassing the DartWorker: 22 crash
# This crash is caused by spaces in the parent directory path on Windows.

Write-Host "Launching BoostDrive Web with --no-pub workaround..." -ForegroundColor Cyan
flutter run -d chrome --no-pub
