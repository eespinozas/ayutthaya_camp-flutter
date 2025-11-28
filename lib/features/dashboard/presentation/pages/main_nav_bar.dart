import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'agendar_page.dart';
import 'mis_clases_page.dart';
import 'pagos_page.dart';
import 'perfil_page.dart';
import 'qr_scanner_page.dart';

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
        return DashboardPage(
          onNavigateToPagos: () {
            setState(() {
              _selectedIndex = 3; // Navega al tab de Pagos
            });
          },
        );     // Inicio
      case 1:
        return const AgendarPage();       // Agendar
      case 2:
        return const MisClasesPage();     // Mis Clases
      case 3:
        return const PagosPage();         // Pagos / Historial de Pagos
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onQRPressed() async {
    try {
      // Abrir el escáner de QR
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerPage(),
        ),
      );

      // Si se escaneó un QR válido
      if (result != null && mounted) {
        // Mostrar información del QR escaneado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR escaneado: ${result['class']} - ${result['time']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Agendar',
              textColor: Colors.white,
              onPressed: () {
                // Cambiar al tab de Agendar
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _buildPage(_selectedIndex);

    // Cada una de las páginas ya es un Scaffold con su propio AppBar
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: currentPage,
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onQRPressed,
            borderRadius: BorderRadius.circular(35),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2A2A2A),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        elevation: 8,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lado izquierdo - dos botones
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      label: 'Inicio',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Agendar',
                      index: 1,
                    ),
                  ],
                ),
              ),
              // Espacio para el botón flotante QR
              const SizedBox(width: 80),
              // Lado derecho - dos botones
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.fitness_center,
                      label: 'Mis Clases',
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.payments_outlined,
                      label: 'Pagos',
                      index: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final itemColor = isSelected ? const Color(0xFFFF6B35) : Colors.white70;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: itemColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
