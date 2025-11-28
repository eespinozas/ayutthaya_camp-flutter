#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para actualizar planes existentes con el campo classesPerMonth

Uso:
  python scripts/update_plans_classes.py [ruta_al_service_account.json]
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
    print("Actualizando planes con campo classesPerMonth...\n")

    # Determinar ruta del service account
    service_account_path = None

    if len(sys.argv) > 1:
        service_account_path = sys.argv[1]
    elif 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
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

    # Mapeo de nombres de planes a cantidad de clases
    plan_classes = {
        'Plan Novato': 1,
        'Plan Iniciado': 4,
        'Plan Guerrero': 8,
        'Plan Nak Muay': 12,
        'Plan Peleador': None,  # Ilimitado
    }

    # Obtener todos los planes
    plans_ref = db.collection('plans')
    plans = plans_ref.get()

    updated_count = 0
    for plan_doc in plans:
        plan_data = plan_doc.data()
        plan_name = plan_data.get('name', '')

        if plan_name in plan_classes:
            classes_per_month = plan_classes[plan_name]

            # Actualizar el documento
            try:
                plans_ref.document(plan_doc.id).update({
                    'classesPerMonth': classes_per_month
                })

                if classes_per_month is None:
                    print(f"✅ {plan_name}: clases ilimitadas")
                else:
                    print(f"✅ {plan_name}: {classes_per_month} clases/mes")

                updated_count += 1
            except Exception as e:
                print(f"❌ Error al actualizar {plan_name}: {e}")
        else:
            print(f"⚠️  Plan desconocido: {plan_name}")

    print(f"\n✅ {updated_count} planes actualizados correctamente")

if __name__ == '__main__':
    main()
