#!/bin/bash

# ========================================
# Android Signing Setup Script
# ========================================
# This script helps you create a keystore for Android app signing
# and configure the local development environment.
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEYSTORE_DIR="$PROJECT_ROOT/android/app"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"
KEY_PROPERTIES="$PROJECT_ROOT/android/key.properties"

echo "========================================="
echo "🔐 Android Signing Setup"
echo "========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ ERROR: keytool not found!"
    echo ""
    echo "keytool comes with Java JDK. Please install Java JDK first:"
    echo "  - Download from: https://www.oracle.com/java/technologies/downloads/"
    echo "  - Or install via package manager (brew, apt, etc.)"
    exit 1
fi

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Keystore already exists at:"
    echo "   $KEYSTORE_FILE"
    echo ""
    read -p "Do you want to overwrite it? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        echo "❌ Aborted."
        exit 1
    fi
    echo "🗑️  Removing existing keystore..."
    rm -f "$KEYSTORE_FILE"
fi

echo "📋 This script will create a new Android keystore for signing your app."
echo ""
echo "⚠️  IMPORTANT: Save the passwords and alias you choose!"
echo "   Without them, you cannot update your app in Google Play."
echo ""
echo "========================================="
echo "Enter Keystore Information"
echo "========================================="
echo ""

# Get alias
read -p "Key alias (default: upload): " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-upload}

# Get validity
read -p "Validity in years (default: 25): " VALIDITY_YEARS
VALIDITY_YEARS=${VALIDITY_YEARS:-25}
VALIDITY_DAYS=$((VALIDITY_YEARS * 365))

echo ""
echo "📝 You will be prompted to enter:"
echo "   1. Keystore password (choose a strong password)"
echo "   2. Key password (can be the same as keystore password)"
echo "   3. Your name and organization details"
echo ""
read -p "Press Enter to continue..."
echo ""

# Create keystore
echo "🔨 Creating keystore..."
keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -keyalg RSA \
    -keysize 2048 \
    -validity $VALIDITY_DAYS \
    -alias "$KEY_ALIAS" \
    -storetype JKS

if [ $? -ne 0 ]; then
    echo "❌ Failed to create keystore"
    exit 1
fi

echo ""
echo "✅ Keystore created successfully!"
echo "   Location: $KEYSTORE_FILE"
echo ""

# Get passwords for key.properties
echo "========================================="
echo "Configure key.properties"
echo "========================================="
echo ""
echo "Please enter the passwords you just used (they will not be displayed)"
echo ""

read -sp "Keystore password: " STORE_PASSWORD
echo ""
read -sp "Key password: " KEY_PASSWORD
echo ""
echo ""

# Create key.properties
cat > "$KEY_PROPERTIES" <<EOF
# Android Signing Configuration
# ⚠️  DO NOT COMMIT THIS FILE TO GIT
# This file contains sensitive credentials

storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=upload-keystore.jks
EOF

echo "✅ Created key.properties at:"
echo "   $KEY_PROPERTIES"
echo ""

# Convert to base64 for GitHub Secrets
echo "========================================="
echo "GitHub Secrets Setup"
echo "========================================="
echo ""
echo "For CI/CD, you need to add the keystore as a GitHub Secret."
echo "Converting keystore to base64..."
echo ""

if command -v base64 &> /dev/null; then
    BASE64_OUTPUT=$(cat "$KEYSTORE_FILE" | base64 | tr -d '\n')

    echo "✅ Keystore converted to base64"
    echo ""
    echo "📋 Add these secrets to GitHub:"
    echo "   Settings → Secrets and variables → Actions → New repository secret"
    echo ""
    echo "1. ANDROID_KEYSTORE_BASE64"
    echo "   Copy the following value (click to select all):"
    echo "   ----------------------------------------"
    echo "$BASE64_OUTPUT"
    echo "   ----------------------------------------"
    echo ""
    echo "2. ANDROID_KEYSTORE_PASSWORD"
    echo "   Value: $STORE_PASSWORD"
    echo ""
    echo "3. ANDROID_KEY_PASSWORD"
    echo "   Value: $KEY_PASSWORD"
    echo ""
    echo "4. ANDROID_KEY_ALIAS"
    echo "   Value: $KEY_ALIAS"
    echo ""
else
    echo "⚠️  base64 command not found."
    echo "   To convert manually (Windows PowerShell):"
    echo "   [Convert]::ToBase64String([IO.File]::ReadAllBytes(\"$KEYSTORE_FILE\"))"
    echo ""
    echo "   Or (Linux/macOS):"
    echo "   cat \"$KEYSTORE_FILE\" | base64 | tr -d '\\n'"
    echo ""
fi

# Verify .gitignore
echo "========================================="
echo "Verify .gitignore"
echo "========================================="
echo ""

GITIGNORE="$PROJECT_ROOT/.gitignore"

if grep -q "key.properties" "$GITIGNORE" 2>/dev/null; then
    echo "✅ .gitignore already contains key.properties"
else
    echo "⚠️  Adding key.properties to .gitignore"
    echo "" >> "$GITIGNORE"
    echo "# Android signing files" >> "$GITIGNORE"
    echo "android/key.properties" >> "$GITIGNORE"
    echo "android/app/upload-keystore.jks" >> "$GITIGNORE"
fi

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. ✅ Keystore created at: android/app/upload-keystore.jks"
echo "2. ✅ key.properties configured"
echo "3. 📋 Copy the GitHub Secrets from above"
echo "4. 🔐 Store your passwords in a safe place (password manager)"
echo ""
echo "⚠️  CRITICAL: Backup your keystore!"
echo "   Without it, you cannot update your app in Google Play Store."
echo "   Store it in a secure location (cloud storage, password manager, etc.)"
echo ""
echo "Test your local build:"
echo "   flutter build appbundle --release"
echo ""
