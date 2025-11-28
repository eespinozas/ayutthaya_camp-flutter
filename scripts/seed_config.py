#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para crear la configuración inicial en Firestore

Uso:
  python scripts/seed_config.py [ruta_al_service_account.json]

  O con variable de entorno:
  export FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json
  python scripts/seed_config.py

Requisitos:
  pip install firebase-admin
"""

import sys
import io
import os
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Determinar ruta del service account
service_account_path = None

# 1. Desde argumento de línea de comandos
if len(sys.argv) > 1:
    service_account_path = sys.argv[1]
    print(f'Usando service account desde argumento: {service_account_path}')
# 2. Desde variable de entorno
elif 'FIREBASE_SERVICE_ACCOUNT' in os.environ:
    service_account_path = os.environ['FIREBASE_SERVICE_ACCOUNT']
    print(f'Usando service account desde variable de entorno: {service_account_path}')
# 3. Valor por defecto
else:
    service_account_path = 'scripts/firebase-service-account.json'
    print(f'Usando service account por defecto: {service_account_path}')

# Verificar que el archivo existe
if not os.path.exists(service_account_path):
    print(f'\nERROR: No se encontro el archivo: {service_account_path}')
    print('\nUso:')
    print('  python scripts/seed_config.py [ruta_al_service_account.json]')
    print('  O configura la variable de entorno FIREBASE_SERVICE_ACCOUNT')
    sys.exit(1)

# Inicializar Firebase Admin SDK
cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

print('Creando configuracion inicial en Firestore...\n')

# ============================================
# 1. App Settings
# ============================================
print('[1/4] Creando app_settings...')
app_settings = {
    'maintenance_mode': False,
    'min_app_version': '1.0.0',
    'force_update': False,
    'support_email': 'soporte@ayutthayacamp.com',
    'support_phone': '+506-1234-5678',
    'default_class_capacity': 15,
    'max_advance_booking_days': 7,
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('config').document('app_settings').set(app_settings)
print('   OK app_settings creado')
print(f'      - maintenance_mode: {app_settings["maintenance_mode"]}')
print(f'      - default_class_capacity: {app_settings["default_class_capacity"]}')
print(f'      - max_advance_booking_days: {app_settings["max_advance_booking_days"]}')
print()

# ============================================
# 2. Payment Settings
# ============================================
print('[2/4] Creando payment_settings...')
payment_settings = {
    'enrollment_price': 30000,
    'currency': 'CRC',
    'currency_symbol': '₡',
    'payment_methods': ['sinpe', 'transferencia', 'efectivo'],
    'require_receipt': True,
    'auto_approve_enabled': False,
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('config').document('payment_settings').set(payment_settings)
print('   OK payment_settings creado')
print(f'      - enrollment_price: {payment_settings["currency_symbol"]}{payment_settings["enrollment_price"]}')
print(f'      - payment_methods: {", ".join(payment_settings["payment_methods"])}')
print(f'      - auto_approve_enabled: {payment_settings["auto_approve_enabled"]}')
print()

# ============================================
# 3. Feature Flags
# ============================================
print('[3/4] Creando feature_flags...')
feature_flags = {
    'booking_enabled': True,
    'payments_enabled': True,
    'qr_checkin_enabled': True,
    'chat_support_enabled': False,
    'push_notifications_enabled': True,
    'admin_reports_enabled': True,
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('config').document('feature_flags').set(feature_flags)
print('   OK feature_flags creado')
print(f'      - booking_enabled: {feature_flags["booking_enabled"]}')
print(f'      - payments_enabled: {feature_flags["payments_enabled"]}')
print(f'      - qr_checkin_enabled: {feature_flags["qr_checkin_enabled"]}')
print(f'      - chat_support_enabled: {feature_flags["chat_support_enabled"]}')
print()

# ============================================
# 4. Business Info
# ============================================
print('[4/4] Creando business_info...')
business_info = {
    'gym_name': 'Ayutthaya Camp',
    'address': 'San José, Costa Rica',
    'schedule': 'Lun-Vie: 7am-10pm, Sáb: 9am-2pm',
    'about': 'Gimnasio especializado en Muay Thai y Boxing. Ofrecemos clases para todos los niveles con instructores certificados.',
    'social_media': {
        'facebook': 'https://facebook.com/ayutthayacamp',
        'instagram': 'https://instagram.com/ayutthayacamp',
        'whatsapp': '+506-1234-5678',
    },
    'updatedAt': firestore.SERVER_TIMESTAMP,
}

db.collection('config').document('business_info').set(business_info)
print('   OK business_info creado')
print(f'      - gym_name: {business_info["gym_name"]}')
print(f'      - address: {business_info["address"]}')
print(f'      - schedule: {business_info["schedule"]}')
print()

print('===========================================')
print('OK Configuracion creada exitosamente')
print('===========================================')
print()
print('Documentos creados:')
print('   - config/app_settings')
print('   - config/payment_settings')
print('   - config/feature_flags')
print('   - config/business_info')
print()
print('Proximos pasos:')
print('   1. Ejecuta: flutter run')
print('   2. La app cargara la configuracion automaticamente')
print('   3. Para editar: Firebase Console -> Firestore -> config/')
print()
