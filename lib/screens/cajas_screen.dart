import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/cajas_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_caja_dialog.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';
import 'package:panaderia_nicol_pos/screens/dialog/nuevo_gasto_dialog.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';
import 'package:open_filex/open_filex.dart';
import 'package:panaderia_nicol_pos/Services/reporte_caja_pdf_service.dart';

class CajasScreen extends StatefulWidget {
  const CajasScreen({Key? key}) : super(key: key);

  @override
  State<CajasScreen> createState() => _CajasScreenState();
}

class _CajasScreenState extends State<CajasScreen> {
  final CajasService _service = CajasService();


  bool _loading = true;
  bool _menuFlotanteAbierto = false;

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

      _cargarCajas();
    }
  }

  Future<void> _abrirVentasCajaActual() async {
    final idCaja = _idCajaActual();

    if (idCaja == null) {
      _mostrarMensaje('Debes seleccionar o activar una caja primero');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _service.obtenerVentasPorCaja(idCaja);

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] != true) {
      _mostrarMensaje(res['error'] ?? 'No se pudieron cargar las ventas');
      return;
    }

    final ventas = (res['data'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final caja = res['caja'] != null
        ? Map<String, dynamic>.from(res['caja'])
        : <String, dynamic>{};

    final huboCambios = await showDialog<bool>(
      context: context,
      builder: (_) => _VentasCajaDialog(
        idCaja: idCaja,
        caja: caja,
        ventas: ventas,
        totalVentas: _moneda(res['total']),
        service: _service,
        moneda: _moneda,
      ),
    );

    if (huboCambios == true) {
      await _cargarCajas();

      final idActiva = CajaActiva().idCaja;

      if (idActiva != null) {
        final actualizada = _cajasAbiertas.where(
              (c) => c['id'].toString() == idActiva.toString(),
        );

        if (actualizada.isNotEmpty) {
          CajaActiva().actualizarDesdeBackend(actualizada.first);
        }
      }

      setState(() {});
    }
  }

  Future<void> _abrirGastosCajaActual() async {
    final idCaja = _idCajaActual();

    if (idCaja == null) {
      _mostrarMensaje('Debes seleccionar o activar una caja primero');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _service.obtenerGastosPorCaja(idCaja);

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] != true) {
      _mostrarMensaje(res['error'] ?? 'No se pudieron cargar los gastos');
      return;
    }

    final gastos = (res['data'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final caja = res['caja'] != null
        ? Map<String, dynamic>.from(res['caja'])
        : <String, dynamic>{};

    final huboCambios = await showDialog<bool>(
      context: context,
      builder: (_) => _GastosCajaDialog(
        idCaja: idCaja,
        caja: caja,
        gastos: gastos,
        totalGastos: _moneda(res['total']),
        service: _service,
        moneda: _moneda,
      ),
    );

    if (huboCambios == true) {
      await _cargarCajas();

      final idActiva = CajaActiva().idCaja;

      if (idActiva != null) {
        final actualizada = _cajasAbiertas.where(
              (c) => c['id'].toString() == idActiva.toString(),
        );

        if (actualizada.isNotEmpty) {
          CajaActiva().actualizarDesdeBackend(actualizada.first);
        }
      }

      setState(() {});
    }
  }

  Future<void> _abrirCajasFinalizadas() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final res = await _service.obtenerCajasFinalizadas();

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] != true) {
      _mostrarMensaje(res['error'] ?? 'No se pudieron cargar las cajas finalizadas');
      return;
    }

    final cajas = (res['data'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showDialog(
      context: context,
      builder: (_) => _TablaCajaDialog(
        titulo: 'Cajas finalizadas',
        subtitulo: 'Histórico de cajas cerradas',
        totalLabel: 'Cajas cerradas',
        totalValor: cajas.length.toString(),
        columnas: const [
          'ID',
          'Empleado',
          'Apertura',
          'Cierre',
          'Base',
          'Bancolombia',
          'Ventas',
          'Gastos',
          'Resultado'
        ],
        filas: cajas.map((c) {
          return [
            c['id'].toString(),
            c['empleado'].toString(),
            c['fecha_apertura'].toString(),
            c['fecha_cierre'].toString(),
            _moneda(c['saldo_base']),
            _moneda(c['saldo_final_bancolombia']),
            _moneda(c['total_ventas']),
            _moneda(c['total_gastos']),
            _moneda(c['resultado']),
          ];
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Padding(
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
        ),

        _buildMenuFlotante(),
      ],
    );
  }

  int? _idCajaActual() {
    if (CajaActiva().idCaja != null) {
      return CajaActiva().idCaja;
    }

    if (_cajaSeleccionada != null) {
      return int.tryParse(_cajaSeleccionada!['id'].toString());
    }

    return null;
  }

  void _mostrarMensaje(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  String _moneda(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '\$ ${n.toStringAsFixed(0)}';
  }

  Widget _buildMenuFlotante() {
    return Positioned(
      right: 24,
      bottom: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          AnimatedOpacity(
            opacity: _menuFlotanteAbierto ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_menuFlotanteAbierto,
              child: Transform.translate(
                offset: _menuFlotanteAbierto
                    ? Offset.zero
                    : const Offset(0, 12),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 74, right: 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _botonOpcionFlotante(
                        label: 'Cajas finalizadas',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          setState(() => _menuFlotanteAbierto = false);
                          _abrirCajasFinalizadas();
                        },
                      ),
                      const SizedBox(height: 14),
                      _botonOpcionFlotante(
                        label: 'Gastos',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFFFFA726),
                        onTap: () {
                          setState(() => _menuFlotanteAbierto = false);
                          _abrirGastosCajaActual();
                        },
                      ),
                      const SizedBox(height: 14),
                      _botonOpcionFlotante(
                        label: 'Ventas',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF536DFE),
                        onTap: () {
                          setState(() => _menuFlotanteAbierto = false);
                          _abrirVentasCajaActual();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Material(
            color: const Color(0xFFc0733d),
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _menuFlotanteAbierto = !_menuFlotanteAbierto;
                });
              },
              child: SizedBox(
                width: 58,
                height: 58,
                child: AnimatedRotation(
                  turns: _menuFlotanteAbierto ? 0.125 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    _menuFlotanteAbierto ? Icons.logout : Icons.settings_suggest,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonOpcionFlotante({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 9,
      shadowColor: Colors.black.withOpacity(0.18),
      borderRadius: BorderRadius.circular(38),
      child: InkWell(
        borderRadius: BorderRadius.circular(38),
        onTap: onTap,
        child: Container(
          width: 230,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ),
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

        // 👉 BOTONES AGRUPADOS A LA DERECHA
        Row(
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc0733d),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.price_check),
              label: const Text('Cerrar Caja'),
              onPressed: () async {
                if (!CajaActiva().tieneCajaActiva) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Debes activar una caja antes de cerrarla'),
                    ),
                  );
                  return;
                }

                var dialogoCargandoAbierto = true;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final res = await CajasService().cerrarCaja(
                    idCaja: CajaActiva().idCaja!,
                    idEmpleado: UsuarioActivo().id!,
                  );

                  if (!mounted) return;
                  if (dialogoCargandoAbierto) {
                    Navigator.pop(context);
                    dialogoCargandoAbierto = false;
                  }

                  if (res['success'] == true) {
                    final reporte = res['reporte'] is Map
                        ? Map<String, dynamic>.from(res['reporte'])
                        : <String, dynamic>{};

                    String? rutaReporte;

                    try {
                      rutaReporte = await ReporteCajaPdfService()
                          .generarReporteCajaDiario(reporte);
                      await OpenFilex.open(rutaReporte);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Caja cerrada, pero no se pudo crear el PDF local: $e',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }

                    CajaActiva().limpiar();
                    await _cargarCajas();

                    if (!mounted) return;
                    setState(() {});

                    if (rutaReporte != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reporte guardado en: $rutaReporte'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['error'] ?? 'Error al cerrar caja')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    if (dialogoCargandoAbierto) {
                      Navigator.pop(context);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cerrar caja: $e')),
                    );
                  }
                }
              },
            ),

            const SizedBox(width: 15), // 👈 espacio entre botones

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFc0733d),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                _info('Bancolombia', c['bancolombia']),
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
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final creado = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const NuevoGastoDialog(),
                      );

                      if (creado == true) {
                        // Aquí actualizas lo que necesites
                        // por ejemplo:
                        setState(() {});
                      }
                    },
                    child: const Text('Nuevo gasto'),
                  ),
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
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

class _TablaCajaDialog extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String totalLabel;
  final String totalValor;
  final List<String> columnas;
  final List<List<String>> filas;

  const _TablaCajaDialog({
    required this.titulo,
    required this.subtitulo,
    required this.totalLabel,
    required this.totalValor,
    required this.columnas,
    required this.filas,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: 1100,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.point_of_sale,
                    color: Color(0xFFc0733d),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitulo,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFc0733d).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalLabel: $totalValor',
                      style: const TextStyle(
                        color: Color(0xFF7A4423),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Expanded(
                child: filas.isEmpty
                    ? const Center(
                  child: Text(
                    'No hay información para mostrar',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
                    : Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        columnSpacing: 28,
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        columns: columnas
                            .map(
                              (c) => DataColumn(
                            label: Text(c),
                          ),
                        )
                            .toList(),
                        rows: filas
                            .map(
                              (fila) => DataRow(
                            cells: fila
                                .map(
                                  (valor) => DataCell(
                                Text(
                                  valor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                                .toList(),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VentasCajaDialog extends StatefulWidget {
  final int idCaja;
  final Map<String, dynamic> caja;
  final List<Map<String, dynamic>> ventas;
  final String totalVentas;
  final CajasService service;
  final String Function(dynamic value) moneda;

  const _VentasCajaDialog({
    required this.idCaja,
    required this.caja,
    required this.ventas,
    required this.totalVentas,
    required this.service,
    required this.moneda,
  });

  @override
  State<_VentasCajaDialog> createState() => _VentasCajaDialogState();
}

class _VentasCajaDialogState extends State<_VentasCajaDialog> {
  Map<String, dynamic>? _ventaSeleccionada;
  List<Map<String, dynamic>> _detalles = [];
  bool _cargandoDetalle = false;
  final Map<int, Map<String, dynamic>> _cambiosDetalle = {};

  double _totalVentasLocal = 0;
  bool _huboCambiosCaja = false;


  @override
  void initState() {
    super.initState();
    _totalVentasLocal = widget.ventas.fold<double>(
      0,
          (sum, venta) {
        final total = double.tryParse(venta['total'].toString()) ?? 0;
        return sum + total;
      },
    );
    if (widget.ventas.isNotEmpty) {
      _seleccionarVenta(widget.ventas.first);
    }
  }

  Future<void> _anularVentaSeleccionada() async {
    final venta = _ventaSeleccionada;

    if (venta == null) return;

    final metodo = venta['metodo'].toString().toLowerCase().trim();

    if (metodo == 'fiado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las ventas fiadas no se pueden anular desde caja'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular venta'),
        content: Text(
          '¿Seguro que deseas anular la venta #${venta['id']}?\n\n'
              'El valor se restará del método de pago correspondiente en la caja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, anular'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final idVenta = int.tryParse(venta['id'].toString()) ?? 0;

    final res = await widget.service.anularVenta(
      idVenta: idVenta,
      motivo: 'Anulación desde módulo de caja',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta anulada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        final totalAnulado =
            double.tryParse(venta['total'].toString()) ?? 0;

        _totalVentasLocal -= totalAnulado;

        if (_totalVentasLocal < 0) {
          _totalVentasLocal = 0;
        }

        _huboCambiosCaja = true;

        widget.ventas.removeWhere(
              (v) => v['id'].toString() == idVenta.toString(),
        );

        _ventaSeleccionada =
        widget.ventas.isNotEmpty ? widget.ventas.first : null;

        _detalles = [];
        _cambiosDetalle.clear();
      });

      if (_ventaSeleccionada != null) {
        await _seleccionarVenta(_ventaSeleccionada!);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'No se pudo anular la venta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editarCantidadDetalle(Map<String, dynamic> detalle) async {
    final controller = TextEditingController(
      text: detalle['cantidad'].toString(),
    );

    final nuevaCantidad = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar cantidad'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));

              if (value == null || value <= 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevaCantidad == null) return;

    final idDetalle = int.tryParse(detalle['id'].toString()) ?? 0;
    final precioUnitario =
        double.tryParse(detalle['precio_unitario'].toString()) ?? 0;

    setState(() {
      detalle['cantidad'] = nuevaCantidad;
      detalle['precio_total'] = nuevaCantidad * precioUnitario;

      _cambiosDetalle[idDetalle] = {
        'id': idDetalle,
        'cantidad': nuevaCantidad,
        'precio_unitario': precioUnitario,
        'eliminar': false,
      };
    });
  }

  void _eliminarDetalle(Map<String, dynamic> detalle) {
    final idDetalle = int.tryParse(detalle['id'].toString()) ?? 0;

    setState(() {
      _detalles.removeWhere(
            (d) => d['id'].toString() == idDetalle.toString(),
      );

      _cambiosDetalle[idDetalle] = {
        'id': idDetalle,
        'cantidad': double.tryParse(detalle['cantidad'].toString()) ?? 0,
        'precio_unitario':
        double.tryParse(detalle['precio_unitario'].toString()) ?? 0,
        'eliminar': true,
      };
    });
  }

  Future<void> _guardarCambiosVenta() async {
    final venta = _ventaSeleccionada;

    if (venta == null) return;

    final metodo = venta['metodo'].toString().toLowerCase().trim();

    if (metodo == 'fiado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las ventas fiadas no se pueden editar desde caja'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La venta debe conservar al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final propinaController = TextEditingController(
      text: venta['propina'].toString(),
    );

    final nuevaPropina = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Actualizar propina'),
        content: TextField(
          controller: propinaController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Propina',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value =
                  double.tryParse(propinaController.text.replaceAll(',', '.')) ??
                      0;
              Navigator.pop(context, value);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (nuevaPropina == null) return;

    final idVenta = int.tryParse(venta['id'].toString()) ?? 0;

    final res = await widget.service.actualizarDetalleVenta(
      idVenta: idVenta,
      propina: nuevaPropina,
      detalles: _cambiosDetalle.values.toList(),
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        final diferencia =
            double.tryParse(res['diferencia_caja'].toString()) ?? 0;
        _totalVentasLocal += diferencia;
        if (_totalVentasLocal < 0) {
          _totalVentasLocal = 0;
        }
        _huboCambiosCaja = true;
        venta['subtotal'] = res['subtotal'];
        venta['propina'] = res['propina'];
        venta['total'] = res['total_nuevo'];
        _cambiosDetalle.clear();
      });

      await _seleccionarVenta(venta);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'No se pudo actualizar la venta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarVenta(Map<String, dynamic> venta) async {
    setState(() {
      _ventaSeleccionada = venta;
      _cargandoDetalle = true;
      _detalles = [];
      _cambiosDetalle.clear();
    });
    final idVenta = int.tryParse(venta['id'].toString()) ?? 0;
    final res = await widget.service.obtenerDetalleVenta(idVenta);
    if (!mounted) return;
    if (res['success'] == true && res['data'] is List) {
      setState(() {
        _detalles = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _cargandoDetalle = false;
      });
    } else {
      setState(() {
        _detalles = [];
        _cargandoDetalle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaApertura = widget.caja['fecha_apertura']?.toString() ?? '';
    final observacion = widget.caja['observaciones_apertura']?.toString() ?? '';
    final empleado = widget.caja['empleado']?.toString() ?? '';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
          minWidth: 900,
          minHeight: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context: context,
                fechaApertura: fechaApertura,
                observacion: observacion,
                empleado: empleado,
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildVentas(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _buildDetalleVenta(),
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

  Widget _buildHeader({
    required BuildContext context,
    required String fechaApertura,
    required String observacion,
    required String empleado,
  }) {
    return Row(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: Color(0xFFc0733d),
          size: 30,
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ventas de la caja #${widget.idCaja}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  Text(
                    'Empleado: $empleado',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'Fecha apertura: $fechaApertura',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    observacion.trim().isEmpty
                        ? 'Observación: Sin observación'
                        : 'Observación: $observacion',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _ventaSeleccionada == null
              ? null
              : _anularVentaSeleccionada,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Anular venta'),
        ),

        const SizedBox(width: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFc0733d).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total ventas: ${widget.moneda(_totalVentasLocal)}',
            style: const TextStyle(
              color: Color(0xFF7A4423),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 10),

        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.pop(context, _huboCambiosCaja),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildVentas() {
    if (widget.ventas.isEmpty) {
      return const Center(
        child: Text(
          'No hay ventas registradas en esta caja',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: const Text(
              'Ventas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: widget.ventas.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (_, index) {
                final venta = widget.ventas[index];
                final selected =
                    _ventaSeleccionada?['id'].toString() == venta['id'].toString();

                return InkWell(
                  onTap: () => _seleccionarVenta(venta),
                  child: Container(
                    color: selected
                        ? const Color(0xFFc0733d).withOpacity(0.10)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: selected
                              ? const Color(0xFFc0733d)
                              : Colors.grey.shade200,
                          child: Text(
                            venta['id'].toString(),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                venta['cliente'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${venta['fecha']}  •  ${venta['metodo']}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.moneda(venta['total']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if ((double.tryParse(venta['propina'].toString()) ?? 0) > 0)
                              Text(
                                'Propina: ${widget.moneda(venta['propina'])}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleVenta() {
    final venta = _ventaSeleccionada;

    return Container(

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Text(
              venta == null
                  ? 'Detalle de venta'
                  : 'Detalle venta #${venta['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          if (venta != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _detalleResumen(
                      'Subtotal',
                      widget.moneda(venta['subtotal']),
                    ),
                  ),
                  Expanded(
                    child: _detalleResumen(
                      'Propina',
                      widget.moneda(venta['propina']),
                    ),
                  ),
                  Expanded(
                    child: _detalleResumen(
                      'Total',
                      widget.moneda(venta['total']),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),
          const SizedBox(height: 15),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFc0733d),
              foregroundColor: Colors.white,
            ),
            onPressed: venta == null
                ? null
                : _guardarCambiosVenta,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Editar propina / guardar cambios'),
          ),

          Expanded(

            child: _cargandoDetalle
                ? const Center(child: CircularProgressIndicator())
                : _detalles.isEmpty
                ? const Center(
              child: Text(
                'Selecciona una venta o no hay productos registrados',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )

                : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _detalles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final d = _detalles[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                        const Color(0xFF536DFE).withOpacity(0.12),
                        child: Text(
                          '${d['cantidad']}',
                          style: const TextStyle(
                            color: Color(0xFF536DFE),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['nombre'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Unitario: ${widget.moneda(d['precio_unitario'])}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        widget.moneda(d['precio_total']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 12),

                      IconButton(
                        tooltip: 'Editar cantidad',
                        onPressed: () => _editarCantidadDetalle(d),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),

                      IconButton(
                        tooltip: 'Eliminar producto',
                        onPressed: () => _eliminarDetalle(d),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleResumen(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GastosCajaDialog extends StatefulWidget {
  final int idCaja;
  final Map<String, dynamic> caja;
  final List<Map<String, dynamic>> gastos;
  final String totalGastos;
  final CajasService service;
  final String Function(dynamic value) moneda;

  const _GastosCajaDialog({
    required this.idCaja,
    required this.caja,
    required this.gastos,
    required this.totalGastos,
    required this.service,
    required this.moneda,
  });

  @override
  State<_GastosCajaDialog> createState() => _GastosCajaDialogState();
}

class _GastosCajaDialogState extends State<_GastosCajaDialog> {
  Map<String, dynamic>? _gastoSeleccionado;
  double _totalGastosLocal = 0;
  bool _huboCambiosCaja = false;

  @override
  void initState() {
    super.initState();

    _totalGastosLocal = widget.gastos.fold<double>(
      0,
          (sum, gasto) {
        final monto = double.tryParse(gasto['monto'].toString()) ?? 0;
        return sum + monto;
      },
    );

    if (widget.gastos.isNotEmpty) {
      _gastoSeleccionado = widget.gastos.first;
    }
  }

  void _seleccionarGasto(Map<String, dynamic> gasto) {
    setState(() {
      _gastoSeleccionado = gasto;
    });
  }

  Future<void> _anularGastoSeleccionado() async {
    final gasto = _gastoSeleccionado;

    if (gasto == null) return;

    final estadoCaja = int.tryParse(widget.caja['estado']?.toString() ?? '1') ?? 1;

    if (estadoCaja != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede anular un gasto de una caja cerrada o cancelada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anular gasto'),
        content: Text(
          '¿Seguro que deseas anular el gasto #${gasto['id']}?\n\n'
              'El valor se devolverá al método de pago correspondiente en la caja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, anular'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final idGasto = int.tryParse(gasto['id'].toString()) ?? 0;

    final res = await widget.service.anularGasto(
      idGasto: idGasto,
      motivo: 'Anulación desde módulo de caja',
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto anulado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        final montoAnulado = double.tryParse(gasto['monto'].toString()) ?? 0;
        _totalGastosLocal -= montoAnulado;

        if (_totalGastosLocal < 0) {
          _totalGastosLocal = 0;
        }

        _huboCambiosCaja = true;

        widget.gastos.removeWhere(
              (g) => g['id'].toString() == idGasto.toString(),
        );

        _gastoSeleccionado = widget.gastos.isNotEmpty ? widget.gastos.first : null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'No se pudo anular el gasto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaApertura = widget.caja['fecha_apertura']?.toString() ?? '';
    final observacion = widget.caja['observaciones_apertura']?.toString() ?? '';
    final empleado = widget.caja['empleado']?.toString() ?? '';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
          minWidth: 900,
          minHeight: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context: context,
                fechaApertura: fechaApertura,
                observacion: observacion,
                empleado: empleado,
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildListadoGastos(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _buildDetalleGasto(),
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

  Widget _buildHeader({
    required BuildContext context,
    required String fechaApertura,
    required String observacion,
    required String empleado,
  }) {
    return Row(
      children: [
        const Icon(
          Icons.payments_outlined,
          color: Color(0xFFc0733d),
          size: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gastos de la caja #${widget.idCaja}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  Text(
                    'Empleado: $empleado',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    'Fecha apertura: $fechaApertura',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    observacion.trim().isEmpty
                        ? 'Observación: Sin observación'
                        : 'Observación: $observacion',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _gastoSeleccionado == null ? null : _anularGastoSeleccionado,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Anular gasto'),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFc0733d).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total gastos: ${widget.moneda(_totalGastosLocal)}',
            style: const TextStyle(
              color: Color(0xFF7A4423),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: () => Navigator.pop(context, _huboCambiosCaja),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildListadoGastos() {
    if (widget.gastos.isEmpty) {
      return const Center(
        child: Text(
          'No hay gastos registrados en esta caja',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: const Text(
              'Gastos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: widget.gastos.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (_, index) {
                final gasto = widget.gastos[index];
                final selected =
                    _gastoSeleccionado?['id'].toString() == gasto['id'].toString();

                return InkWell(
                  onTap: () => _seleccionarGasto(gasto),
                  child: Container(
                    color: selected
                        ? const Color(0xFFc0733d).withOpacity(0.10)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: selected
                              ? const Color(0xFFc0733d)
                              : Colors.grey.shade200,
                          child: Text(
                            gasto['id'].toString(),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gasto['descripcion'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${gasto['fecha_gasto']}  •  ${gasto['metodo']}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.moneda(gasto['monto']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleGasto() {
    final gasto = _gastoSeleccionado;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Text(
              gasto == null ? 'Detalle de gasto' : 'Detalle gasto #${gasto['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (gasto != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: _detalleResumen(
                      'Método',
                      gasto['metodo'].toString(),
                    ),
                  ),
                  Expanded(
                    child: _detalleResumen(
                      'Monto',
                      widget.moneda(gasto['monto']),
                    ),
                  ),
                  Expanded(
                    child: _detalleResumen(
                      'Fecha',
                      gasto['fecha_gasto'].toString(),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: gasto == null
                ? const Center(
              child: Text(
                'Selecciona un gasto para ver su información',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      gasto['descripcion'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _detalleLinea('Empleado', gasto['empleado']),
                  _detalleLinea('Sale de caja diaria',
                      (gasto['esCaja'].toString() == '1') ? 'Sí' : 'No'),
                  _detalleLinea('Estado', 'Activo'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _anularGastoSeleccionado,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Anular gasto seleccionado'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleResumen(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _detalleLinea(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}