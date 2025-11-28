#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para actualizar el plan de un usuario

Uso:
  python scripts/update_user_plan.py [email] [plan_name]

Ejemplos:
  python scripts/update_user_plan.py usuario@example.com "Plan Iniciado"
  python scripts/update_user_plan.py usuario@example.com "Plan Peleador"
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
        print("Uso: python scripts/update_user_plan.py [email] [plan_name]")
        print("\nEjemplos:")
        print('  python scripts/update_user_plan.py usuario@example.com "Plan Iniciado"')
        print('  python scripts/update_user_plan.py usuario@example.com "Plan Peleador"')
        sys.exit(1)

    user_email = sys.argv[1]
    plan_name = sys.argv[2]

    print(f"Actualizando usuario: {user_email}")
    print(f"Plan: {plan_name}\n")

    # Determinar ruta del service account
    service_account_path = None
    if 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
        service_account_path = os.environ['FIREBASE_SERVICE_ACCOUNT']
    else:
        service_account_path = 'scripts/firebase-service-account.json'

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

    # Buscar el plan
    print(f"Buscando plan '{plan_name}'...")
    plans_query = db.collection('plans').where('name', '==', plan_name).where('active', '==', True).limit(1).get()

    if not plans_query:
        print(f"❌ Plan '{plan_name}' no encontrado")
        print("\nPlanes disponibles:")
        all_plans = db.collection('plans').where('active', '==', True).get()
        for plan in all_plans:
            print(f"  - {plan.get('name')}")
        sys.exit(1)

    plan_doc = plans_query[0]
    plan_data = plan_doc.to_dict()
    plan_id = plan_doc.id
    classes_per_month = plan_data.get('classesPerMonth')

    print(f"✅ Plan encontrado:")
    print(f"   ID: {plan_id}")
    print(f"   Clases/mes: {classes_per_month if classes_per_month else 'ilimitado'}")

    # Buscar el usuario por email
    print(f"\nBuscando usuario '{user_email}'...")
    users_query = db.collection('users').where('email', '==', user_email).limit(1).get()

    if not users_query:
        print(f"❌ Usuario '{user_email}' no encontrado")
        sys.exit(1)

    user_doc = users_query[0]
    user_id = user_doc.id

    print(f"✅ Usuario encontrado: {user_id}")

    # Actualizar el usuario
    print(f"\nActualizando usuario...")

    update_data = {
        'planId': plan_id,
        'planName': plan_name,
        'membershipStatus': 'active',
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

    if classes_per_month is not None:
        update_data['classesPerMonth'] = classes_per_month
    else:
        # Plan ilimitado - eliminar el campo
        update_data['classesPerMonth'] = firestore.DELETE_FIELD

    try:
        db.collection('users').document(user_id).update(update_data)
        print(f"✅ Usuario actualizado exitosamente")
        print(f"\nResumen:")
        print(f"  Usuario: {user_email}")
        print(f"  Plan: {plan_name}")
        print(f"  Clases/mes: {classes_per_month if classes_per_month else 'ilimitado'}")
        print(f"  Estado: active")
    except Exception as e:
        print(f"❌ Error al actualizar usuario: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
