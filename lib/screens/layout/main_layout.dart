import 'package:flutter/material.dart';
import 'custom_top_bar.dart';
import 'sidebar.dart';
import '../usuarios_screen.dart';
import '../clientes_screen.dart';

class MainLayout extends StatefulWidget {
  final String rol;
  final String nombreUsuario; // ← recomendado

  const MainLayout({
    super.key,
    required this.rol,
    required this.nombreUsuario,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarCollapsed = false;
  String _currentSection = '';

  @override
  void initState() {
    super.initState();

    /// 🔑 ROL → SECCIÓN INICIAL
    _currentSection =
    widget.rol == 'Administrador' ? 'dashboard' : 'venta_rapida';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Column(
        children: [
          /// 🔝 TOP BAR (YA NO FLOTA)
          CustomTopBar(
            section: _currentSection,
            onMenuTap: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            }, sectionTitle: '', userName: '',
          ),

          /// CONTENIDO PRINCIPAL
          Expanded(
            child: Row(
              children: [
                /// SIDEBAR
                Sidebar(
                  collapsed: _sidebarCollapsed,
                  onToggle: () {
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                  },
                  onSelect: (section) {
                    setState(() => _currentSection = section);
                  },
                ),

                /// CONTENIDO CENTRAL
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🧠 MAPEA CLAVES → TÍTULOS HUMANOS
  String _mapSectionTitle(String section) {
    switch (section) {
      case 'dashboard':
        return 'Dashboard';
      case 'venta_rapida':
        return 'Venta rápida';
      default:
        return 'Sección';
    }
  }

  Widget _buildContent() {
    switch (_currentSection) {
      case 'dashboard':
        return const Center(child: Text('Dashboard'));
      case 'venta_rapida':
        return const Center(child: Text('Venta Rápida'));
      case 'usuarios':
        return const UsuariosScreen();
      case 'clientes':
        return const ClientesScreen();
      default:
        return const Center(child: Text('Sección'));
    }
  }
}