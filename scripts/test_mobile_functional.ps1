# Run all mobile functionality tests: packages, SOS, provider Orders, and full app widget/unit suite.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

function Invoke-Step {
    param([string]$Label, [scriptblock]$Action)

    Write-Host ""
    Write-Host "========================================"
    Write-Host "  $Label"
    Write-Host "========================================"
    & $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $Label"
    }
}

Write-Host "BoostDrive mobile functionality test runner"
Write-Host "Root: $Root"

Invoke-Step "Core package" {
    Push-Location (Join-Path $Root "packages\boostdrive_core")
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
    } finally { Pop-Location }
}

Invoke-Step "Services package" {
    Push-Location (Join-Path $Root "packages\boostdrive_services")
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
    } finally { Pop-Location }
}

Invoke-Step "Auth package" {
    Push-Location (Join-Path $Root "packages\boostdrive_auth")
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
    } finally { Pop-Location }
}

Invoke-Step "UI package (logistics + theme)" {
    Push-Location (Join-Path $Root "packages\boostdrive_ui")
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
    } finally { Pop-Location }
}

Invoke-Step "SOS flows (customer + provider)" {
    & (Join-Path $Root "scripts\test_sos.ps1")
}

Invoke-Step "Provider Orders" {
    & (Join-Path $Root "scripts\test_provider_orders.ps1")
}

Invoke-Step "Mobile app (all unit + widget tests)" {
    Push-Location (Join-Path $Root "apps\Mobile")
    try {
        flutter pub get | Out-Host
        flutter test | Out-Host
    } finally { Pop-Location }
}

Invoke-Step "Mobile integration (app bootstrap)" {
    Push-Location (Join-Path $Root "apps\Mobile")
    try {
        # integration_test requires a single target device on Windows dev machines.
        $device = if ($env:FLUTTER_TEST_DEVICE) { $env:FLUTTER_TEST_DEVICE } else { "windows" }
        flutter test integration_test -d $device | Out-Host
    } finally { Pop-Location }
}

Write-Host ""
Write-Host "All mobile functionality tests passed."
