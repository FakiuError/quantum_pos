import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;
  final Function(String) onSelect;

  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: collapsed ? 70 : 240,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 64),
          _item(Icons.home, 'Home', 'dashboard'),
          _item(Icons.shopping_cart, 'Venta rápida', 'venta_rapida'),
          _item(Icons.inventory_2, 'Productos', 'productos'),
          _item(Icons.local_shipping, 'Proveedores', 'proveedores'),
          _item(Icons.assignment_ind, 'Clientes', 'clientes'),
          _item(Icons.people, 'Usuarios', 'usuarios'),
          _item(Icons.deck, 'Mesas', 'mesas'),
          _item(Icons.bar_chart, 'Reportes', 'reportes'),

          const Spacer(),

          IconButton(
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.chevron_left,
            ),
            onPressed: onToggle,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String key) {
    return InkWell(
      onTap: () => onSelect(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFc0733d)),
            if (!collapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
