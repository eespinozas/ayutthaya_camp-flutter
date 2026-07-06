import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import 'admin_dashboard_page.dart';
import 'admin_alumnos_page.dart';
import 'admin_pagos_page.dart';
import 'admin_clases_page.dart';
import 'admin_reportes_page.dart';
import 'admin_perfil_page.dart';

class _AdminNavItem {
  final String id;
  final IconData icon;
  final String label;
  final WidgetBuilder pageBuilder;

  const _AdminNavItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.pageBuilder,
  });
}

class AdminMainNavBar extends StatefulWidget {
  const AdminMainNavBar({super.key});

  @override
  State<AdminMainNavBar> createState() => _AdminMainNavBarState();
}

class _AdminMainNavBarState extends State<AdminMainNavBar> {
  int _selectedIndex = 0;

  // El tab Pagos se oculta para administradores; los índices del resto
  // se derivan de la posición en esta lista, así la navegación no se rompe.
  List<_AdminNavItem> _navItemsFor(bool isAdmin) {
    return [
      _AdminNavItem(
        id: 'inicio',
        icon: Icons.dashboard_outlined,
        label: 'Inicio',
        pageBuilder: (_) => const AdminDashboardPage(),
      ),
      _AdminNavItem(
        id: 'alumnos',
        icon: Icons.people_outline,
        label: 'Alumnos',
        pageBuilder: (_) => AdminAlumnosPage(
          onNavigateToPagos: _navigateToPagos,
        ),
      ),
      if (!isAdmin)
        _AdminNavItem(
          id: 'pagos',
          icon: Icons.payment,
          label: 'Pagos',
          pageBuilder: (_) => const AdminPagosPage(),
        ),
      _AdminNavItem(
        id: 'clases',
        icon: Icons.fitness_center,
        label: 'Clases',
        pageBuilder: (_) => const AdminClasesPage(),
      ),
      _AdminNavItem(
        id: 'reportes',
        icon: Icons.bar_chart,
        label: 'Reportes',
        pageBuilder: (_) => const AdminReportesPage(),
      ),
      _AdminNavItem(
        id: 'perfil',
        icon: Icons.person_outline,
        label: 'Perfil',
        pageBuilder: (_) => const AdminPerfilPage(),
      ),
    ];
  }

  void _navigateToPagos() {
    final isAdmin = context.read<AuthViewModel>().isAdmin;
    final items = _navItemsFor(isAdmin);
    final pagosIndex = items.indexWhere((item) => item.id == 'pagos');
    if (pagosIndex == -1) return; // Admin: Pagos no disponible.
    setState(() {
      _selectedIndex = pagosIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthViewModel>().isAdmin;
    final items = _navItemsFor(isAdmin);
    final selectedIndex = _selectedIndex.clamp(0, items.length - 1);
    final currentPage = items[selectedIndex].pageBuilder(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: currentPage,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFFF6A00),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
