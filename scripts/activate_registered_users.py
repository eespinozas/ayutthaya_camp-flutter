"""
Activa a los usuarios registrados sin membresía (fase de acceso libre).

Pasa membershipStatus 'none' (o ausente) -> 'active' para todos los
usuarios con role != 'admin'. No toca pending/active/expired/frozen.

Uso:
    python3 scripts/activate_registered_users.py            # dry-run (solo muestra)
    python3 scripts/activate_registered_users.py --apply    # aplica los cambios
"""

import sys

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT = 'ayuthaya-camp-firebase-adminsdk-fbsvc-0576711a21.json'

apply_changes = '--apply' in sys.argv

cred = credentials.Certificate(SERVICE_ACCOUNT)
firebase_admin.initialize_app(cred)
db = firestore.client()

users = db.collection('users').get()

targets = []
for doc in users:
    data = doc.to_dict()
    role = data.get('role', 'student')
    status = data.get('membershipStatus', 'none')
    if role != 'admin' and status == 'none':
        targets.append((doc.id, data.get('email', 'sin email'), data.get('name', '')))

mode = 'APLICANDO' if apply_changes else 'DRY-RUN (sin cambios)'
print(f'\n=== {mode} ===')
print(f'Usuarios totales: {len(users)}')
print(f"Usuarios a activar ('none' -> 'active'): {len(targets)}\n")

for uid, email, name in targets:
    print(f'  - {email}  ({name or "sin nombre"})  [{uid}]')

if not targets:
    print('Nada que hacer.')
    sys.exit(0)

if not apply_changes:
    print('\nDry-run terminado. Ejecuta con --apply para aplicar.')
    sys.exit(0)

batch = db.batch()
count = 0
for uid, _, _ in targets:
    ref = db.collection('users').document(uid)
    batch.update(ref, {
        'membershipStatus': 'active',
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })
    count += 1
    # Firestore permite máx 500 operaciones por batch
    if count % 450 == 0:
        batch.commit()
        batch = db.batch()

batch.commit()
print(f'\nListo: {count} usuarios activados.')
