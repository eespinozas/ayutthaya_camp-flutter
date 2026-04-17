# ========================================
# Android Signing Setup Script (PowerShell)
# ========================================
# This script helps you create a keystore for Android app signing
# and configure the local development environment.
# ========================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

$KeystoreDir = Join-Path $ProjectRoot "android\app"
$KeystoreFile = Join-Path $KeystoreDir "upload-keystore.jks"
$KeyProperties = Join-Path $ProjectRoot "android\key.properties"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Android Signing Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if keytool is available
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host "ERROR: keytool not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "keytool comes with Java JDK. Please install Java JDK first:"
    Write-Host "  - Download from: https://www.oracle.com/java/technologies/downloads/"
    Write-Host "  - Or install via: winget install Oracle.JDK.17"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if keystore already exists
if (Test-Path $KeystoreFile) {
    Write-Host "WARNING: Keystore already exists at:" -ForegroundColor Yellow
    Write-Host "   $KeystoreFile"
    Write-Host ""
    $response = Read-Host "Do you want to overwrite it? (yes/no)"
    if ($response -notmatch '^[Yy]es$') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
    Write-Host "Removing existing keystore..." -ForegroundColor Yellow
    Remove-Item $KeystoreFile -Force
}

Write-Host "This script will create a new Android keystore for signing your app." -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Save the passwords and alias you choose!" -ForegroundColor Yellow
Write-Host "Without them, you cannot update your app in Google Play." -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Enter Keystore Information" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get alias
$KeyAlias = Read-Host "Key alias (default: upload)"
if ([string]::IsNullOrWhiteSpace($KeyAlias)) {
    $KeyAlias = "upload"
}

# Get validity
$ValidityYearsInput = Read-Host "Validity in years (default: 25)"
if ([string]::IsNullOrWhiteSpace($ValidityYearsInput)) {
    $ValidityYears = 25
} else {
    $ValidityYears = [int]$ValidityYearsInput
}
$ValidityDays = $ValidityYears * 365

Write-Host ""
Write-Host "You will be prompted to enter:" -ForegroundColor White
Write-Host "   1. Keystore password (choose a strong password)" -ForegroundColor White
Write-Host "   2. Key password (can be the same as keystore password)" -ForegroundColor White
Write-Host "   3. Your name and organization details" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to continue"
Write-Host ""

# Create keystore
Write-Host "Creating keystore..." -ForegroundColor Cyan
$keytoolArgs = @(
    "-genkey", "-v",
    "-keystore", $KeystoreFile,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", $ValidityDays,
    "-alias", $KeyAlias,
    "-storetype", "JKS"
)

& keytool $keytoolArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create keystore" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "SUCCESS: Keystore created!" -ForegroundColor Green
Write-Host "   Location: $KeystoreFile" -ForegroundColor White
Write-Host ""

# Get passwords for key.properties
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Configure key.properties" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please enter the passwords you just used" -ForegroundColor White
Write-Host ""

$StorePassword = Read-Host "Keystore password" -AsSecureString
$StorePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorePassword))

$KeyPassword = Read-Host "Key password" -AsSecureString
$KeyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPassword))

Write-Host ""

# Create key.properties
$keyPropertiesContent = @"
# Android Signing Configuration
# WARNING: DO NOT COMMIT THIS FILE TO GIT
# This file contains sensitive credentials

storePassword=$StorePasswordPlain
keyPassword=$KeyPasswordPlain
keyAlias=$KeyAlias
storeFile=upload-keystore.jks
"@

Set-Content -Path $KeyProperties -Value $keyPropertiesContent -Encoding UTF8

Write-Host "SUCCESS: Created key.properties at:" -ForegroundColor Green
Write-Host "   $KeyProperties" -ForegroundColor White
Write-Host ""

# Convert to base64 for GitHub Secrets
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "GitHub Secrets Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "For CI/CD, you need to add the keystore as a GitHub Secret." -ForegroundColor White
Write-Host "Converting keystore to base64..." -ForegroundColor White
Write-Host ""

$KeystoreBytes = [System.IO.File]::ReadAllBytes($KeystoreFile)
$Base64String = [System.Convert]::ToBase64String($KeystoreBytes)

Write-Host "SUCCESS: Keystore converted to base64" -ForegroundColor Green
Write-Host ""
Write-Host "Add these secrets to GitHub:" -ForegroundColor Cyan
Write-Host "Settings -> Secrets and variables -> Actions -> New repository secret" -ForegroundColor White
Write-Host ""
Write-Host "1. ANDROID_KEYSTORE_BASE64" -ForegroundColor Yellow
Write-Host "   Copy the following value:" -ForegroundColor White
Write-Host "   ----------------------------------------" -ForegroundColor Gray
Write-Host $Base64String -ForegroundColor White
Write-Host "   ----------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "2. ANDROID_KEYSTORE_PASSWORD" -ForegroundColor Yellow
Write-Host "   Value: $StorePasswordPlain" -ForegroundColor White
Write-Host ""
Write-Host "3. ANDROID_KEY_PASSWORD" -ForegroundColor Yellow
Write-Host "   Value: $KeyPasswordPlain" -ForegroundColor White
Write-Host ""
Write-Host "4. ANDROID_KEY_ALIAS" -ForegroundColor Yellow
Write-Host "   Value: $KeyAlias" -ForegroundColor White
Write-Host ""

# Verify .gitignore
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Verify .gitignore" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$GitignorePath = Join-Path $ProjectRoot ".gitignore"

if (Test-Path $GitignorePath) {
    $gitignoreContent = Get-Content $GitignorePath -Raw
    if ($gitignoreContent -match "key\.properties") {
        Write-Host "SUCCESS: .gitignore already contains key.properties" -ForegroundColor Green
    } else {
        Write-Host "Adding key.properties to .gitignore" -ForegroundColor Yellow
        Add-Content -Path $GitignorePath -Value "`n# Android signing files`nandroid/key.properties`nandroid/app/upload-keystore.jks`n"
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Keystore created at: android\app\upload-keystore.jks" -ForegroundColor Green
Write-Host "2. key.properties configured" -ForegroundColor Green
Write-Host "3. Copy the GitHub Secrets from above" -ForegroundColor Yellow
Write-Host "4. Store your passwords in a safe place (password manager)" -ForegroundColor Yellow
Write-Host ""
Write-Host "CRITICAL: Backup your keystore!" -ForegroundColor Red
Write-Host "Without it, you cannot update your app in Google Play Store." -ForegroundColor Yellow
Write-Host "Store it in a secure location (cloud storage, password manager, etc.)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Test your local build:" -ForegroundColor White
Write-Host "   flutter build appbundle --release" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
