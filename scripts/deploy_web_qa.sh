#!/bin/bash
# Compila y despliega la web al hosting QA (ayutthaya-camp-qa.web.app).
# Además de compilar con APP_ENV=qa, parcha el service worker de FCM
# (web/firebase-messaging-sw.js tiene la config de PROD hardcodeada) para
# que los push en segundo plano funcionen contra el proyecto QA.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Compilando web (APP_ENV=qa) =="
flutter build web --release --dart-define=APP_ENV=qa

echo "== Parchando service worker con config QA =="
SW=build/web/firebase-messaging-sw.js
sed -i \
  -e 's/AIzaSyAvzSmDVLKNUxNaS-ia8YvU4m3TXFVf-ZE/AIzaSyDlRcHn32H4Vd_4g6GzzjHBAPiJMcS_Eu4/' \
  -e 's/ayuthaya-camp\.firebaseapp\.com/ayutthaya-camp-qa.firebaseapp.com/' \
  -e 's/"ayuthaya-camp"/"ayutthaya-camp-qa"/' \
  -e 's/ayuthaya-camp\.firebasestorage\.app/ayutthaya-camp-qa.firebasestorage.app/' \
  -e 's/611359423677/691167888702/g' \
  -e 's/1:691167888702:web:e16824168b1803b2afcbd4/1:691167888702:web:a89da14d54ddd6b2e2586f/' \
  "$SW"
grep -q 'ayutthaya-camp-qa' "$SW" || { echo "ERROR: el parche del SW no se aplicó"; exit 1; }

echo "== Desplegando hosting QA =="
firebase deploy -P ayutthaya-camp-qa --only hosting

echo "OK: https://ayutthaya-camp-qa.web.app"
