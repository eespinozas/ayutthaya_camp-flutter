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
              _selectedIndex = 3;
            });
          },
        );
      case 1:
        return const AgendarPage();
      case 2:
        return const MisClasesPage();
      case 3:
        return const PagosPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _onQRPressed() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerPage(),
        ),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR escaneado: ${result['class']} - ${result['time']}',
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Agendar',
              textColor: Colors.white,
              onPressed: () {
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
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _buildPage(_selectedIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: currentPage,
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6A00), Color(0xFFFF8534)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 5,
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
        color: const Color(0xFF1A1A1A),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        elevation: 8,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFFF6A00).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
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
                      icon: Icons.home_rounded,
                      label: 'Inicio',
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.calendar_month_rounded,
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
                      icon: Icons.payments_rounded,
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
    final itemColor = isSelected ? const Color(0xFFFF6A00) : Colors.white.withValues(alpha: 0.6);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: itemColor,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
