import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import 'dashboard_page.dart';
import 'agendar_page.dart';
import 'mis_clases_page.dart';
import 'pagos_page.dart';
import 'qr_checkin_page.dart';

class _NavTab {
  final String id;
  final IconData icon;
  final String label;
  final WidgetBuilder pageBuilder;

  const _NavTab({
    required this.id,
    required this.icon,
    required this.label,
    required this.pageBuilder,
  });
}

class MainNavBar extends StatefulWidget {
  const MainNavBar({super.key});

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  int _selectedIndex = 0;

  // Los tabs ocultos por feature flag no se eliminan del código: al poner
  // su flag en true vuelven a aparecer y los índices se recalculan solos
  // porque siempre se trabaja sobre la lista filtrada.
  List<_NavTab> _visibleTabs() {
    return [
      if (FeatureFlags.showInicioTab)
        _NavTab(
          id: 'inicio',
          icon: Icons.home_rounded,
          label: 'Inicio',
          pageBuilder: (_) => DashboardPage(
            onNavigateToPagos: () => _selectTabById('pagos'),
          ),
        ),
      if (FeatureFlags.showAgendarTab)
        _NavTab(
          id: 'agendar',
          icon: Icons.calendar_month_rounded,
          label: 'Agendar',
          pageBuilder: (_) => const AgendarPage(),
        ),
      if (FeatureFlags.showMisClasesTab)
        _NavTab(
          id: 'mis_clases',
          icon: Icons.fitness_center,
          label: 'Mis Clases',
          pageBuilder: (_) => const MisClasesPage(),
        ),
      if (FeatureFlags.showPagosTab)
        _NavTab(
          id: 'pagos',
          icon: Icons.payments_rounded,
          label: 'Pagos',
          pageBuilder: (_) => const PagosPage(),
        ),
    ];
  }

  void _selectTabById(String id) {
    final tabs = _visibleTabs();
    final index = tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return; // Tab oculto por feature flag: no navegar.
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _onQRPressed() async {
    // QRCheckInPage escanea el QR del gimnasio y registra la asistencia
    // (antes se abría el escáner "pelado" y el resultado solo mostraba un
    // snackbar, sin registrar nada).
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRCheckInPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _visibleTabs();
    final selectedIndex = _selectedIndex.clamp(0, tabs.length - 1);
    final currentPage = tabs[selectedIndex].pageBuilder(context);

    // Distribución simétrica alrededor del FAB central: mitad de los tabs
    // visibles a la izquierda y mitad a la derecha.
    final splitIndex = (tabs.length / 2).ceil();
    final leftTabs = tabs.sublist(0, splitIndex);
    final rightTabs = tabs.sublist(splitIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: currentPage,
      // En web no hay check-in QR: sin FAB ni notch (ver FeatureFlags).
      floatingActionButton: !FeatureFlags.enableQrCheckIn
          ? null
          : Container(
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
        // Sin borde superior: una línea recta queda cortada por el notch del
        // FAB. La separación visual la dan la elevation y el color del bar.
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < leftTabs.length; i++)
                      _buildNavItem(
                        tab: leftTabs[i],
                        index: i,
                        selectedIndex: selectedIndex,
                      ),
                  ],
                ),
              ),
              // Espacio para el botón flotante QR
              if (FeatureFlags.enableQrCheckIn) const SizedBox(width: 80),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < rightTabs.length; i++)
                      _buildNavItem(
                        tab: rightTabs[i],
                        index: splitIndex + i,
                        selectedIndex: selectedIndex,
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
    required _NavTab tab,
    required int index,
    required int selectedIndex,
  }) {
    final isSelected = selectedIndex == index;
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
              tab.icon,
              color: itemColor,
              size: isSelected ? 26 : 24,
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
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
