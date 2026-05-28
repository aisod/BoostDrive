# Run automated tests for the BoostDrive mobile app and its UI dependencies.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Mobile = Join-Path $Root "apps\Mobile"
$Ui = Join-Path $Root "packages\boostdrive_ui"
$Core = Join-Path $Root "packages\boostdrive_core"
$Services = Join-Path $Root "packages\boostdrive_services"
$Auth = Join-Path $Root "packages\boostdrive_auth"

function Run-FlutterTest {
    param(
        [string]$Path,
        [string]$Label
    )

    Write-Host ""
    Write-Host "==> $Label"
    Push-Location $Path
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "Tests failed in $Path"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "BoostDrive mobile test runner"
Write-Host "Root: $Root"

Run-FlutterTest -Path $Core -Label "boostdrive_core"
Run-FlutterTest -Path $Services -Label "boostdrive_services"
Run-FlutterTest -Path $Auth -Label "boostdrive_auth"
Run-FlutterTest -Path $Ui -Label "boostdrive_ui"
Run-FlutterTest -Path $Mobile -Label "mobile app"

Write-Host ""
Write-Host "All mobile-related tests passed."
