"""
Cierra como noShow las reservas 'confirmed' de clases que ya terminaron.

Una reserva queda "sin resolver" cuando el alumno nunca confirmó ni pasó
por QR y tampoco abrió la app (los barridos client-side no corrieron).
Este script replica esa regla del lado servidor, una sola vez.

Criterio: status == 'confirmed' y el término de la clase ya pasó
(inicio + 90 min de clase + 15 min de gracia). No toca reservas de hoy
que aún no parten, ni pendingApproval/attended/cancelled.

Uso:
    python3 scripts/close_unresolved_bookings.py            # dry-run
    python3 scripts/close_unresolved_bookings.py --apply    # aplica
"""

import sys
from datetime import datetime, timedelta

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT = 'ayuthaya-camp-firebase-adminsdk-fbsvc-0576711a21.json'
# Duración máxima de clase (90 min) + gracia de confirmación (15 min)
VENTANA = timedelta(minutes=105)

apply_changes = '--apply' in sys.argv

cred = credentials.Certificate(SERVICE_ACCOUNT)
firebase_admin.initialize_app(cred)
db = firestore.client()

now = datetime.now()
targets = []

for doc in db.collection('bookings').where('status', '==', 'confirmed').get():
    b = doc.to_dict()
    class_date = b.get('classDate')
    schedule_time = b.get('scheduleTime', '00:00')
    if class_date is None:
        continue
    try:
        hour, minute = (int(x) for x in schedule_time.split(':'))
    except ValueError:
        hour, minute = 0, 0
    start = datetime(class_date.year, class_date.month, class_date.day, hour, minute)
    if start + VENTANA < now:
        targets.append((doc.id, b.get('userName', '?'), start))

mode = 'APLICANDO' if apply_changes else 'DRY-RUN (sin cambios)'
print(f'\n=== {mode} ===  (ahora: {now:%d/%m/%Y %H:%M})')
print(f"Reservas 'confirmed' con clase ya terminada -> noShow: {len(targets)}\n")

for _id, nombre, start in sorted(targets, key=lambda t: t[2]):
    print(f'  - {start:%d/%m/%Y %H:%M}  {nombre}  [{_id}]')

if not targets:
    print('Nada que cerrar.')
    sys.exit(0)

if not apply_changes:
    print('\nDry-run terminado. Ejecuta con --apply para aplicar.')
    sys.exit(0)

batch = db.batch()
for _id, _, _ in targets:
    batch.update(db.collection('bookings').document(_id), {
        'status': 'noShow',
        'updatedAt': firestore.SERVER_TIMESTAMP,
    })
batch.commit()
print(f'\nListo: {len(targets)} reservas cerradas como noShow.')
