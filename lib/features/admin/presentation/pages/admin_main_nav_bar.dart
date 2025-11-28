import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'admin_alumnos_page.dart';
import 'admin_pagos_page.dart';
import 'admin_clases_page.dart';
import 'admin_reportes_page.dart';
import 'admin_perfil_page.dart';

class AdminMainNavBar extends StatefulWidget {
  const AdminMainNavBar({super.key});

  @override
  State<AdminMainNavBar> createState() => _AdminMainNavBarState();
}

class _AdminMainNavBarState extends State<AdminMainNavBar> {
  int _selectedIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardPage();  // Dashboard
      case 1:
        return AdminAlumnosPage(
          onNavigateToPagos: () {
            setState(() {
              _selectedIndex = 2; // Navegar a Pagos
            });
          },
        );    // Alumnos
      case 2:
        return const AdminPagosPage();      // Pagos
      case 3:
        return const AdminClasesPage();     // Clases
      case 4:
        return const AdminReportesPage();   // Reportes
      case 5:
        return const AdminPerfilPage();     // Perfil
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _buildPage(_selectedIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: currentPage,
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
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Alumnos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
