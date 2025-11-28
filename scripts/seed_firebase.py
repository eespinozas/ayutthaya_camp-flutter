#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para poblar Firebase Firestore con planes y horarios de clases

Uso:
  python scripts/seed_firebase.py [ruta_al_service_account.json]

  O con variable de entorno:
  export FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json
  python scripts/seed_firebase.py
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def main():
    print("Iniciando seed de Firebase...\n")

    # Determinar ruta del service account
    service_account_path = None

    # 1. Desde argumento de línea de comandos
    if len(sys.argv) > 1:
        service_account_path = sys.argv[1]
        print(f'Usando service account desde argumento: {service_account_path}')
    # 2. Desde variable de entorno
    elif 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
        service_account_path = os.environ['FIREBASE_SERVICE_ACCOUNT']
        print(f'Usando service account desde variable de entorno: {service_account_path}')
    # 3. Valor por defecto
    else:
        service_account_path = 'scripts/firebase-service-account.json'
        print(f'Usando service account por defecto: {service_account_path}')

    # Verificar que el archivo existe
    if not os.path.exists(service_account_path):
        print(f'\nERROR: No se encontro el archivo: {service_account_path}')
        print('\nUso:')
        print('  python scripts/seed_firebase.py [ruta_al_service_account.json]')
        print('  O configura la variable de entorno FIREBASE_SERVICE_ACCOUNT')
        print('\nINSTRUCCIONES:')
        print('1. Ve a Firebase Console > Project Settings > Service Accounts')
        print('2. Click en "Generate new private key"')
        print('3. Guarda el archivo y especifica su ruta')
        sys.exit(1)

    # Inicializar Firebase Admin SDK
    try:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        print("OK Firebase inicializado correctamente\n")
    except Exception as e:
        print(f"ERROR al inicializar Firebase: {e}")
        sys.exit(1)

    db = firestore.client()

    # ==================== SEED PLANES ====================
    print("[PLANES] Agregando planes...\n")

    plans = [
        {
            'name': 'Plan Novato',
            'price': 10000,
            'durationDays': 30,
            'description': '1 clase mensual - Ideal para probar',
            'classesPerMonth': 1,
            'active': True,
            'displayOrder': 1,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'name': 'Plan Iniciado',
            'price': 35000,
            'durationDays': 30,
            'description': '4 clases mensuales - Para empezar tu entrenamiento',
            'classesPerMonth': 4,
            'active': True,
            'displayOrder': 2,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'name': 'Plan Guerrero',
            'price': 45000,
            'durationDays': 30,
            'description': '8 clases mensuales - Entrena de forma regular',
            'classesPerMonth': 8,
            'active': True,
            'displayOrder': 3,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'name': 'Plan Nak Muay',
            'price': 55000,
            'durationDays': 30,
            'description': '12 clases mensuales - Mejora tu técnica',
            'classesPerMonth': 12,
            'active': True,
            'displayOrder': 4,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'name': 'Plan Peleador',
            'price': 65000,
            'durationDays': 30,
            'description': 'Clases ilimitadas - Entrena todos los días',
            'classesPerMonth': None,  # None = ilimitado
            'active': True,
            'displayOrder': 5,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
    ]

    plans_count = 0
    for plan in plans:
        try:
            doc_ref = db.collection('plans').add(plan)
            plans_count += 1
            print(f"   OK Plan agregado: {plan['name']} - ${plan['price']}")
        except Exception as e:
            print(f"   ERROR al agregar {plan['name']}: {e}")

    print(f"\n   {plans_count}/{len(plans)} planes agregados\n")

    # ==================== SEED HORARIOS ====================
    print("[HORARIOS] Agregando horarios de clases...\n")

    schedules = [
        # LUNES, MIÉRCOLES, VIERNES (días 1, 3, 5)
        {
            'time': '07:00',
            'instructor': 'Francisco Poveda',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [1, 3, 5],
            'active': True,
            'displayOrder': 1,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '08:00',
            'instructor': 'Francisco Poveda',
            'type': 'Boxing',
            'capacity': 15,
            'daysOfWeek': [1, 3, 5],
            'active': True,
            'displayOrder': 2,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '09:30',
            'instructor': 'Carlos Mendoza',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [1, 3, 5],
            'active': True,
            'displayOrder': 3,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '18:00',
            'instructor': 'Francisco Poveda',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [1, 3, 5],
            'active': True,
            'displayOrder': 4,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '20:00',
            'instructor': 'Carlos Mendoza',
            'type': 'Boxing',
            'capacity': 15,
            'daysOfWeek': [1, 3, 5],
            'active': True,
            'displayOrder': 5,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },

        # MARTES Y JUEVES (días 2, 4)
        {
            'time': '07:00',
            'instructor': 'Francisco Poveda',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [2, 4],
            'active': True,
            'displayOrder': 6,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '08:00',
            'instructor': 'Francisco Poveda',
            'type': 'Boxing',
            'capacity': 15,
            'daysOfWeek': [2, 4],
            'active': True,
            'displayOrder': 7,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '09:30',
            'instructor': 'Carlos Mendoza',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [2, 4],
            'active': True,
            'displayOrder': 8,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '18:30',
            'instructor': 'Francisco Poveda',
            'type': 'Muay Thai',
            'capacity': 15,
            'daysOfWeek': [2, 4],
            'active': True,
            'displayOrder': 9,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '20:00',
            'instructor': 'Carlos Mendoza',
            'type': 'Boxing',
            'capacity': 15,
            'daysOfWeek': [2, 4],
            'active': True,
            'displayOrder': 10,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },

        # SÁBADO (día 6)
        {
            'time': '11:00',
            'instructor': 'Francisco Poveda',
            'type': 'Muay Thai',
            'capacity': 20,
            'daysOfWeek': [6],
            'active': True,
            'displayOrder': 11,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
        {
            'time': '13:00',
            'instructor': 'Carlos Mendoza',
            'type': 'Muay Thai',
            'capacity': 20,
            'daysOfWeek': [6],
            'active': True,
            'displayOrder': 12,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': None,
        },
    ]

    schedules_count = 0
    for schedule in schedules:
        try:
            doc_ref = db.collection('class_schedules').add(schedule)
            schedules_count += 1
            days_str = ', '.join(['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][d-1] for d in schedule['daysOfWeek'])
            print(f"   OK Horario agregado: {schedule['type']} a las {schedule['time']} ({days_str})")
        except Exception as e:
            print(f"   ERROR al agregar horario {schedule['type']}: {e}")

    print(f"\n   {schedules_count}/{len(schedules)} horarios agregados\n")

    # ==================== RESUMEN ====================
    print("=" * 50)
    print("OK SEED COMPLETADO EXITOSAMENTE")
    print("=" * 50)
    print(f"Planes agregados: {plans_count}")
    print(f"Horarios agregados: {schedules_count}")
    print("\nVerifica en Firebase Console:")
    print("https://console.firebase.google.com/project/YOUR_PROJECT/firestore")
    print()

if __name__ == '__main__':
    main()
