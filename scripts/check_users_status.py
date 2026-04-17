"""
Script de diagnóstico para verificar usuarios y sus estados
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Inicializar Firebase Admin
cred = credentials.Certificate('scripts/firebase-service-account.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

print("\n" + "=" * 80)
print("DIAGNÓSTICO DE USUARIOS")
print("=" * 80 + "\n")

# Obtener todos los usuarios
users_ref = db.collection('users')
users = users_ref.get()

print(f"Total de usuarios en Firestore: {len(users)}\n")

# Separar por rol
admins = []
students = []

for user_doc in users:
    user_data = user_doc.to_dict()
    user_id = user_doc.id
    role = user_data.get('role', 'student')

    if role == 'admin':
        admins.append((user_id, user_data))
    else:
        students.append((user_id, user_data))

print(f"[ADMIN] Administradores: {len(admins)}")
for user_id, data in admins:
    print(f"   - {data.get('email')} (ID: {user_id})")

print(f"\n[ESTUDIANTES] Total: {len(students)}\n")

# Separar estudiantes por estado
pending_students = []
active_students = []
none_students = []
other_students = []

for user_id, data in students:
    status = data.get('membershipStatus', 'none')

    if status == 'pending':
        pending_students.append((user_id, data))
    elif status == 'active':
        active_students.append((user_id, data))
    elif status == 'none':
        none_students.append((user_id, data))
    else:
        other_students.append((user_id, data, status))

print(f"[PENDIENTES] {len(pending_students)} estudiantes:")
for user_id, data in pending_students:
    email = data.get('email', 'Sin email')
    name = data.get('name', 'Sin nombre')
    created_at = data.get('createdAt')
    print(f"   - {name} ({email})")
    print(f"     ID: {user_id}")
    print(f"     Status: {data.get('membershipStatus')}")
    print(f"     Role: {data.get('role')}")
    print(f"     Creado: {created_at}")
    print()

print(f"\n[SIN STATUS] {len(none_students)} estudiantes sin status (none):")
for user_id, data in none_students:
    email = data.get('email', 'Sin email')
    name = data.get('name', 'Sin nombre')
    created_at = data.get('createdAt')
    print(f"   - {name} ({email})")
    print(f"     ID: {user_id}")
    print(f"     Status: {data.get('membershipStatus')}")
    print(f"     Role: {data.get('role')}")
    print(f"     Creado: {created_at}")
    print()

print(f"\n[ACTIVOS] {len(active_students)} estudiantes activos:")
for user_id, data in active_students:
    email = data.get('email', 'Sin email')
    name = data.get('name', 'Sin nombre')
    expiration = data.get('expirationDate')
    print(f"   - {name} ({email})")
    print(f"     ID: {user_id}")
    print(f"     Expira: {expiration}")
    print()

if other_students:
    print(f"\n[OTROS STATUS] {len(other_students)} estudiantes con otro status:")
    for user_id, data, status in other_students:
        email = data.get('email', 'Sin email')
        print(f"   - {email} - Status: {status} (ID: {user_id})")

# Verificar TODOS los pagos
print("\n" + "=" * 80)
print("VERIFICANDO TODOS LOS PAGOS EN FIRESTORE")
print("=" * 80 + "\n")

all_payments = db.collection('payments').get()
print(f"Total de pagos en sistema: {len(all_payments)}\n")

for payment_doc in all_payments:
    payment_data = payment_doc.to_dict()
    user_id = payment_data.get('userId')
    print(f"Pago ID: {payment_doc.id}")
    print(f"  - Usuario ID: {user_id}")
    print(f"  - Email: {payment_data.get('userEmail')}")
    print(f"  - Tipo: {payment_data.get('type')}")
    print(f"  - Estado: {payment_data.get('status')}")
    print(f"  - Monto: ${payment_data.get('amount')}")
    print(f"  - Plan: {payment_data.get('plan')}")
    print(f"  - Creado: {payment_data.get('createdAt')}")
    print()

# Verificar pagos de usuarios sin status
print("\n" + "=" * 80)
print("PAGOS DE USUARIOS SIN STATUS (none)")
print("=" * 80 + "\n")

for user_id, data in none_students:
    email = data.get('email')
    print(f"Usuario: {email} (ID: {user_id})")

    # Buscar pagos de este usuario
    payments = db.collection('payments').where('userId', '==', user_id).get()

    if len(payments) == 0:
        print(f"   [X] No tiene pagos registrados")
    else:
        print(f"   [PAGOS] Tiene {len(payments)} pago(s):")
        for payment_doc in payments:
            payment_data = payment_doc.to_dict()
            print(f"      - Tipo: {payment_data.get('type')}")
            print(f"      - Estado: {payment_data.get('status')}")
            print(f"      - Monto: ${payment_data.get('amount')}")
            print(f"      - Plan: {payment_data.get('plan')}")
            print(f"      - Creado: {payment_data.get('createdAt')}")
    print()

print("\n" + "=" * 80)
print("FIN DEL DIAGNÓSTICO")
print("=" * 80)
