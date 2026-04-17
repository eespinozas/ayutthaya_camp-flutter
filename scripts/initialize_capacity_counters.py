#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para inicializar los contadores de capacidad (capacity_tracking)
basándose en los bookings existentes en Firestore.

Este script debe ejecutarse UNA VEZ después de implementar el sistema
de transacciones atómicas para verificación de capacidad.

Uso:
  python scripts/initialize_capacity_counters.py [ruta_al_service_account.json]
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
from collections import defaultdict

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def main():
    print("=" * 60)
    print("INICIALIZACIÓN DE CONTADORES DE CAPACIDAD")
    print("=" * 60)
    print("\n📋 Este script:")
    print("  1. Lee todos los bookings confirmados existentes")
    print("  2. Agrupa por (scheduleId, classDate)")
    print("  3. Crea documentos en capacity_tracking con el conteo actual")
    print()

    # Determinar ruta del service account
    service_account_path = None

    if len(sys.argv) > 1:
        service_account_path = sys.argv[1]
        print(f'Usando service account desde argumento: {service_account_path}')
    elif 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
        service_account_path = os.environ['FIREBASE_SERVICE_ACCOUNT']
        print(f'Usando service account desde variable de entorno: {service_account_path}')
    else:
        service_account_path = 'scripts/firebase-service-account.json'
        print(f'Usando service account por defecto: {service_account_path}')

    # Verificar que el archivo existe
    if not os.path.exists(service_account_path):
        print(f'\n❌ ERROR: No se encontró el archivo: {service_account_path}')
        print('\nUso:')
        print('  python scripts/initialize_capacity_counters.py [ruta_al_service_account.json]')
        print('  O configura la variable de entorno FIREBASE_SERVICE_ACCOUNT')
        sys.exit(1)

    # Inicializar Firebase Admin SDK
    try:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase inicializado correctamente\n")
    except Exception as e:
        print(f"❌ ERROR al inicializar Firebase: {e}")
        sys.exit(1)

    db = firestore.client()

    # 1. Obtener todos los bookings confirmados
    print("[1/4] Obteniendo bookings confirmados...")
    bookings = db.collection('bookings').where('status', '==', 'confirmed').get()
    print(f"✅ Total de bookings confirmados: {len(bookings)}\n")

    if len(bookings) == 0:
        print("✅ No hay bookings confirmados para procesar")
        return

    # 2. Agrupar por (scheduleId, classDate)
    print("[2/4] Agrupando por horario y fecha...")
    counters = defaultdict(lambda: {
        'count': 0,
        'scheduleId': None,
        'classDate': None,
        'dateKey': None
    })

    for booking_doc in bookings:
        data = booking_doc.data()
        schedule_id = data.get('scheduleId')
        class_date_timestamp = data.get('classDate')

        if not schedule_id or not class_date_timestamp:
            print(f"⚠️  Booking {booking_doc.id} sin scheduleId o classDate, omitiendo...")
            continue

        # Convertir Timestamp a datetime
        class_date = class_date_timestamp.to_pydatetime().date()
        date_key = class_date.strftime('%Y-%m-%d')

        key = f"{schedule_id}_{date_key}"
        counters[key]['count'] += 1
        counters[key]['scheduleId'] = schedule_id
        counters[key]['classDate'] = class_date_timestamp
        counters[key]['dateKey'] = date_key

    print(f"✅ Encontradas {len(counters)} clases únicas con reservas\n")

    # 3. Obtener capacidades máximas de los schedules
    print("[3/4] Obteniendo capacidades máximas...")
    schedules_capacity = {}

    for counter_info in counters.values():
        schedule_id = counter_info['scheduleId']
        if schedule_id not in schedules_capacity:
            try:
                schedule_doc = db.collection('class_schedules').document(schedule_id).get()
                if schedule_doc.exists:
                    schedules_capacity[schedule_id] = schedule_doc.to_dict().get('capacity', 15)
                else:
                    schedules_capacity[schedule_id] = 15  # Default
                    print(f"⚠️  Schedule {schedule_id} no encontrado, usando capacidad por defecto: 15")
            except Exception as e:
                print(f"⚠️  Error obteniendo schedule {schedule_id}: {e}")
                schedules_capacity[schedule_id] = 15

    print(f"✅ Capacidades obtenidas para {len(schedules_capacity)} horarios\n")

    # 4. Crear documentos de capacity_tracking
    print("[4/4] Creando documentos de capacity_tracking...")
    batch = db.batch()
    count = 0
    total_processed = 0

    for key, info in counters.items():
        schedule_id = info['scheduleId']
        date_key = info['dateKey']
        max_capacity = schedules_capacity.get(schedule_id, 15)

        # Crear documento de tracking
        capacity_ref = (db.collection('class_schedules')
                        .document(schedule_id)
                        .collection('capacity_tracking')
                        .document(date_key))

        batch.set(capacity_ref, {
            'currentBookings': info['count'],
            'maxCapacity': max_capacity,
            'lastUpdated': firestore.SERVER_TIMESTAMP,
            'scheduleId': schedule_id,
            'classDate': info['classDate'],
        })

        count += 1
        total_processed += 1

        # Firestore batch límite: 500 operaciones
        if count >= 500:
            try:
                batch.commit()
                print(f"  ✅ Procesados {total_processed} documentos (batch de 500)")
                batch = db.batch()
                count = 0
            except Exception as e:
                print(f"  ❌ Error en batch commit: {e}")
                sys.exit(1)

    # Commit final
    if count > 0:
        try:
            batch.commit()
            print(f"  ✅ Procesados últimos {count} documentos")
        except Exception as e:
            print(f"  ❌ Error en batch commit final: {e}")
            sys.exit(1)

    # Resumen
    print("\n" + "=" * 60)
    print("✅ MIGRACIÓN COMPLETADA")
    print("=" * 60)
    print(f"Total de contadores inicializados: {total_processed}")
    print(f"Total de bookings procesados: {len(bookings)}")
    print()
    print("📋 Próximos pasos:")
    print("  1. Verifica en Firebase Console → class_schedules/{id}/capacity_tracking")
    print("  2. Prueba crear un nuevo booking desde la app")
    print("  3. Verifica que el contador se incrementa correctamente")
    print()

if __name__ == '__main__':
    main()
