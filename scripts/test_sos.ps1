# Run SOS-focused automated tests for customer and provider flows.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Core = Join-Path $Root "packages\boostdrive_core"
$Services = Join-Path $Root "packages\boostdrive_services"
$Mobile = Join-Path $Root "apps\Mobile"

function Run-FlutterTest {
    param([string]$Path, [string]$Label, [string]$Target = "")

    Write-Host ""
    Write-Host "==> $Label"
    Push-Location $Path
    try {
        flutter pub get | Out-Host
        if ($Target -ne "") {
            flutter test $Target | Out-Host
        } else {
            flutter test | Out-Host
        }
        if ($LASTEXITCODE -ne 0) { throw "Tests failed in $Path" }
    }
    finally {
        Pop-Location
    }
}

Write-Host "BoostDrive SOS test runner"

Run-FlutterTest -Path $Core -Label "SOS rules (core)" -Target "test/unit"
Run-FlutterTest -Path $Mobile -Label "SOS mobile widget and unit tests" -Target "test/unit/sos_provider_orders_filter_test.dart"
Run-FlutterTest -Path $Mobile -Label "SOS provider detail widget tests" -Target "test/widget/sos_provider_detail_test.dart"
Run-FlutterTest -Path $Mobile -Label "SOS customer hub widget tests" -Target "test/widget/sos_customer_hub_test.dart"

Write-Host ""
Write-Host "All SOS tests passed."
