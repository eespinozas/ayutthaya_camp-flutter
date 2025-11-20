import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'agendar_page.dart';
import 'mis_clases_page.dart';
import 'pagos_page.dart';
import 'perfil_page.dart';

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  int _selectedIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();     // Inicio
      case 1:
        return const AgendarPage();       // Agendar
      case 2:
        return const MisClasesPage();     // Mis Clases
      case 3:
        return const PagosPage();         // Pagos / Historial de Pagos
      case 4:
        return const PerfilPage();        // Mi Perfil
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _buildPage(_selectedIndex);

    // OJO:
    // Cada una de las páginas internas (DashboardPage, AgendarPage, etc.)
    // ya es un Scaffold con su propio AppBar (excepto DashboardPage).
    // Para no tener un Scaffold dentro de otro Scaffold con AppBar doble,
    // hacemos esto:
    final bool pageYaTieneAppBar = _selectedIndex != 0; // DashboardPage NO tiene AppBar propio

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: pageYaTieneAppBar
            ? currentPage
            : currentPage, 
        // si más adelante quieres que DashboardPage tenga AppBar también,
        // puedes hacer que DashboardPage sea un Scaffold y aquí simplemente
        // usar `currentPage` para todos los casos.
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Agendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Mis Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }
}
