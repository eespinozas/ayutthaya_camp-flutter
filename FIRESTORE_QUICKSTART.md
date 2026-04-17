# 🚀 Firestore Optimization - Quick Start

## ⚡ Deploy en 5 Minutos

### 1. Deploy de Índices (2 minutos)

```bash
# Instalar Firebase CLI (si no la tienes)
npm install -g firebase-tools

# Login y seleccionar proyecto
firebase login
firebase use ayuthaya-camp

# Deploy índices
firebase deploy --only firestore:indexes
```

✅ **Listo!** Los índices se construirán en background (5-15 min)

---

### 2. Migrar Contadores de Capacidad (1 minuto)

```bash
# Ejecutar script de migración
python scripts/initialize_capacity_counters.py
```

✅ **Listo!** Contadores inicializados para todos los bookings existentes

---

### 3. Verificar que Todo Funciona (2 minutos)

#### Paso 3.1: Verificar Índices
1. Abre [Firebase Console](https://console.firebase.google.com/project/ayuthaya-camp/firestore/indexes)
2. Ve a **Firestore Database** → **Indexes**
3. Confirma que todos estén en **verde** (Enabled)

#### Paso 3.2: Verificar Contadores
1. En Firebase Console → Firestore Database
2. Abre un documento de `class_schedules`
3. Verás una subcolección `capacity_tracking` → ábrela
4. Deberías ver documentos como `2025-01-15` con `currentBookings: 5`

#### Paso 3.3: Probar en la App
1. Inicia sesión como usuario normal
2. Intenta agendar una clase
3. Si funciona sin errores → **✅ Todo OK!**

---

## 📊 ¿Qué Cambió?

| Componente | Cambio |
|------------|--------|
| **Índices** | Agregados en `firestore.indexes.json` |
| **Paginación** | Nuevo servicio en `lib/core/services/pagination_service.dart` |
| **Capacidad** | Contadores atómicos con transacciones en `booking_service.dart` |

---

## 🔧 Comandos Útiles

```bash
# Ver índices activos
firebase firestore:indexes

# Ver uso de Firestore
firebase firestore:usage

# Backup de Firestore (recomendado antes de cambios grandes)
gcloud firestore export gs://ayuthaya-camp-backups/$(date +%Y%m%d)
```

---

## ⚠️ Troubleshooting

### Error: "The query requires an index"
**Solución:** Los índices aún se están construyendo. Espera 5-15 minutos.

### Error: "PERMISSION_DENIED" al crear booking
**Solución:** Verifica las reglas de Firestore permiten escribir en `capacity_tracking`:
```javascript
// En firestore.rules, agregar:
match /class_schedules/{scheduleId}/capacity_tracking/{date} {
  allow read: if request.auth != null;
  allow write: if false; // Solo desde código server-side
}
```

### Los contadores están en 0
**Solución:** Ejecuta el script de migración:
```bash
python scripts/initialize_capacity_counters.py
```

---

## 📚 Documentación Completa

Lee **[FIRESTORE_OPTIMIZATION_GUIDE.md](FIRESTORE_OPTIMIZATION_GUIDE.md)** para:
- Explicación detallada de cada optimización
- Arquitectura del sistema de contadores
- Scripts de mantenimiento
- FAQ y mejores prácticas

---

## 🎯 Checklist Post-Deploy

- [ ] Índices desplegados y en estado "Enabled"
- [ ] Contadores de capacidad inicializados
- [ ] App compila sin errores
- [ ] Crear booking funciona correctamente
- [ ] Cancelar booking funciona correctamente
- [ ] Paginación en admin alumnos funciona
- [ ] Monitorear logs por 24h para errores

---

**¿Problemas?** Abre un issue o revisa la documentación completa.
