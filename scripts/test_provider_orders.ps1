# Run automated tests for the service provider Orders feature (mobile).
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Core = Join-Path $Root "packages\boostdrive_core"
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

Write-Host "BoostDrive provider Orders test runner"

Run-FlutterTest -Path $Core -Label "SOS pool filter (core)" -Target "test/unit/sos_rules_test.dart"
Run-FlutterTest -Path $Mobile -Label "Provider orders filter unit test" -Target "test/unit/sos_provider_orders_filter_test.dart"
Run-FlutterTest -Path $Mobile -Label "Provider orders page widget tests" -Target "test/widget/provider_orders_page_test.dart"

Write-Host ""
Write-Host "All provider Orders tests passed."
