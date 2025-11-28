import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/config_service.dart';
import 'core/services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar servicio de notificaciones
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('⚠️ Error inicializando notificaciones: $e');
  }

  // Cargar configuración de Firebase (no bloquear si falla)
  try {
    final configService = ConfigService();
    await configService.loadConfig();

    // Verificar modo mantenimiento
    if (configService.isMaintenanceMode) {
      runApp(const MaintenanceApp());
      return;
    }
  } catch (e) {
    debugPrint('⚠️ Error cargando configuración al inicio: $e');
    debugPrint('   La app continuará con valores por defecto');
  }

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

/// App simple para modo mantenimiento
class MaintenanceApp extends StatelessWidget {
  const MaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    String supportEmail = 'soporte@ayutthayacamp.com';
    try {
      supportEmail = ConfigService().supportEmail;
    } catch (e) {
      debugPrint('⚠️ No se pudo obtener supportEmail de ConfigService: $e');
    }

    return MaterialApp(
      title: 'Ayutthaya Camp - Mantenimiento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.build_circle,
                  size: 100,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Mantenimiento',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Estamos realizando mejoras en la aplicación.\nVolveremos pronto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Soporte: $supportEmail',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
