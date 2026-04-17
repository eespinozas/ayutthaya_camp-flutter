#!/usr/bin/env python3
"""
Script simple para probar notificaciones push
Uso: python scripts/test_push_simple.py
"""

import firebase_admin
from firebase_admin import credentials, firestore, messaging
import sys
from datetime import datetime

print("\n" + "="*60)
print("🔔 PRUEBA DE NOTIFICACIÓN PUSH")
print("="*60)

# Inicializar Firebase
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Conectado a Firebase\n")
except Exception as e:
    print(f"❌ Error: {e}")
    print("\n💡 Necesitas el archivo 'serviceAccountKey.json'")
    print("   Descárgalo desde:")
    print("   Firebase Console > Project Settings > Service accounts")
    print("   > Generate new private key\n")
    sys.exit(1)

# Obtener usuarios con FCM token
print("📱 Buscando usuarios con FCM token...\n")
users = db.collection('users').stream()

user_list = []
print("-" * 70)
print(f"{'#':<4} {'Email':<35} {'Role':<10} {'Nombre':<20}")
print("-" * 70)

for idx, user in enumerate(users, 1):
    user_data = user.to_dict()
    fcm_token = user_data.get('fcmToken', '')

    # Solo agregar usuarios que tengan FCM token
    if fcm_token:
        user_list.append({
            'id': user.id,
            'email': user_data.get('email', 'N/A'),
            'name': user_data.get('name', 'N/A'),
            'role': user_data.get('role', 'user'),
            'fcmToken': fcm_token
        })
        print(f"{len(user_list):<4} {user_data.get('email', 'N/A'):<35} {user_data.get('role', 'user'):<10} {user_data.get('name', 'N/A'):<20}")

print("-" * 70)
print(f"\n✨ Total: {len(user_list)} usuarios con FCM token\n")

if not user_list:
    print("❌ No hay usuarios con FCM token")
    print("💡 Primero ejecuta la app y inicia sesión para generar el token\n")
    sys.exit(1)

# Seleccionar usuario
try:
    user_num = int(input("Ingresa el número del usuario que quieres probar (o 0 para salir): "))
    if user_num == 0:
        print("\n👋 ¡Hasta luego!\n")
        sys.exit(0)

    if user_num < 1 or user_num > len(user_list):
        print("❌ Número inválido\n")
        sys.exit(1)

    user = user_list[user_num - 1]

except ValueError:
    print("❌ Ingresa un número válido\n")
    sys.exit(1)

print(f"\n📨 Enviando notificación push a: {user['email']}")
print(f"   Nombre: {user['name']}")
print(f"   Role: {user['role']}\n")

# Enviar notificación
try:
    message = messaging.Message(
        notification=messaging.Notification(
            title='🧪 Prueba de Notificación Push',
            body=f'Notificación enviada a las {datetime.now().strftime("%H:%M:%S")}. ¡Funciona correctamente! 🎉'
        ),
        data={
            'type': 'test',
            'timestamp': datetime.now().isoformat(),
            'message': 'Esta es una prueba de notificación push desde Python'
        },
        token=user['fcmToken'],
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                sound='default',
                priority='high',
                channel_id='default'
            )
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound='default',
                    badge=1,
                    content_available=True
                )
            )
        )
    )

    response = messaging.send(message)

    print("="*60)
    print("✅ ¡NOTIFICACIÓN ENVIADA EXITOSAMENTE!")
    print("="*60)
    print(f"📨 Message ID: {response}")
    print(f"📱 Destinatario: {user['email']}")
    print(f"🕐 Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n💡 Revisa tu dispositivo AHORA para ver la notificación")
    print("   - Si la app está abierta: verás la notificación en la app")
    print("   - Si la app está cerrada: verás la notificación en la bandeja")
    print("   - Si no funciona: verifica que el dispositivo tenga Play Services\n")

except Exception as e:
    print("="*60)
    print("❌ ERROR AL ENVIAR NOTIFICACIÓN")
    print("="*60)
    print(f"Error: {e}\n")

    if 'registration-token-not-registered' in str(e):
        print("⚠️  El token FCM es inválido o expiró")
        print("💡 Solución:")
        print("   1. Abre la app en el dispositivo")
        print("   2. Inicia sesión nuevamente")
        print("   3. El token se regenerará automáticamente")
        print("   4. Vuelve a ejecutar este script\n")
    elif 'service not found' in str(e):
        print("⚠️  Firebase Cloud Messaging no está configurado")
        print("💡 Verifica la configuración de FCM en Firebase Console\n")
    else:
        print("💡 Verifica que:")
        print("   - El token FCM sea válido")
        print("   - El dispositivo tenga conexión a internet")
        print("   - La app tenga permisos de notificaciones\n")

    sys.exit(1)
