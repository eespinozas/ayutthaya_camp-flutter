#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para recrear los class_schedules con IDs descriptivos
Formato: LXV{hora} donde L=Lunes, X=Miércoles, V=Viernes
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def main():
    # Determinar ruta del service account
    service_account_path = 'scripts/firebase-service-account.json'
    if 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
        service_account_path = os.environ['FIREBASE_SERVICE_ACCOUNT']

    if not os.path.exists(service_account_path):
        print(f'ERROR: No se encontró el archivo: {service_account_path}')
        sys.exit(1)

    # Inicializar Firebase
    try:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase inicializado\n")
    except Exception as e:
        print(f"❌ Error al inicializar Firebase: {e}")
        sys.exit(1)

    db = firestore.client()

    # Definir los nuevos schedules con IDs descriptivos
    # Formato:
    # - LMXJV = Lunes, Martes, Miércoles, Jueves, Viernes
    # - LXV = Lunes, Miércoles, Viernes
    # - MJ = Martes, Jueves
    # - S = Sábado
    schedules = [
        # Lunes a Viernes - 07:00 (1 hora)
        {
            'id': 'LMXJV07',
            'time': '07:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [1, 2, 3, 4, 5],  # L, M, X, J, V
            'durationMinutes': 60,
        },
        # Lunes a Viernes - 08:00 (1.5 horas)
        {
            'id': 'LMXJV08',
            'time': '08:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [1, 2, 3, 4, 5],
            'durationMinutes': 90,
        },
        # Lunes a Viernes - 11:00 (1.5 horas)
        {
            'id': 'LMXJV11',
            'time': '11:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [1, 2, 3, 4, 5],
            'durationMinutes': 90,
        },
        # Lunes, Miércoles, Viernes - 18:30 (1.5 horas)
        {
            'id': 'LXV1830',
            'time': '18:30',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [1, 3, 5],
            'durationMinutes': 90,
        },
        # Lunes, Miércoles, Viernes - 20:00 (1.5 horas)
        {
            'id': 'LXV20',
            'time': '20:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [1, 3, 5],
            'durationMinutes': 90,
        },
        # Martes, Jueves - 18:00 (1.5 horas)
        {
            'id': 'MJ18',
            'time': '18:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [2, 4],
            'durationMinutes': 90,
        },
        # Martes, Jueves - 19:30 (1.5 horas)
        {
            'id': 'MJ1930',
            'time': '19:30',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [2, 4],
            'durationMinutes': 90,
        },
        # Sábado - 11:00 (2 horas)
        {
            'id': 'S11',
            'time': '11:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [6],
            'durationMinutes': 120,
        },
        # Sábado - 13:00 (2 horas)
        {
            'id': 'S13',
            'time': '13:00',
            'type': 'Muay Thai',
            'instructor': 'Francisco Poveda',
            'capacity': 15,
            'days': [6],
            'durationMinutes': 120,
        },
    ]

    # Paso 1: Obtener todos los schedules actuales para crear mapeo
    print("📋 Obteniendo schedules actuales...")
    current_schedules = db.collection('class_schedules').get()

    # Crear mapeo de hora -> ID actual
    old_id_map = {}
    for doc in current_schedules:
        data = doc.to_dict()
        time = data.get('time', '')
        old_id_map[time] = doc.id
        print(f"   {doc.id} -> {time}")

    # Paso 2: Crear mapeo de ID antiguo -> ID nuevo
    id_mapping = {}
    for schedule in schedules:
        time = schedule['time']
        new_id = schedule['id']
        if time in old_id_map:
            old_id = old_id_map[time]
            id_mapping[old_id] = new_id
            print(f"   Mapeo: {old_id} -> {new_id} ({time})")

    # Paso 3: Actualizar todas las bookings con los nuevos IDs
    print("\n🔄 Actualizando bookings...")
    bookings = db.collection('bookings').get()
    bookings_updated = 0

    for booking_doc in bookings:
        booking_data = booking_doc.to_dict()
        old_schedule_id = booking_data.get('scheduleId', '')

        if old_schedule_id in id_mapping:
            new_schedule_id = id_mapping[old_schedule_id]

            db.collection('bookings').document(booking_doc.id).update({
                'scheduleId': new_schedule_id,
                'updatedAt': firestore.SERVER_TIMESTAMP,
            })

            bookings_updated += 1
            print(f"   ✅ Booking actualizada: {old_schedule_id} -> {new_schedule_id}")

    print(f"\n✅ Total de bookings actualizadas: {bookings_updated}")

    # Paso 4: Eliminar schedules antiguos
    print("\n🗑️  Eliminando schedules antiguos...")
    for doc in current_schedules:
        db.collection('class_schedules').document(doc.id).delete()
        print(f"   ❌ Eliminado: {doc.id}")

    # Paso 5: Crear nuevos schedules con IDs descriptivos
    print("\n✨ Creando nuevos schedules...")
    display_order = 0
    for schedule in schedules:
        schedule_id = schedule['id']
        schedule_data = {
            'time': schedule['time'],
            'type': schedule['type'],
            'instructor': schedule['instructor'],
            'capacity': schedule['capacity'],
            'daysOfWeek': schedule['days'],  # Cambiar 'days' a 'daysOfWeek'
            'durationMinutes': schedule['durationMinutes'],
            'active': True,
            'displayOrder': display_order,
            'createdAt': firestore.SERVER_TIMESTAMP,
        }

        db.collection('class_schedules').document(schedule_id).set(schedule_data)
        duration_hours = schedule['durationMinutes'] / 60
        print(f"   ✅ Creado: {schedule_id} ({schedule['time']} - {duration_hours}h)")
        display_order += 1

    print("\n✅ ¡Schedules recreados exitosamente!")
    print("\nResumen:")
    print(f"   - Schedules eliminados: {len(current_schedules)}")
    print(f"   - Schedules creados: {len(schedules)}")
    print(f"   - Bookings actualizadas: {bookings_updated}")

if __name__ == '__main__':
    main()
