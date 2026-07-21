// Selector de entorno Firebase (prod por defecto, QA con dart-define).
//
//   flutter run --dart-define=APP_ENV=qa          -> ayutthaya-camp-qa
//   flutter build ... (sin define)                -> ayuthaya-camp (prod)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'firebase_options.dart';
import 'firebase_options_qa.dart';

const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');

bool get isQa => appEnv == 'qa';

FirebaseOptions get firebaseOptionsForEnv => isQa
    ? QaFirebaseOptions.currentPlatform
    : DefaultFirebaseOptions.currentPlatform;
