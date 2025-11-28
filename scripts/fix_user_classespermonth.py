#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para actualizar usuarios con el campo correcto classesPerMonth
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

    # Obtener todos los usuarios
    print("Buscando usuarios...")
    users = db.collection('users').get()

    for user_doc in users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        email = user_data.get('email', 'sin email')

        # Si tiene classLimit pero no classesPerMonth
        if 'classLimit' in user_data and 'classesPerMonth' not in user_data:
            class_limit = user_data['classLimit']

            # Actualizar con classesPerMonth y eliminar classLimit
            update_data = {
                'classesPerMonth': 4,  # Plan Iniciado por defecto
                'classLimit': firestore.DELETE_FIELD  # Eliminar campo viejo
            }

            db.collection('users').document(user_id).update(update_data)

            print(f"✅ Usuario actualizado: {email}")
            print(f"   classLimit {class_limit} → classesPerMonth 4")

        # Si tiene AMBOS campos, eliminar classLimit
        elif 'classLimit' in user_data and 'classesPerMonth' in user_data:
            class_limit = user_data['classLimit']
            classes_per_month = user_data['classesPerMonth']

            # Solo eliminar classLimit
            update_data = {
                'classLimit': firestore.DELETE_FIELD  # Eliminar campo viejo
            }

            db.collection('users').document(user_id).update(update_data)

            print(f"✅ Usuario limpiado: {email}")
            print(f"   Eliminado classLimit {class_limit} (ya tiene classesPerMonth {classes_per_month})")

        else:
            print(f"⏭️  Usuario OK: {email}")

if __name__ == '__main__':
    main()
