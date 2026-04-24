import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/dashboard/presentation/pages/main_nav_bar.dart';
import '../features/admin/presentation/pages/admin_main_nav_bar.dart';
import '../features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import '../features/payments/viewmodels/payment_viewmodel.dart';
import '../features/plans/viewmodels/plan_viewmodel.dart';
import '../features/schedules/viewmodels/class_schedule_viewmodel.dart';
import '../features/bookings/viewmodels/booking_viewmodel.dart';
import '../features/gamification/presentation/pages/avatar_test_screen.dart';

import 'theme.dart';

class Routes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const shell = '/shell'; // (lo puedes dejar si se usa en otra parte)
  static const mainNav = '/main'; // 👈 NUEVA ruta (navbar)
  static const avatarTest = '/avatar-test'; // Test screen for avatar animations
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth ViewModel (Firebase Auth directo)
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel()..checkSession(),
        ),

        // Dashboard ViewModel
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(),
        ),

        // Payment ViewModel (Firebase directo)
        ChangeNotifierProvider<PaymentViewModel>(
          create: (_) => PaymentViewModel(),
        ),

        // Plan ViewModel (Firebase directo)
        ChangeNotifierProvider<PlanViewModel>(
          create: (_) => PlanViewModel(),
        ),

        // ClassSchedule ViewModel (Firebase directo)
        ChangeNotifierProvider<ClassScheduleViewModel>(
          create: (_) => ClassScheduleViewModel(),
        ),

        // Booking ViewModel (Firebase directo)
        ChangeNotifierProvider<BookingViewModel>(
          create: (_) => BookingViewModel(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ayutthaya',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,

        // Configuración de localización para español
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés (fallback)
        ],
        locale: const Locale('es', 'ES'),

        routes: {
          Routes.login: (_) => const LoginPage(),
          Routes.register: (_) => const RegisterPage(),
          Routes.forgotPassword: (_) => const ForgotPasswordPage(),
          Routes.dashboard: (_) => const DashboardPage(),
          // Routes.shell: (_) => const ShellPage(), // ya no lo usamos como pantalla inicial
          Routes.mainNav: (_) => const MainNavBar(), // 👈 ruta a la navbar
          Routes.avatarTest: (_) => const AvatarTestScreen(), // Avatar animation test screen
        },

        // Pantalla inicial que decide a dónde ir
        home: const _SplashDecider(),
      ),
    );
  }
}

class _SplashDecider extends StatelessWidget {
  const _SplashDecider();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (_, vm, __) {
        if (vm.isCheckingSession) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ IMPORTANTE:
        // Si está logeado → verifica rol
        // - Admin → AdminMainNavBar
        // - Student → MainNavBar
        // Si NO está logeado → LoginPage
        if (!vm.isLoggedIn) {
          return const LoginPage();
        }

        return vm.isAdmin
            ? const AdminMainNavBar()
            : const MainNavBar();
      },
    );
  }
}
