# 🚀 Testing Quick Start

## ⚡ Ejecutar Tests en 30 Segundos

### Windows (PowerShell)
```powershell
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar todos los tests
.\scripts\run_tests.ps1

# O directamente:
flutter test
```

### Linux/macOS (Bash)
```bash
# 1. Dar permisos de ejecución
chmod +x scripts/run_tests.sh

# 2. Ejecutar todos los tests
./scripts/run_tests.sh

# O directamente:
flutter test
```

---

## 📊 Comandos Útiles

### Ejecutar Tests
```bash
# Todos los tests
flutter test

# Con cobertura
.\scripts\run_tests.ps1 coverage

# Un test específico
flutter test test/features/bookings/services/booking_service_test.dart

# Modo watch (re-ejecuta al guardar)
flutter test --watch
```

### Ver Cobertura
```bash
# Generar y abrir reporte HTML
.\scripts\run_tests.ps1 coverage

# Solo ejecutar con cobertura
flutter test --coverage

# Verificar threshold mínimo (60%)
.\scripts\run_tests.ps1 threshold 60
```

---

## 📁 Archivos de Tests Creados

```
test/
├── core/
│   └── services/
│       └── pagination_service_test.dart  ✅ 9 tests
├── features/
    ├── bookings/
    │   ├── models/
    │   │   └── booking_test.dart          ✅ 15 tests
    │   └── services/
    │       └── booking_service_test.dart   ✅ 12 tests
    └── payments/
        └── models/
            └── payment_test.dart           ✅ 14 tests

TOTAL: 50+ test cases
```

---

## ✅ Verificar que Todo Funciona

```powershell
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar todos los tests
flutter test

# Deberías ver algo como:
# 00:02 +50: All tests passed!
```

Si ves errores, revisa:
1. ¿Instalaste las dependencias? (`flutter pub get`)
2. ¿Tienes Flutter actualizado? (`flutter upgrade`)
3. ¿Los imports son correctos en los tests?

---

## 🎯 Próximos Pasos

1. **Lee la estrategia completa:** [TESTING_STRATEGY.md](TESTING_STRATEGY.md)

2. **Agrega más tests:**
   - PaymentService
   - ViewModels
   - Widgets

3. **Configura CI/CD:**
   - GitHub Actions
   - Verificación automática en PRs

4. **Monitorea cobertura:**
   - Objetivo: 60%+
   - Usa `flutter test --coverage`

---

## 📚 Documentación

- **[TESTING_STRATEGY.md](TESTING_STRATEGY.md)** - Estrategia completa de testing
- **[FIRESTORE_OPTIMIZATION_GUIDE.md](FIRESTORE_OPTIMIZATION_GUIDE.md)** - Optimizaciones implementadas

---

## 🐛 Troubleshooting

### Error: "No tests found"
**Solución:** Verifica que los archivos terminen en `_test.dart`

### Error: "package:ayutthaya_camp not found"
**Solución:** Ejecuta `flutter pub get`

### Error: "firebase_core not initialized"
**Solución:** Los tests usan mocks, no necesitan Firebase real

### Tests muy lentos
**Solución:** Ejecuta solo los tests que necesitas:
```bash
flutter test test/features/bookings/
```

---

**¿Problemas?** Abre un issue o revisa la documentación completa.
