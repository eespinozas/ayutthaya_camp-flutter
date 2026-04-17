#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para eliminar todos los documentos de usuarios de Firestore
EXCEPTO el usuario con role='admin'
Elimina usuarios, reservas (bookings) y pagos (payments)
MANTIENE todas las colecciones intactas, solo elimina los documentos

Uso:
  python scripts/delete_all_users_except_admin.py [--confirm] [ruta_al_service_account.json]
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
    print("ELIMINACIÓN DE USUARIOS (EXCEPTO ADMIN)")
    print("=" * 60)
    print("\n⚠️  ADVERTENCIA: Este script eliminará PERMANENTEMENTE:")
    print("  - Todos los usuarios EXCEPTO el que tiene role='admin'")
    print("  - Todas las reservas (bookings) de usuarios eliminados")
    print("  - Todos los pagos (payments) de usuarios eliminados")
    print("  - Los usuarios de Firebase Authentication")
    print()
    print("  ✅ Se preservará el usuario con role='admin'")
    print("  ✅ Las colecciones se mantendrán intactas")
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
        print('  python scripts/delete_all_users_except_admin.py [ruta_al_service_account.json]')
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
    print("[1/5] Obteniendo todos los usuarios de Firestore...")
    users_ref = db.collection('users')
    all_users = users_ref.get()

    print(f"✅ Total de usuarios encontrados: {len(all_users)}\n")

    # Clasificar usuarios
    users_to_delete = []
    users_to_preserve = []

    for user_doc in all_users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        user_name = user_data.get('name', '')
        user_email = user_data.get('email', 'Sin email')
        user_role = user_data.get('role', 'student')

        user_info = {
            'id': user_id,
            'email': user_email,
            'name': user_name,
            'role': user_role
        }

        # Preservar el usuario con role='admin'
        if user_role == 'admin':
            users_to_preserve.append(user_info)
        else:
            users_to_delete.append(user_info)

    print(f"[2/5] Clasificación de usuarios:")
    print(f"  ✅ Usuarios a PRESERVAR: {len(users_to_preserve)}")
    for user in users_to_preserve:
        print(f"     - {user['email']} (name: '{user['name']}', role: {user['role']}, ID: {user['id']})")

    print(f"\n  🗑️  Usuarios a ELIMINAR: {len(users_to_delete)}")
    if len(users_to_delete) <= 20:  # Solo mostrar si no son demasiados
        for user in users_to_delete:
            print(f"     - {user['email']} (name: '{user['name']}', role: {user['role']}, ID: {user['id']})")
    else:
        # Mostrar solo los primeros 20
        for user in users_to_delete[:20]:
            print(f"     - {user['email']} (name: '{user['name']}', role: {user['role']}, ID: {user['id']})")
        print(f"     ... y {len(users_to_delete) - 20} usuarios más")

    if len(users_to_delete) == 0:
        print("\n✅ No hay usuarios para eliminar")
        return

    if len(users_to_preserve) == 0:
        print("\n⚠️  ADVERTENCIA: No se encontró ningún usuario con role='admin'")
        print("Se eliminarán TODOS los usuarios")

    # Confirmación
    print("\n" + "=" * 60)
    if auto_confirm:
        print(f"✅ Auto-confirmado (--confirm): Se eliminarán {len(users_to_delete)} usuarios")
    else:
        print("⚠️  ESTA ACCIÓN ES IRREVERSIBLE ⚠️")
        response = input(f"\n¿Confirmas que deseas eliminar {len(users_to_delete)} usuarios? (escribe 'ELIMINAR' para confirmar): ")
        if response != 'ELIMINAR':
            print("\n❌ Operación cancelada")
            sys.exit(0)

    # Crear lista de IDs de usuarios a eliminar
    user_ids_to_delete = [user['id'] for user in users_to_delete]

    # Eliminar bookings de usuarios a eliminar
    print("\n[3/5] Eliminando bookings de usuarios a eliminar...")
    total_bookings_deleted = 0

    for user in users_to_delete:
        user_id = user['id']
        user_email = user['email']

        # Buscar todas las bookings del usuario
        bookings = db.collection('bookings').where('userId', '==', user_id).get()

        if len(bookings) > 0:
            print(f"  🗑️  {user_email}: {len(bookings)} booking(s)")

            # Eliminar cada booking
            for booking_doc in bookings:
                try:
                    booking_doc.reference.delete()
                    total_bookings_deleted += 1
                except Exception as e:
                    print(f"     ⚠️  Error eliminando booking: {e}")

    print(f"\n✅ Total de bookings eliminadas: {total_bookings_deleted}\n")

    # Eliminar pagos de usuarios a eliminar
    print("[4/5] Eliminando pagos de usuarios a eliminar...")
    total_payments_deleted = 0

    for user in users_to_delete:
        user_id = user['id']
        user_email = user['email']

        # Buscar todos los pagos del usuario
        payments = db.collection('payments').where('userId', '==', user_id).get()

        if len(payments) > 0:
            print(f"  🗑️  {user_email}: {len(payments)} pago(s)")

            # Eliminar cada pago
            for payment_doc in payments:
                try:
                    payment_doc.reference.delete()
                    total_payments_deleted += 1
                except Exception as e:
                    print(f"     ⚠️  Error eliminando payment: {e}")

    print(f"\n✅ Total de pagos eliminados: {total_payments_deleted}\n")

    # Eliminar dashboards de usuarios a eliminar
    print("   Eliminando dashboards de usuarios a eliminar...")
    total_dashboards_deleted = 0

    for user in users_to_delete:
        user_id = user['id']

        # Intentar eliminar dashboard del usuario
        try:
            dashboard_ref = db.collection('dashboards').document(user_id)
            dashboard_doc = dashboard_ref.get()
            if dashboard_doc.exists:
                dashboard_ref.delete()
                total_dashboards_deleted += 1
        except Exception as e:
            pass  # Silently continue if no dashboard exists

    if total_dashboards_deleted > 0:
        print(f"   ✅ Total de dashboards eliminados: {total_dashboards_deleted}\n")

    # Eliminar usuarios de Firestore y Authentication
    print("[5/5] Eliminando usuarios de Firestore y Authentication...")
    users_deleted_firestore = 0
    users_deleted_auth = 0

    for user in users_to_delete:
        user_id = user['id']
        user_email = user['email']
        user_name = user['name']

        try:
            # Eliminar de Firestore
            db.collection('users').document(user_id).delete()
            users_deleted_firestore += 1

            # Eliminar de Firebase Authentication
            try:
                auth.delete_user(user_id)
                users_deleted_auth += 1
                print(f"  ✅ {user_email} (name: '{user_name}') - Firestore + Auth")
            except auth.UserNotFoundError:
                print(f"  ⚠️  {user_email} (name: '{user_name}') - Firestore OK, no existe en Auth")
            except Exception as e:
                print(f"  ⚠️  {user_email} (name: '{user_name}') - Firestore OK, error Auth: {e}")

        except Exception as e:
            print(f"  ❌ Error eliminando {user_email}: {e}")

    # Resumen final
    print("\n" + "=" * 60)
    print("✅ ELIMINACIÓN COMPLETADA")
    print("=" * 60)
    print(f"Usuarios eliminados de Firestore: {users_deleted_firestore}/{len(users_to_delete)}")
    print(f"Usuarios eliminados de Auth: {users_deleted_auth}/{len(users_to_delete)}")
    print(f"Bookings eliminadas: {total_bookings_deleted}")
    print(f"Pagos eliminados: {total_payments_deleted}")
    if total_dashboards_deleted > 0:
        print(f"Dashboards eliminados: {total_dashboards_deleted}")
    print(f"\n✅ Usuarios PRESERVADOS: {len(users_to_preserve)}")
    for user in users_to_preserve:
        print(f"   - {user['email']} (name: '{user['name']}', role: {user['role']})")
    print()
    print("📋 Colecciones mantenidas:")
    print("  - users (con usuarios preservados)")
    print("  - bookings (sin documentos de usuarios eliminados)")
    print("  - payments (sin documentos de usuarios eliminados)")
    print("  - plans")
    print("  - class_schedules")
    print("  - schools")
    print("  - config")
    print()

if __name__ == '__main__':
    main()
