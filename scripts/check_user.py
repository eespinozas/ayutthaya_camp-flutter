#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para ver el estado actual de un usuario
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

    # Obtener el usuario por email
    email = 'exequiel.espinozasanmartin@gmail.com'
    users_query = db.collection('users').where('email', '==', email).limit(1).get()

    if not users_query:
        print(f"❌ Usuario '{email}' no encontrado")
        sys.exit(1)

    user_doc = users_query[0]
    user_data = user_doc.to_dict()
    user_id = user_doc.id

    print(f"Usuario: {email}")
    print(f"UID: {user_id}\n")
    print("Campos relevantes:")
    print(f"  - planName: {user_data.get('planName', 'NO EXISTE')}")
    print(f"  - classLimit: {user_data.get('classLimit', 'NO EXISTE')}")
    print(f"  - classesPerMonth: {user_data.get('classesPerMonth', 'NO EXISTE')}")
    print(f"  - membershipStatus: {user_data.get('membershipStatus', 'NO EXISTE')}")
    print("\nTodos los campos:")
    for key, value in user_data.items():
        print(f"  - {key}: {value}")

if __name__ == '__main__':
    main()
