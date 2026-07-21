// Opciones de Firebase para el entorno QA (proyecto ayutthaya-camp-qa).
// Generado desde `firebase apps:sdkconfig` — mismo formato que firebase_options.dart.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// [FirebaseOptions] del entorno QA. Se selecciona con
/// `--dart-define=APP_ENV=qa` (ver firebase_env.dart).
class QaFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'QaFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlRcHn32H4Vd_4g6GzzjHBAPiJMcS_Eu4',
    appId: '1:691167888702:web:a89da14d54ddd6b2e2586f',
    messagingSenderId: '691167888702',
    projectId: 'ayutthaya-camp-qa',
    authDomain: 'ayutthaya-camp-qa.firebaseapp.com',
    storageBucket: 'ayutthaya-camp-qa.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCeytruYWtsm_qyJtfUG33XSDFUA_09bmo',
    appId: '1:691167888702:android:7baa90a85a4d2df7e2586f',
    messagingSenderId: '691167888702',
    projectId: 'ayutthaya-camp-qa',
    storageBucket: 'ayutthaya-camp-qa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuh9R5OWiOe7B-1VpfjM8zNB27qpYumAk',
    appId: '1:691167888702:ios:12b8ca8e69df4991e2586f',
    messagingSenderId: '691167888702',
    projectId: 'ayutthaya-camp-qa',
    storageBucket: 'ayutthaya-camp-qa.firebasestorage.app',
    iosBundleId: 'com.ayutthaya.ayutthayaCamp',
  );
}
