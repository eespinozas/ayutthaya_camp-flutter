# 🔐 Android Signing Setup - Quick Guide

Guía rápida para configurar la firma de tu app Android.

---

## ⚡ Configuración Automática (Recomendado)

Ejecuta el script interactivo que te guiará paso a paso:

```bash
./scripts/setup_android_signing.sh
```

El script automáticamente:
- ✅ Crea el keystore (upload-keystore.jks)
- ✅ Genera android/key.properties
- ✅ Convierte keystore a base64 para GitHub
- ✅ Te muestra los valores de GitHub Secrets
- ✅ Verifica que .gitignore esté configurado

**Tiempo estimado: 3 minutos**

---

## 🔧 Configuración Manual

Si prefieres hacerlo manualmente:

### 1. Crear Keystore

```bash
cd android/app

keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS
```

Anota las passwords que uses.

### 2. Crear key.properties

Copia el template y edita con tus valores:

```bash
cd android
cp key.properties.template key.properties
```

Edita `android/key.properties`:

```properties
storePassword=TU_KEYSTORE_PASSWORD
keyPassword=TU_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3. Convertir a Base64 para GitHub

**Windows PowerShell:**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks"))
```

**Linux/macOS:**
```bash
cat android/app/upload-keystore.jks | base64 | tr -d '\n'
```

### 4. Configurar GitHub Secrets

Ve a: **Settings → Secrets and variables → Actions → New repository secret**

Agrega estos secrets:

| Secret | Valor |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Output del comando base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Tu keystore password |
| `ANDROID_KEY_PASSWORD` | Tu key password |
| `ANDROID_KEY_ALIAS` | `upload` |

---

## ✅ Verificar Configuración

Prueba que la firma funciona localmente:

```bash
flutter build appbundle --release
```

Si builds correctamente, la firma está configurada ✅

---

## 🔍 Troubleshooting

### Error: "key.properties not found"

**Solución:**
```bash
# Verifica que existe
ls -la android/key.properties

# Si no existe, créalo desde el template
cp android/key.properties.template android/key.properties
# Luego edita con tus valores
```

### Error: "Keystore was tampered with, or password was incorrect"

**Solución:**
- Verifica que las passwords en `key.properties` sean correctas
- Asegúrate de que `storePassword` y `keyPassword` coincidan con las que usaste al crear el keystore

### Error: "Certificate chain not found for: upload"

**Solución:**
- Verifica que el `keyAlias` en `key.properties` sea correcto (default: `upload`)
- Si usaste otro alias al crear el keystore, actualiza `key.properties`

---

## ⚠️ Seguridad

### ✅ Archivos PROTEGIDOS por .gitignore

Estos archivos **NUNCA** deben commitearse:

- ✅ `android/key.properties` - Contiene passwords
- ✅ `android/app/upload-keystore.jks` - Keystore privado
- ✅ `android/app/*.jks` - Cualquier keystore
- ✅ `*.p12` - Certificados iOS

### 🔒 Backup del Keystore

**CRÍTICO:** Sin el keystore NO puedes actualizar la app en Google Play.

Guarda una copia segura en:
- ☁️ Cloud storage (Google Drive, Dropbox, etc.)
- 🔑 Password manager (1Password, LastPass, etc.)
- 💾 Disco externo encriptado

---

## 📋 Checklist

Verifica que hayas completado:

- [ ] Keystore creado en `android/app/upload-keystore.jks`
- [ ] `android/key.properties` configurado
- [ ] Passwords guardadas en lugar seguro
- [ ] GitHub Secrets configurados (4 secrets)
- [ ] Keystore respaldado en lugar seguro
- [ ] Build de release funciona: `flutter build appbundle --release`

---

## 📚 Referencias

- **CI/CD completo:** [CI_CD_SETUP.md](CI_CD_SETUP.md)
- **Guía rápida:** [CI_CD_QUICK_START.md](CI_CD_QUICK_START.md)
- **Android Docs:** https://developer.android.com/studio/publish/app-signing
- **Flutter Deployment:** https://docs.flutter.dev/deployment/android

---

**¡Tu firma de Android está lista para producción!** ✅
