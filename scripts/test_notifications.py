#!/usr/bin/env python3
"""
Script para probar notificaciones push antes de publicar la app
Requiere: pip install firebase-admin
"""

import firebase_admin
from firebase_admin import credentials, firestore, messaging
import sys
from datetime import datetime, timedelta

# Inicializar Firebase Admin
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Conectado a Firebase")
except Exception as e:
    print(f"❌ Error conectando a Firebase: {e}")
    print("\n💡 Asegúrate de tener el archivo 'serviceAccountKey.json' en la raíz del proyecto")
    print("   Descárgalo desde: Firebase Console > Project Settings > Service accounts > Generate new private key")
    sys.exit(1)

def show_menu():
    """Muestra el menú principal"""
    print("\n" + "="*60)
    print("🔔 PRUEBA DE NOTIFICACIONES PUSH")
    print("="*60)
    print("1. Ver usuarios con FCM token")
    print("2. Enviar notificación de prueba a un usuario")
    print("3. Enviar notificación de prueba a todos los admins")
    print("4. Enviar notificación de prueba a TU dispositivo")
    print("5. Ver notificaciones pendientes")
    print("6. Ver recordatorios programados")
    print("7. Crear recordatorio de prueba")
    print("0. Salir")
    print("="*60)

def get_users_with_tokens():
    """Obtiene usuarios que tienen FCM token"""
    users = db.collection('users').stream()
    user_list = []

    print("\n📱 Usuarios con FCM token:")
    print("-" * 80)
    print(f"{'#':<4} {'Email':<30} {'Nombre':<25} {'Role':<10}")
    print("-" * 80)

    for user in users:
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
            print(f"{len(user_list):<4} {user_data.get('email', 'N/A'):<30} {user_data.get('name', 'N/A'):<25} {user_data.get('role', 'user'):<10}")

    print("-" * 80)
    print(f"Total: {len(user_list)} usuarios\n")
    return user_list

def send_test_notification_to_user(user_id, fcm_token):
    """Envía notificación de prueba a un usuario específico"""
    try:
        # Crear documento en la colección 'notifications'
        # La Cloud Function lo detectará y enviará la notificación automáticamente
        notification_ref = db.collection('notifications').add({
            'userId': user_id,
            'fcmToken': fcm_token,
            'title': '🧪 Notificación de Prueba',
            'body': f'Esta es una notificación de prueba enviada el {datetime.now().strftime("%H:%M:%S")}',
            'data': {
                'type': 'test',
                'timestamp': datetime.now().isoformat()
            },
            'createdAt': firestore.SERVER_TIMESTAMP,
            'sent': False
        })

        print(f"✅ Notificación creada con ID: {notification_ref[1].id}")
        print("⏳ La Cloud Function la enviará en unos segundos...")
        print("💡 Revisa tu dispositivo para ver la notificación")

    except Exception as e:
        print(f"❌ Error enviando notificación: {e}")

def send_test_to_admins():
    """Envía notificación de prueba a todos los admins"""
    try:
        admins = db.collection('users').where('role', '==', 'admin').stream()

        count = 0
        for admin in admins:
            admin_data = admin.to_dict()
            fcm_token = admin_data.get('fcmToken')

            if fcm_token:
                db.collection('notifications').add({
                    'userId': admin.id,
                    'fcmToken': fcm_token,
                    'title': '👨‍💼 Notificación Admin de Prueba',
                    'body': f'Prueba de notificación para administradores - {datetime.now().strftime("%H:%M:%S")}',
                    'data': {
                        'type': 'admin_test',
                        'timestamp': datetime.now().isoformat()
                    },
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'sent': False
                })
                count += 1
                print(f"✅ Notificación creada para admin: {admin_data.get('email')}")

        print(f"\n📨 Total de notificaciones creadas: {count}")
        print("⏳ Las Cloud Functions las enviarán en unos segundos...")

    except Exception as e:
        print(f"❌ Error enviando notificaciones: {e}")

def view_pending_notifications():
    """Ver notificaciones pendientes de enviar"""
    try:
        notifications = db.collection('notifications').where('sent', '==', False).limit(20).stream()

        print("\n📬 Notificaciones pendientes:")
        print("-" * 100)
        print(f"{'ID':<25} {'Usuario':<30} {'Título':<30} {'Creada':<15}")
        print("-" * 100)

        count = 0
        for notif in notifications:
            notif_data = notif.to_dict()
            created_at = notif_data.get('createdAt')
            created_str = created_at.strftime("%Y-%m-%d %H:%M") if created_at else 'N/A'

            print(f"{notif.id[:24]:<25} {notif_data.get('userId', 'N/A')[:29]:<30} {notif_data.get('title', 'N/A')[:29]:<30} {created_str:<15}")
            count += 1

        print("-" * 100)
        print(f"Total: {count} notificaciones pendientes\n")

    except Exception as e:
        print(f"❌ Error obteniendo notificaciones: {e}")

def view_scheduled_reminders():
    """Ver recordatorios programados"""
    try:
        reminders = db.collection('scheduled_notifications').where('sent', '==', False).limit(20).stream()

        print("\n⏰ Recordatorios programados:")
        print("-" * 110)
        print(f"{'ID':<25} {'Usuario':<30} {'Programado para':<20} {'Título':<30}")
        print("-" * 110)

        count = 0
        for reminder in reminders:
            reminder_data = reminder.to_dict()
            scheduled_for = reminder_data.get('scheduledFor')
            scheduled_str = scheduled_for.strftime("%Y-%m-%d %H:%M") if scheduled_for else 'N/A'

            print(f"{reminder.id[:24]:<25} {reminder_data.get('userId', 'N/A')[:29]:<30} {scheduled_str:<20} {reminder_data.get('title', 'N/A')[:29]:<30}")
            count += 1

        print("-" * 110)
        print(f"Total: {count} recordatorios programados\n")

    except Exception as e:
        print(f"❌ Error obteniendo recordatorios: {e}")

def create_test_reminder(user_id, fcm_token):
    """Crea un recordatorio de prueba que se enviará en 2 minutos"""
    try:
        # Programar para 2 minutos en el futuro
        reminder_time = datetime.now() + timedelta(minutes=2)

        db.collection('scheduled_notifications').add({
            'bookingId': 'test_booking_123',
            'userId': user_id,
            'title': '🧪 Recordatorio de Prueba',
            'body': 'Este es un recordatorio de prueba. Debería llegar en 2 minutos.',
            'data': {
                'type': 'class_reminder',
                'bookingId': 'test_booking_123',
                'minutesBefore': 15,
                'test': True
            },
            'scheduledFor': reminder_time,
            'sent': False,
            'createdAt': firestore.SERVER_TIMESTAMP
        })

        print(f"✅ Recordatorio de prueba creado")
        print(f"⏰ Programado para: {reminder_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"⏳ Se enviará en aproximadamente 2 minutos")
        print("💡 La Cloud Function lo procesará automáticamente")

    except Exception as e:
        print(f"❌ Error creando recordatorio: {e}")

def send_direct_notification(fcm_token):
    """Envía una notificación directa usando el SDK (sin Cloud Function)"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title='🧪 Notificación Directa de Prueba',
                body=f'Esta notificación se envió directamente usando el Admin SDK a las {datetime.now().strftime("%H:%M:%S")}'
            ),
            data={
                'type': 'direct_test',
                'timestamp': datetime.now().isoformat()
            },
            token=fcm_token,
            android=messaging.AndroidConfig(
                notification=messaging.AndroidNotification(
                    sound='default',
                    priority='high'
                )
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1
                    )
                )
            )
        )

        response = messaging.send(message)
        print(f"✅ Notificación directa enviada exitosamente")
        print(f"📨 Message ID: {response}")
        print("💡 Revisa tu dispositivo inmediatamente")

    except Exception as e:
        print(f"❌ Error enviando notificación directa: {e}")
        if 'registration-token-not-registered' in str(e):
            print("⚠️  El token FCM parece ser inválido o expirado")
            print("💡 Intenta abrir la app en el dispositivo para regenerar el token")

def main():
    """Función principal"""
    while True:
        show_menu()
        choice = input("\nElige una opción (0-7): ").strip()

        if choice == '0':
            print("\n👋 ¡Hasta luego!")
            break

        elif choice == '1':
            get_users_with_tokens()

        elif choice == '2':
            users = get_users_with_tokens()
            if not users:
                print("⚠️  No hay usuarios con FCM token")
                continue

            try:
                user_num = int(input("\nIngresa el número de usuario (o 0 para cancelar): "))
                if user_num == 0:
                    continue
                if 1 <= user_num <= len(users):
                    user = users[user_num - 1]
                    print(f"\n📱 Enviando notificación a: {user['email']}")
                    send_test_notification_to_user(user['id'], user['fcmToken'])
                else:
                    print("❌ Número inválido")
            except ValueError:
                print("❌ Ingresa un número válido")

        elif choice == '3':
            confirm = input("\n⚠️  ¿Enviar notificación a TODOS los admins? (s/n): ")
            if confirm.lower() == 's':
                send_test_to_admins()
            else:
                print("❌ Cancelado")

        elif choice == '4':
            users = get_users_with_tokens()
            if not users:
                print("⚠️  No hay usuarios con FCM token")
                continue

            try:
                user_num = int(input("\nIngresa el número de tu usuario (o 0 para cancelar): "))
                if user_num == 0:
                    continue
                if 1 <= user_num <= len(users):
                    user = users[user_num - 1]
                    print(f"\n📱 Enviando notificación DIRECTA a: {user['email']}")
                    send_direct_notification(user['fcmToken'])
                else:
                    print("❌ Número inválido")
            except ValueError:
                print("❌ Ingresa un número válido")

        elif choice == '5':
            view_pending_notifications()

        elif choice == '6':
            view_scheduled_reminders()

        elif choice == '7':
            users = get_users_with_tokens()
            if not users:
                print("⚠️  No hay usuarios con FCM token")
                continue

            try:
                user_num = int(input("\nIngresa el número de usuario (o 0 para cancelar): "))
                if user_num == 0:
                    continue
                if 1 <= user_num <= len(users):
                    user = users[user_num - 1]
                    print(f"\n⏰ Creando recordatorio para: {user['email']}")
                    create_test_reminder(user['id'], user['fcmToken'])
                else:
                    print("❌ Número inválido")
            except ValueError:
                print("❌ Ingresa un número válido")

        else:
            print("❌ Opción inválida")

        input("\nPresiona Enter para continuar...")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Programa interrumpido. ¡Hasta luego!")
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        sys.exit(1)
