"""
Script para limpiar pago corrupto
"""

import firebase_admin
from firebase_admin import credentials, firestore

# Inicializar Firebase Admin
cred = credentials.Certificate('scripts/firebase-service-account.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

print("\n" + "=" * 80)
print("LIMPIANDO PAGO CORRUPTO")
print("=" * 80 + "\n")

# ID del pago corrupto
corrupt_payment_id = 'SO6mLFUruJ6aQxYEqCbc'

print(f"Eliminando pago corrupto: {corrupt_payment_id}")

try:
    db.collection('payments').document(corrupt_payment_id).delete()
    print(f"[OK] Pago corrupto eliminado exitosamente")
except Exception as e:
    print(f"[ERROR] No se pudo eliminar el pago: {e}")

print("\n" + "=" * 80)
print("FIN")
print("=" * 80)
