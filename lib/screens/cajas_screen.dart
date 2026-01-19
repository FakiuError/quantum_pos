import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/cajas_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_caja_dialog.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';

class CajasScreen extends StatefulWidget {
  const CajasScreen({Key? key}) : super(key: key);

  @override
  State<CajasScreen> createState() => _CajasScreenState();
}

class _CajasScreenState extends State<CajasScreen> {
  final CajasService _service = CajasService();


  bool _loading = true;

  List<Map<String, dynamic>> _cajasAbiertas = [];
  Map<String, dynamic>? _cajaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCajas();
  }

  Future<void> _cargarCajas() async {
    final res = await _service.obtenerCajasAbiertas();

    List<Map<String, dynamic>> cajas = [];

    if (res['data'] != null && res['data'] is List) {
      cajas = (res['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    setState(() {
      _cajasAbiertas = cajas;
      _cajaSeleccionada ??= cajas.isNotEmpty ? cajas.first : null;
      _loading = false;
    });
  }

  Future<void> _confirmarCancelarCaja() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar caja'),
        content: const Text(
          '¿Estás seguro de cancelar esta caja?\n\n'
              'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _service.cancelarCaja(_cajaSeleccionada!['id']);

      // Si era la caja activa → limpiar
      if (CajaActiva().caja?['id'] == _cajaSeleccionada!['id']) {
        CajaActiva().limpiar();
      }

      _cargarCajas(); // recarga cajas
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCajaActiva(),
          const SizedBox(height: 24),
          const Text(
            'Cajas abiertas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildListadoCajas()),
        ],
      ),
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Gestión de cajas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nueva caja'),
          onPressed: () async {
            final creada = await showDialog(
              context: context,
              builder: (_) => const CrearCajaDialog(),
            );

            if (creada == true) {
              _cargarCajas();
            }
          },
        ),
      ],
    );
  }

  // ───────────────── CAJA SELECCIONADA ─────────────────
  Widget _buildCajaActiva() {
    if (_cajaSeleccionada == null) {
      return const Center(child: Text('No hay cajas abiertas'));
    }

    final c = _cajaSeleccionada!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('Empleado', c['empleado']),
                _info('Fecha apertura', c['fecha_apertura']),
                const SizedBox(height: 12),
                _info('Base', c['saldo_base']),
                _info('Efectivo', c['efectivo']),
                _info('Nequi', c['nequi']),
                _info('Daviplata', c['daviplata']),
              ],
            ),
          ),

          // ICONO + BOTONES
          Column(
            children: [
              Image.asset(
                'assets/img/punto-de-venta.png',
                height: 110,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      CajaActiva().activarCaja(_cajaSeleccionada!);

                      setState(() {});
                    },
                    child: const Text('Activar'),
                  ),
                  const SizedBox(width: 10),
                  if (_cajaSeleccionada != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar caja'),
                      onPressed: () => _confirmarCancelarCaja(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── LISTADO CAJAS ─────────────────
  Widget _buildListadoCajas() {
    if (_cajasAbiertas.isEmpty) {
      return const Center(child: Text('No hay cajas abiertas'));
    }

    return GridView.builder(
      itemCount: _cajasAbiertas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) {
        final c = _cajasAbiertas[i];
        final selected = _cajaSeleccionada?['id'] == c['id'];
        final activa = CajaActiva().caja?['id'] == c['id'];

        return InkWell(
          onTap: () {
            setState(() {
              _cajaSeleccionada = c;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activa
                  ? Colors.green.withOpacity(0.12) // 👈 ACTIVA
                  : selected
                  ? const Color(0xFFc0733d).withOpacity(0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activa
                    ? Colors.green // 👈 BORDE ACTIVA
                    : selected
                    ? const Color(0xFFc0733d)
                    : Colors.grey.shade300,
                width: activa ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.point_of_sale,
                  size: 28,
                  color: activa ? Colors.green : Colors.black87,
                ),

                // 🔹 BADGE ACTIVA
                if (activa)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'ACTIVA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 6),

                Text(
                  c['empleado'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  c['fecha_apertura'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────── HELPERS ─────────────────
  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
