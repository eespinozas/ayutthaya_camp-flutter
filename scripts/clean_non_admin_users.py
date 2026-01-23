#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para limpiar todos los usuarios no-admin de Firestore
Elimina usuarios y todas sus reservas (bookings)

Uso:
  python scripts/clean_non_admin_users.py [--confirm] [ruta_al_service_account.json]
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def main():
    print("=" * 60)
    print("LIMPIEZA DE USUARIOS NO-ADMIN")
    print("=" * 60)
    print("\n⚠️  ADVERTENCIA: Este script eliminará PERMANENTEMENTE:")
    print("  - Todos los usuarios que NO tengan role='admin'")
    print("  - Todas las reservas (bookings) de esos usuarios")
    print("  - Los usuarios de Firebase Authentication")
    print()

    # Verificar si se pasó el flag --confirm
    auto_confirm = '--confirm' in sys.argv
    if auto_confirm:
        sys.argv.remove('--confirm')

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
        print('  python scripts/clean_non_admin_users.py [ruta_al_service_account.json]')
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
    print("[1/4] Obteniendo todos los usuarios...")
    users_ref = db.collection('users')
    all_users = users_ref.get()

    print(f"✅ Total de usuarios encontrados: {len(all_users)}\n")

    # Filtrar usuarios no-admin
    non_admin_users = []
    admin_users = []

    for user_doc in all_users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        user_role = user_data.get('role', 'student')
        user_email = user_data.get('email', 'Sin email')

        if user_role == 'admin':
            admin_users.append({
                'id': user_id,
                'email': user_email,
                'role': user_role
            })
        else:
            non_admin_users.append({
                'id': user_id,
                'email': user_email,
                'role': user_role
            })

    print(f"[2/4] Clasificación de usuarios:")
    print(f"  👑 Usuarios ADMIN (se mantendrán): {len(admin_users)}")
    for admin in admin_users:
        print(f"     - {admin['email']} (ID: {admin['id']})")

    print(f"\n  🗑️  Usuarios NO-ADMIN (se eliminarán): {len(non_admin_users)}")
    for user in non_admin_users:
        print(f"     - {user['email']} (ID: {user['id']})")

    if len(non_admin_users) == 0:
        print("\n✅ No hay usuarios no-admin para eliminar")
        return

    # Confirmación
    print("\n" + "=" * 60)
    if auto_confirm:
        print(f"✅ Auto-confirmado (--confirm): Se eliminarán {len(non_admin_users)} usuarios")
    else:
        response = input(f"¿Confirmas que deseas eliminar {len(non_admin_users)} usuarios? (escribe 'SI' para confirmar): ")
        if response != 'SI':
            print("\n❌ Operación cancelada")
            sys.exit(0)

    print("\n[3/4] Eliminando bookings de usuarios no-admin...")
    total_bookings_deleted = 0

    for user in non_admin_users:
        user_id = user['id']
        user_email = user['email']

        # Buscar todas las bookings del usuario
        bookings = db.collection('bookings').where('userId', '==', user_id).get()

        if len(bookings) > 0:
            print(f"  🗑️  {user_email}: {len(bookings)} booking(s)")

            # Eliminar cada booking
            for booking_doc in bookings:
                booking_doc.reference.delete()
                total_bookings_deleted += 1

    print(f"\n✅ Total de bookings eliminadas: {total_bookings_deleted}\n")

    # Eliminar usuarios de Firestore y Authentication
    print("[4/4] Eliminando usuarios...")
    users_deleted_firestore = 0
    users_deleted_auth = 0

    for user in non_admin_users:
        user_id = user['id']
        user_email = user['email']

        try:
            # Eliminar de Firestore
            db.collection('users').document(user_id).delete()
            users_deleted_firestore += 1

            # Eliminar de Firebase Authentication
            try:
                auth.delete_user(user_id)
                users_deleted_auth += 1
                print(f"  ✅ {user_email} (Firestore + Auth)")
            except auth.UserNotFoundError:
                print(f"  ⚠️  {user_email} (Firestore OK, no existe en Auth)")
            except Exception as e:
                print(f"  ⚠️  {user_email} (Firestore OK, error Auth: {e})")

        except Exception as e:
            print(f"  ❌ Error eliminando {user_email}: {e}")

    # Resumen final
    print("\n" + "=" * 60)
    print("✅ LIMPIEZA COMPLETADA")
    print("=" * 60)
    print(f"Usuarios eliminados de Firestore: {users_deleted_firestore}/{len(non_admin_users)}")
    print(f"Usuarios eliminados de Auth: {users_deleted_auth}/{len(non_admin_users)}")
    print(f"Bookings eliminadas: {total_bookings_deleted}")
    print(f"Usuarios ADMIN preservados: {len(admin_users)}")
    print()

if __name__ == '__main__':
    main()
