import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app/app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runZonedGuarded(() {
    runApp(const App());
  }, (error, stack) {
    // Esto asegura log del error en web
    // ignore: avoid_print
    print('Uncaught zone error: $error');
    // ignore: avoid_print
    print(stack);
  });
}
