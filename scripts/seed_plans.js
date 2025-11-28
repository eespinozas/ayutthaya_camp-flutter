// Script para Firebase Console (JavaScript)
// Cópialo y pégalo en: Firebase Console > Firestore > Abrir en Cloud Shell

const admin = require('firebase-admin');

// Si ya está inicializado, usa admin.firestore() directamente
// Si no, inicializa primero:
// admin.initializeApp();

const db = admin.firestore();

const plans = [
  {
    name: 'Plan Novato',
    price: 10000,
    durationDays: 30,
    description: '1 clase mensual - Ideal para probar',
    active: true,
    displayOrder: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
  },
  {
    name: 'Plan Iniciado',
    price: 35000,
    durationDays: 30,
    description: '4 clases mensuales - Para empezar tu entrenamiento',
    active: true,
    displayOrder: 2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
  },
  {
    name: 'Plan Guerrero',
    price: 45000,
    durationDays: 30,
    description: '8 clases mensuales - Entrena de forma regular',
    active: true,
    displayOrder: 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
  },
  {
    name: 'Plan Nak Muay',
    price: 55000,
    durationDays: 30,
    description: '12 clases mensuales - Mejora tu técnica',
    active: true,
    displayOrder: 4,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
  },
  {
    name: 'Plan Peleador',
    price: 65000,
    durationDays: 30,
    description: 'Clases ilimitadas - Entrena todos los días',
    active: true,
    displayOrder: 5,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: null,
  },
];

async function seedPlans() {
  console.log('🔥 Iniciando seed de planes...\n');

  const batch = db.batch();

  plans.forEach((plan) => {
    const docRef = db.collection('plans').doc();
    batch.set(docRef, plan);
    console.log(`✅ Preparando: ${plan.name} - $${plan.price}`);
  });

  await batch.commit();

  console.log('\n🎉 Todos los planes fueron agregados exitosamente!');
}

seedPlans().catch(console.error);
