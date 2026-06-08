import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panaderia_nicol_pos/Services/clientes_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_cliente_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClientesService _service = ClientesService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _clientes = [];

  String _buscar = '';
  String _estado = '1';
  String _orden = 'id';
  String _direccion = 'DESC';

  int _paginaActual = 1;
  int _totalPaginas = 1;
  int _totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final res = await _service.obtenerClientes(
      buscar: _buscar,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _clientes = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
    });
  }

  void _confirmarReactivar(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar cliente'),
        content: Text(
          '¿Deseas reactivar al cliente "${cliente['nombre']}"?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _reactivarCliente(cliente['id']);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivarCliente(int id) async {
    final ok = await _service.cambiarEstadoCliente(id, 1);
    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Cliente reactivado')),
      //);
      _cargarClientes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reactivar cliente')),
      );
    }
  }

  void _confirmarEliminar(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar cliente'),
        content: Text(
          '¿Deseas desactivar al cliente "${cliente['nombre']}"?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _desactivarCliente(cliente['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarCliente(int id) async {
    final ok = await _service.cambiarEstadoCliente(id, 0);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Cliente desactivado')),
      //);
      _cargarClientes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar cliente')),
      );
    }
  }

  void _mostrarDialogCrearUsuario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CrearClienteDialog(),
    ).then((creado) {
      if (creado == true) {
        _cargarClientes(); // refresca tabla
      }
    });
  }

  void _abrirDialogoAbono(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (_) => _DialogoAbono(cliente: cliente),
    ).then((ok) {
      if (ok == true) {
        _cargarClientes();
      }
    });
  }

  void _abrirDialogoReporte(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (_) => _DialogoReporte(cliente: cliente),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildTableHeader(),
          const Divider(height: 1),
          Expanded(child: _buildClientes()),
          const Divider(height: 1),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  // ───────────────── TOP BAR ─────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _buscarCtrl,
            onChanged: (v) {
              _buscar = v;
              _paginaActual = 1;
              _cargarClientes();
            },
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        DropdownButton<String>(
          value: _estado,
          items: const [
            DropdownMenuItem(value: '1', child: Text('Activos')),
            DropdownMenuItem(value: '0', child: Text('Eliminados')),
          ],
          onChanged: (v) {
            setState(() {
              _estado = v!;
              _paginaActual = 1;
            });
            _cargarClientes();
          },
        ),

        const SizedBox(width: 12),

        IconButton(
          icon: Icon(
            _direccion == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
            color: _direccion == 'ASC' ? Colors.red : Colors.green,
          ),
          onPressed: () {
            setState(() {
              _direccion = _direccion == 'ASC' ? 'DESC' : 'ASC';
            });
            _cargarClientes();
          },
        ),

        /// ➕ NUEVO
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo cliente'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => const CrearClienteDialog(),
            );

            if (creado == true) {
              _cargarClientes();
            }
          },
        ),
      ],
    );
  }

  // ───────────────── TABLE HEADER ─────────────────
  Widget _buildTableHeader() {
    return Row(
      children: const [
        _HeaderCell('Nombre'),
        _HeaderCell('Apellido'),
        _HeaderCell('Identificación'),
        _HeaderCell('Teléfono'),
        _HeaderCell('Correo'),
        _HeaderCell('Deuda'),
        _HeaderCell('Estado'),
        SizedBox(width: 175),
      ],
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildClientes() {
    if (_clientes.isEmpty) {
      return const Center(child: Text('No hay clientes'));
    }

    return ListView.separated(
      itemCount: _clientes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = _clientes[i];
        final activo = c['estado'] == 1;

        String _val(String? v) =>
            (v == null || v.trim().isEmpty) ? 'No tiene' : v;

        return Row(
          children: [
            _Cell(c['nombre']),
            _Cell(c['apellido']),
            _Cell(_val(c['identificacion'])),
            _Cell(_val(c['telefono'])),
            _Cell(_val(c['correo'])),
            _Cell(CurrencyUtils.formatCop(c['deuda'] ?? 0)),
            _Cell(
              activo ? 'Activo' : 'Eliminado',
              color: activo ? Colors.green : Colors.red,
            ),
            SizedBox(
              width: 170,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Reporte deuda',
                    icon: const Icon(Icons.request_quote, size: 18, color: Colors.blue),
                    onPressed: () => _abrirDialogoReporte(c),
                  ),
                  IconButton(
                    tooltip: 'Registrar abono',
                    icon: const Icon(Icons.paid, size: 18, color: Colors.green),
                    onPressed: () => _abrirDialogoAbono(c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                    onPressed: () async {
                      final actualizado = await showDialog(
                        context: context,
                        builder: (_) => CrearClienteDialog(cliente: c),
                      );

                      if (actualizado == true) {
                        _cargarClientes();
                      }
                    },
                  ),
                  IconButton(
                    tooltip: activo
                        ? 'Desactivar usuario'
                        : 'Reactivar usuario',
                    icon: Icon(
                      activo ? Icons.delete : Icons.restore,
                      size: 18,
                      color: activo ? Colors.red : Colors.green,
                    ),
                    onPressed: () => activo
                        ? _confirmarEliminar(c)
                        : _confirmarReactivar(c),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────── PAGINATION ─────────────────
  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando ${_clientes.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarClientes();
                }
                    : null,
              ),

              Text(
                'Página $_paginaActual de $_totalPaginas',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _paginaActual < _totalPaginas
                    ? () {
                  setState(() => _paginaActual++);
                  _cargarClientes();
                }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────── CELLS ─────────────────
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final Color? color;
  const _Cell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}

class _DialogoAbono extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const _DialogoAbono({required this.cliente});

  @override
  State<_DialogoAbono> createState() => _DialogoAbonoState();
}

class _DialogoAbonoState extends State<_DialogoAbono> {

  final TextEditingController _montoCtrl = TextEditingController();
  String metodo = 'efectivo';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Abono - ${widget.cliente['nombre']}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// MONTO
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [ColombianCurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Monto',
              hintText: '\$ 0',
            ),
          ),

          const SizedBox(height: 12),

          /// MÉTODO
          DropdownButtonFormField<String>(
            value: metodo,
            items: const [
              DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
              DropdownMenuItem(value: 'bancolombia', child: Text('Bancolombia')),
              DropdownMenuItem(value: 'nequi', child: Text('Nequi')),
              DropdownMenuItem(value: 'daviplata', child: Text('Daviplata')),
            ],
            onChanged: (v) {
              setState(() {
                metodo = v!;
              });
            },
            decoration: const InputDecoration(labelText: 'Método de pago'),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),

        ElevatedButton(
          onPressed: () async {
            final monto = CurrencyUtils.parse(_montoCtrl.text);

            if (monto <= 0) return;

            final ok = await ClientesService().registrarAbono(
              idCliente: widget.cliente['id'],
              monto: monto,
              metodo: metodo,
            );

            if (ok) {
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error al registrar abono")),
              );
            }
          },
          child: const Text("Registrar"),
        )
      ],
    );
  }
}

class _DialogoReporte extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const _DialogoReporte({required this.cliente});

  @override
  State<_DialogoReporte> createState() => _DialogoReporteState();
}

class _DialogoReporteState extends State<_DialogoReporte> {
  DateTime? desde;
  DateTime? hasta;
  String? rangoSeleccionado;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _cargarUltimoRango();
  }

  /// 🧠 CARGAR ÚLTIMO RANGO
  Future<void> _cargarUltimoRango() async {
    final prefs = await SharedPreferences.getInstance();

    final d = prefs.getString('reporte_desde');
    final h = prefs.getString('reporte_hasta');

    if (d != null && h != null) {
      setState(() {
        desde = DateTime.parse(d);
        hasta = DateTime.parse(h);
      });
    }
  }

  /// 💾 GUARDAR RANGO
  Future<void> _guardarRango() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('reporte_desde', desde!.toIso8601String());
    await prefs.setString('reporte_hasta', hasta!.toIso8601String());
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar';
    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year}";
  }

  Future<void> _pickFecha(bool inicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (inicio) {
          desde = fecha;
        } else {
          hasta = fecha;
        }
      });
    }
  }

  /// ⚡ RANGOS RÁPIDOS
  void _setRangoRapido(String tipo) {
    final now = DateTime.now();

    setState(() {
      rangoSeleccionado = tipo; // 👈 🔥 MARCAR SELECCIÓN

      if (tipo == 'hoy') {
        desde = DateTime(now.year, now.month, now.day);
        hasta = now;
      } else if (tipo == 'semana') {
        final inicio = now.subtract(Duration(days: now.weekday - 1));
        desde = DateTime(inicio.year, inicio.month, inicio.day);
        hasta = now;
      } else if (tipo == 'mes') {
        desde = DateTime(now.year, now.month, 1);
        hasta = now;
      }
    });
  }

  Future<void> _generar() async {
    if (desde == null || hasta == null) return;

    if (hasta!.isBefore(desde!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rango de fechas inválido")),
      );
      return;
    }

    setState(() => loading = true);

    await _guardarRango();

    final ok = await ClientesService().descargarReporteDeuda(
      idCliente: widget.cliente['id'],
      desde: desde!,
      hasta: hasta!,
    );

    setState(() => loading = false);

    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final puedeGenerar = desde != null && hasta != null;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction(onInvoke: (_) {
            if (puedeGenerar && !loading) _generar();
            return null;
          }),
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 360,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// HEADER
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Reporte",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.cliente['nombre'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// RANGOS RÁPIDOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _chip("Hoy", 'hoy'),
                      _chip("Semana", 'semana'),
                      _chip("Mes", 'mes'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// FECHAS
                  Row(
                    children: [
                      Expanded(
                        child: _fechaField(
                          "Inicio",
                          _formatFecha(desde),
                              () => _pickFecha(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _fechaField(
                          "Fin",
                          _formatFecha(hasta),
                              () => _pickFecha(false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// BOTONES
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFc0733d),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (!puedeGenerar || loading)
                              ? null
                              : _generar,
                          child: loading
                              ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text("Generar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// INPUT BONITO COMPACTO
  Widget _fechaField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  /// CHIPS RÁPIDOS
  Widget _chip(String text, String tipo) {
    final isSelected = rangoSeleccionado == tipo;

    return GestureDetector(
      onTap: () => _setRangoRapido(tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? const Color(0xFFC0733D) // 🔥 color seleccionado
              : Colors.grey.shade200,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}