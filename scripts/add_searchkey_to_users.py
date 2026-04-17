#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para agregar el campo 'searchKey' a todos los usuarios existentes
searchKey = email en minúsculas para facilitar búsquedas

Uso:
  python scripts/add_searchkey_to_users.py [ruta_al_service_account.json]
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials, firestore

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def main():
    print("=" * 60)
    print("AGREGAR SEARCHKEY A USUARIOS EXISTENTES")
    print("=" * 60)
    print("\nEste script agregará el campo 'searchKey' a todos los usuarios")
    print("searchKey = email en minúsculas (para búsquedas fáciles)\n")

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
        print('  python scripts/add_searchkey_to_users.py [ruta_al_service_account.json]')
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

    # Obtener todos los usuarios
    print("[1/2] Obteniendo todos los usuarios...")
    users_ref = db.collection('users')
    all_users = users_ref.get()

    print(f"✅ Total de usuarios encontrados: {len(all_users)}\n")

    if len(all_users) == 0:
        print("ℹ️  No hay usuarios para actualizar")
        return

    # Actualizar cada usuario
    print("[2/2] Actualizando usuarios...\n")
    updated_count = 0
    already_have_count = 0
    error_count = 0

    for user_doc in all_users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        user_email = user_data.get('email', '')
        user_role = user_data.get('role', 'student')

        # Verificar si ya tiene searchKey
        if 'searchKey' in user_data:
            print(f"  ⏭️  {user_email} - Ya tiene searchKey: '{user_data['searchKey']}'")
            already_have_count += 1
            continue

        if not user_email:
            print(f"  ⚠️  Usuario {user_id} - No tiene email, saltando")
            error_count += 1
            continue

        try:
            # Agregar searchKey
            search_key = user_email.lower()
            db.collection('users').document(user_id).update({
                'searchKey': search_key
            })

            role_emoji = '👑' if user_role == 'admin' else '👤'
            print(f"  ✅ {role_emoji} {user_email} -> searchKey: '{search_key}'")
            updated_count += 1

        except Exception as e:
            print(f"  ❌ Error actualizando {user_email}: {e}")
            error_count += 1

    # Resumen final
    print("\n" + "=" * 60)
    print("✅ ACTUALIZACIÓN COMPLETADA")
    print("=" * 60)
    print(f"Usuarios actualizados: {updated_count}")
    print(f"Usuarios que ya tenían searchKey: {already_have_count}")
    print(f"Errores: {error_count}")
    print(f"Total procesado: {len(all_users)}")
    print()

    # Instrucciones para usar searchKey en Firebase Console
    print("📖 CÓMO BUSCAR USUARIOS EN FIREBASE CONSOLE:")
    print("-" * 60)
    print("1. Ir a Firestore Database > users")
    print("2. Hacer clic en 'Add filter'")
    print("3. Seleccionar campo: 'searchKey'")
    print("4. Operador: '=='")
    print("5. Valor: el email en minúsculas (ej: 'user@example.com')")
    print("6. Click 'Apply'")
    print()

if __name__ == '__main__':
    main()
