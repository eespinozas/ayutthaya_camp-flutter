import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/tw_background.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});
  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  final _pages = const [DashboardPage(), Placeholder(), Placeholder(), Placeholder()];

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst); // volver al login (MyApp decide)
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant.withOpacity(0.18);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_index == 0 ? 'Bienvenido' : const ['Dashboard','Reservas','Pagos','Perfil'][0]),
        actions: [
          IconButton(tooltip: 'Inicio', onPressed: () => setState(() => _index = 0), icon: const Icon(Icons.home_outlined)),
          IconButton(tooltip: 'Cerrar sesión', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: TwBackground(expandChild: true, applyTextWhite: true, child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 0.8, color: dividerColor),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
                  NavigationDestination(icon: Icon(Icons.event), selectedIcon: Icon(Icons.event_available), label: 'Reservas'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pagos'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
