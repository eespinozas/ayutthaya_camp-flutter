#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para cancelar bookings de un usuario
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
    if len(sys.argv) < 3:
        print("Uso: python scripts/cancel_bookings.py [email] [cantidad]")
        sys.exit(1)

    user_email = sys.argv[1]
    cantidad = int(sys.argv[2])

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

    # Buscar el usuario
    print(f"Buscando usuario '{user_email}'...")
    users_query = db.collection('users').where('email', '==', user_email).limit(1).get()

    if not users_query:
        print(f"❌ Usuario '{user_email}' no encontrado")
        sys.exit(1)

    user_doc = users_query[0]
    user_id = user_doc.id

    print(f"✅ Usuario encontrado: {user_id}\n")

    # Buscar bookings confirmadas
    print(f"Buscando bookings confirmadas...")
    bookings = db.collection('bookings')\
        .where('userId', '==', user_id)\
        .where('status', '==', 'confirmed')\
        .limit(cantidad)\
        .get()

    if len(bookings) == 0:
        print("❌ No hay bookings confirmadas para cancelar")
        sys.exit(1)

    print(f"✅ Encontradas {len(bookings)} bookings\n")

    # Cancelar las bookings
    cancelled_count = 0
    for booking_doc in bookings:
        booking_data = booking_doc.to_dict()
        booking_id = booking_doc.id

        # Actualizar a cancelled
        db.collection('bookings').document(booking_id).update({
            'status': 'cancelled',
            'cancelledAt': firestore.SERVER_TIMESTAMP,
            'cancellationReason': 'Cancelado por script de prueba',
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })

        class_type = booking_data.get('scheduleType', 'Clase')
        class_date = booking_data.get('classDate')

        print(f"✅ Cancelada: {class_type} - {class_date}")
        cancelled_count += 1

    print(f"\n✅ Total canceladas: {cancelled_count} bookings")

if __name__ == '__main__':
    main()
