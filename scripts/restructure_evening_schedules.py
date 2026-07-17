"""
Reestructura los horarios de tarde (jul 2026), one-off:

- MJ18:    18:00 Mar+Jue  -> 18:30 solo Martes (Francisco)
- J1830:   NUEVO           - 18:30 Jueves (Felipe Roman)
- LXV1830: 18:30 L+X+V    -> 18:30 Lun+Mié (Francisco)
- V1830:   NUEVO           - 18:30 Viernes (Felipe Roman)
- MJ1930:  19:30 Mar+Jue  -> 20:00 Mar+Jue (Francisco)

Migra las reservas futuras (>= hoy) afectadas al horario/hora nuevos y
mueve los contadores de capacity_tracking de las fechas migradas.

Uso:
    python3 scripts/restructure_evening_schedules.py            # dry-run
    python3 scripts/restructure_evening_schedules.py --apply    # aplica
"""

import sys
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT = 'ayuthaya-camp-firebase-adminsdk-fbsvc-0576711a21.json'
FELIPE = 'Felipe Roman'

apply_changes = '--apply' in sys.argv

cred = credentials.Certificate(SERVICE_ACCOUNT)
firebase_admin.initialize_app(cred)
db = firestore.client()

today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

schedules = {d.id: d.to_dict() for d in db.collection('class_schedules').get()}
for sid in ('MJ18', 'LXV1830', 'MJ1930'):
    if sid not in schedules:
        print(f'❌ No existe el horario {sid}; aborto.')
        sys.exit(1)
if 'J1830' in schedules or 'V1830' in schedules:
    print('❌ J1830/V1830 ya existen; revisar antes de correr de nuevo.')
    sys.exit(1)

def base_doc(source_id, days):
    src = schedules[source_id]
    return {
        'time': '18:30',
        'instructor': FELIPE,
        'type': src.get('type', 'Muay Thai'),
        'capacity': src.get('capacity', 30),
        'daysOfWeek': days,
        'active': True,
        'displayOrder': src.get('displayOrder', 0),
        'createdAt': firestore.SERVER_TIMESTAMP,
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }

schedule_updates = {
    'MJ18': {'time': '18:30', 'daysOfWeek': [2], 'updatedAt': firestore.SERVER_TIMESTAMP},
    'LXV1830': {'daysOfWeek': [1, 3], 'updatedAt': firestore.SERVER_TIMESTAMP},
    'MJ1930': {'time': '20:00', 'updatedAt': firestore.SERVER_TIMESTAMP},
}
new_schedules = {
    'J1830': base_doc('MJ18', [4]),
    'V1830': base_doc('LXV1830', [5]),
}

# --- Reservas futuras a migrar ---------------------------------------------
# (scheduleId origen, weekday, destino, campos extra a actualizar)
RULES = [
    ('LXV1830', 5, 'V1830', {'instructor': FELIPE}),                      # viernes 18:30
    ('MJ18', 4, 'J1830', {'instructor': FELIPE, 'scheduleTime': '18:30'}),# jueves 18:00->18:30
    ('MJ18', 2, 'MJ18', {'scheduleTime': '18:30'}),                       # martes 18:00->18:30
    ('MJ1930', 2, 'MJ1930', {'scheduleTime': '20:00'}),                   # martes 19:30->20:00
    ('MJ1930', 4, 'MJ1930', {'scheduleTime': '20:00'}),                   # jueves 19:30->20:00
]

booking_moves = []  # (booking_id, userName, fecha, source, target, extra)
for source, weekday, target, extra in RULES:
    docs = db.collection('bookings').where('scheduleId', '==', source).get()
    for doc in docs:
        b = doc.to_dict()
        cd = b.get('classDate')
        if cd is None:
            continue
        cdate = datetime(cd.year, cd.month, cd.day)
        if cdate < today or cdate.isoweekday() != weekday:
            continue
        if b.get('status') in ('cancelled',):
            continue
        booking_moves.append((doc.id, b.get('userName', '?'), cdate, source, target, extra))

mode = 'APLICANDO' if apply_changes else 'DRY-RUN (sin cambios)'
print(f'\n=== {mode} ===\n')
print('Horarios a modificar:')
for sid, upd in schedule_updates.items():
    visible = {k: v for k, v in upd.items() if k != 'updatedAt'}
    print(f'  ~ {sid}: {visible}')
print('Horarios nuevos:')
for sid, doc in new_schedules.items():
    print(f"  + {sid}: 18:30 days={doc['daysOfWeek']} instructor={doc['instructor']}")
print(f'\nReservas futuras a migrar: {len(booking_moves)}')
for _id, nombre, fecha, source, target, extra in booking_moves:
    cambio = f'{source} -> {target}' if source != target else 'misma clase'
    print(f'  - {fecha:%d/%m/%Y}  {nombre}  ({cambio}, {extra})')

if not apply_changes:
    print('\nDry-run terminado. Ejecuta con --apply para aplicar.')
    sys.exit(0)

batch = db.batch()

for sid, upd in schedule_updates.items():
    batch.update(db.collection('class_schedules').document(sid), upd)
for sid, doc in new_schedules.items():
    batch.set(db.collection('class_schedules').document(sid), doc)

# Migrar bookings y armar contadores por (schedule destino, fecha)
counters = {}
for _id, _, fecha, source, target, extra in booking_moves:
    updates = {'updatedAt': firestore.SERVER_TIMESTAMP, **extra}
    if source != target:
        updates['scheduleId'] = target
        key = (source, target, fecha)
        counters[key] = counters.get(key, 0) + 1
    batch.update(db.collection('bookings').document(_id), updates)

# Mover capacity_tracking de las fechas cuyos bookings cambiaron de schedule
for (source, target, fecha), moved in counters.items():
    date_key = fecha.strftime('%Y-%m-%d')
    old_ref = (db.collection('class_schedules').document(source)
               .collection('capacity_tracking').document(date_key))
    new_ref = (db.collection('class_schedules').document(target)
               .collection('capacity_tracking').document(date_key))
    old_doc = old_ref.get()
    old_count = (old_doc.to_dict() or {}).get('currentBookings', 0) if old_doc.exists else 0

    batch.set(new_ref, {
        'currentBookings': moved,
        'maxCapacity': new_schedules.get(target, schedules.get(target, {})).get('capacity', 30),
        'scheduleId': target,
        'classDate': fecha,
        'lastUpdated': firestore.SERVER_TIMESTAMP,
    }, merge=True)
    remaining = max(0, old_count - moved)
    if old_doc.exists:
        batch.update(old_ref, {
            'currentBookings': remaining,
            'lastUpdated': firestore.SERVER_TIMESTAMP,
        })
    print(f'  contador {date_key}: {source}({old_count}->{remaining})  {target}(+{moved})')

batch.commit()
print(f'\nListo: horarios reestructurados y {len(booking_moves)} reservas migradas.')
