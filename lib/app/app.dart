import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../features/auth/data/auth_api.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/dashboard/presentation/pages/main_nav_bar.dart'; // 👈 NUEVO: barra inferior
// import '../features/shell/presentation/pages/shell_page.dart'; // ya no usamos ShellPage visualmente

import '../features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';

import 'theme.dart';

class Routes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const shell = '/shell'; // (lo puedes dejar si se usa en otra parte)
  static const mainNav = '/main'; // 👈 NUEVA ruta (navbar)
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1) ApiClient (HTTP → tu backend)
        Provider<ApiClient>(
          create: (_) => ApiClient(
            baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
                ? const String.fromEnvironment('API_BASE_URL')
                : (dotenv.maybeGet('API_BASE_URL') ?? 'http://localhost:3000'),
          ),
        ),

        // 2) Auth API
        ProxyProvider<ApiClient, AuthApi>(
          update: (_, apiClient, __) => AuthApi(apiClient),
        ),

        // 3) Auth Repository
        ProxyProvider<AuthApi, AuthRepository>(
          update: (_, api, __) => AuthRepositoryImpl(api: api),
        ),

        // 4) Auth ViewModel (maneja login, sesión, etc.)
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) =>
              AuthViewModel(ctx.read<AuthRepository>())..checkSession(),
        ),

        // 5) Dashboard ViewModel
        ChangeNotifierProvider<DashboardViewModel>(
          create: (_) => DashboardViewModel(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ayutthaya',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,

        routes: {
          Routes.login: (_) => const LoginPage(),
          Routes.register: (_) => const RegisterPage(),
          Routes.dashboard: (_) => const DashboardPage(),
          // Routes.shell: (_) => const ShellPage(), // ya no lo usamos como pantalla inicial
          Routes.mainNav: (_) => const MainNavBar(), // 👈 ruta a la navbar
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
        // Si está logeado → entramos a la app con la barra inferior (MainNavBar)
        // Si NO está logeado → LoginPage
        return vm.isLoggedIn
            ? const MainNavBar()
            : const LoginPage();
      },
    );
  }
}
