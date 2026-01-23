importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Configuración de Firebase - reemplaza con tus credenciales
firebase.initializeApp({
  apiKey: "AIzaSyAvzSmDVLKNUxNaS-ia8YvU4m3TXFVf-ZE",
  authDomain: "ayuthaya-camp.firebaseapp.com",
  projectId: "ayuthaya-camp",
  storageBucket: "ayuthaya-camp.firebasestorage.app",
  messagingSenderId: "611359423677",
  appId: "1:611359423677:web:e16824168b1803b2afcbd4"
});

const messaging = firebase.messaging();

// Manejar mensajes en segundo plano
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Nueva notificación';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'default',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Manejar clics en notificaciones
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  // Abrir la aplicación
  event.waitUntil(
    clients.openWindow('/')
  );
});
