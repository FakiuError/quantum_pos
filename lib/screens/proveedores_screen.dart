import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panaderia_nicol_pos/Services/proveedores_service.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_proveedor_dialog.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ProveedoresService _service = ProveedoresService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _proveedores = [];

  String _buscar = '';
  String _estado = '1'; // activos por defecto
  String _orden = 'id';
  String _direccion = 'DESC';

  int _paginaActual = 1;
  int _totalPaginas = 1;
  int _totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarProveedores() async {
    final res = await _service.obtenerProveedores(
      buscar: _buscar,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    if (!mounted) return;

    setState(() {
      _proveedores = res['data'] is List
          ? List<Map<String, dynamic>>.from(res['data'])
          : <Map<String, dynamic>>[];
      _totalRegistros = int.tryParse((res['total'] ?? 0).toString()) ?? 0;
      _totalPaginas = int.tryParse((res['totalPages'] ?? 1).toString()) ?? 1;
    });
  }

  void _confirmarReactivar(Map<String, dynamic> proveedor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar proveedor'),
        content: Text(
          '¿Deseas reactivar al proveedor "${proveedor['razon']}"?',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _reactivarProveedor(proveedor['id']);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivarProveedor(int id) async {
    final ok = await _service.cambiarEstadoProveedor(id, 1);
    if (!mounted) return;

    if (ok) {
      _cargarProveedores();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reactivar proveedor')),
      );
    }
  }

  void _confirmarEliminar(Map<String, dynamic> proveedor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar proveedor'),
        content: Text(
          '¿Deseas desactivar al proveedor "${proveedor['razon']}"?',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _desactivarProveedor(proveedor['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarProveedor(int id) async {
    final ok = await _service.cambiarEstadoProveedor(id, 0);

    if (!mounted) return;

    if (ok) {
      _cargarProveedores();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar proveedor')),
      );
    }
  }

  Future<void> _abrirDialogEntradaProveedor(Map<String, dynamic> proveedor) async {
    if (!CajaActiva().tieneCajaActiva || CajaActiva().idCaja == null) {
      _mostrarMensaje(
        'Debes activar una caja diaria antes de registrar una entrada a proveedor',
        color: Colors.orange.shade800,
      );
      return;
    }

    if (UsuarioActivo().id == null) {
      _mostrarMensaje('No se encontró el usuario activo');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EntradaProveedorDialog(
        proveedor: proveedor,
        service: _service,
      ),
    );

    if (ok == true) {
      await _cargarProveedores();
    }
  }

  void _mostrarMensaje(String mensaje, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
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
          Expanded(child: _buildProveedores()),
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
              _cargarProveedores();
            },
            decoration: InputDecoration(
              hintText: 'Buscar proveedor...',
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
            _cargarProveedores();
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
            _cargarProveedores();
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo proveedor'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => const CrearProveedorDialog(),
            );

            if (creado == true) {
              _cargarProveedores();
            }
          },
        ),
      ],
    );
  }

  // ───────────────── TABLE HEADER ─────────────────
  Widget _buildTableHeader() {
    return const Row(
      children: [
        _HeaderCell('Nombre'),
        _HeaderCell('Apellido'),
        _HeaderCell('Razón'),
        _HeaderCell('Teléfono'),
        _HeaderCell('Correo'),
        _HeaderCell('Dirección'),
        _HeaderCell('Estado'),
        SizedBox(width: 132),
      ],
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildProveedores() {
    if (_proveedores.isEmpty) {
      return const Center(child: Text('No hay proveedores'));
    }

    return ListView.separated(
      itemCount: _proveedores.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = _proveedores[i];
        final activo = p['estado'].toString() == '1';

        String val(dynamic v) {
          final text = v?.toString() ?? '';
          return text.trim().isEmpty ? 'No tiene' : text;
        }

        return Row(
          children: [
            _Cell(val(p['nombre'])),
            _Cell(val(p['apellido'])),
            _Cell(val(p['razon'])),
            _Cell(val(p['telefono'])),
            _Cell(val(p['correo'])),
            _Cell(val(p['direccion'])),
            _Cell(
              activo ? 'Activo' : 'Eliminado',
              color: activo ? Colors.green : Colors.red,
            ),
            SizedBox(
              width: 132,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (activo)
                    IconButton(
                      tooltip: 'Crear entrada a proveedor',
                      icon: const Icon(
                        Icons.inventory_2_outlined,
                        size: 19,
                        color: Color(0xFF536DFE),
                      ),
                      onPressed: () => _abrirDialogEntradaProveedor(p),
                    ),
                  IconButton(
                    tooltip: 'Editar proveedor',
                    icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                    onPressed: () async {
                      final actualizado = await showDialog(
                        context: context,
                        builder: (_) => CrearProveedorDialog(proveedor: p),
                      );

                      if (actualizado == true) {
                        _cargarProveedores();
                      }
                    },
                  ),
                  IconButton(
                    tooltip: activo
                        ? 'Desactivar proveedor'
                        : 'Reactivar proveedor',
                    icon: Icon(
                      activo ? Icons.delete : Icons.restore,
                      size: 18,
                      color: activo ? Colors.red : Colors.green,
                    ),
                    onPressed: () => activo
                        ? _confirmarEliminar(p)
                        : _confirmarReactivar(p),
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
            'Mostrando ${_proveedores.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarProveedores();
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
                  _cargarProveedores();
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

// ───────────────── DIALOG ENTRADA PROVEEDOR ─────────────────
class EntradaProveedorDialog extends StatefulWidget {
  final Map<String, dynamic> proveedor;
  final ProveedoresService service;

  const EntradaProveedorDialog({
    super.key,
    required this.proveedor,
    required this.service,
  });

  @override
  State<EntradaProveedorDialog> createState() => _EntradaProveedorDialogState();
}

class _EntradaProveedorDialogState extends State<EntradaProveedorDialog> {
  static const String _baseImagenUrl = 'http://200.7.100.146';

  final TextEditingController _buscarCtrl = TextEditingController();
  final TextEditingController _totalEntradaCtrl = TextEditingController(
    text: CurrencyUtils.formatControllerValue(0),
  );
  final List<Map<String, dynamic>> _productos = [];
  final List<_EntradaItem> _items = [];

  Timer? _debounce;
  bool _cargandoProductos = true;
  bool _guardando = false;
  bool _esCaja = true;
  bool _totalEditadoManual = false;
  bool _sincronizandoTotalCtrl = false;
  String _metodo = 'efectivo';

  double get _totalCalculadoItems => _items.fold<double>(
    0,
        (sum, item) => sum + item.total,
  );

  double get _totalEntrada {
    if (_totalEditadoManual) {
      return CurrencyUtils.parse(_totalEntradaCtrl.text);
    }

    return _totalCalculadoItems;
  }

  double get _diferenciaTotalManual => _totalEntrada - _totalCalculadoItems;

  String get _nombreProveedor =>
      (widget.proveedor['razon'] ?? 'Proveedor').toString();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscarCtrl.dispose();
    _totalEntradaCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargandoProductos = true);

    final idProveedor = int.tryParse(widget.proveedor['id'].toString()) ?? 0;
    final res = await widget.service.obtenerProductosProveedor(
      idProveedor: idProveedor,
      buscar: _buscarCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _productos
        ..clear()
        ..addAll(
          res['success'] == true && res['data'] is List
              ? List<Map<String, dynamic>>.from(res['data'])
              : <Map<String, dynamic>>[],
        );
      _cargandoProductos = false;
    });

    if (res['success'] != true && mounted) {
      _mostrarMensaje(
        res['error'] ?? 'No se pudieron cargar los productos del proveedor',
      );
    }
  }

  void _buscarProductos(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _cargarProductos);
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    final id = int.tryParse(producto['id'].toString()) ?? 0;
    if (id <= 0) return;

    final index = _items.indexWhere((item) => item.idProducto == id);

    setState(() {
      if (index == -1) {
        _items.add(_EntradaItem.fromProducto(producto));
      } else {
        final item = _items[index];
        item.cantidad += 1;
        item.cantidadCtrl.text = _formatCantidadInput(item.cantidad);
      }
      _sincronizarTotalDesdeItems();
    });
  }

  void _eliminarItem(_EntradaItem item) {
    setState(() {
      item.dispose();
      _items.remove(item);
      _sincronizarTotalDesdeItems();
    });
  }

  void _sincronizarTotalDesdeItems({bool forzar = false}) {
    if (_totalEditadoManual && !forzar) return;

    _sincronizandoTotalCtrl = true;
    _totalEntradaCtrl.text = CurrencyUtils.formatControllerValue(_totalCalculadoItems);
    _sincronizandoTotalCtrl = false;
  }

  void _marcarTotalManual() {
    if (_sincronizandoTotalCtrl) return;
    if (_totalEditadoManual) {
      setState(() {});
      return;
    }
    setState(() => _totalEditadoManual = true);
  }

  void _usarTotalCalculado() {
    setState(() {
      _totalEditadoManual = false;
      _sincronizarTotalDesdeItems(forzar: true);
    });
  }

  Future<void> _guardarEntrada() async {
    if (_guardando) return;

    if (_items.isEmpty) {
      _mostrarMensaje('Agrega al menos un producto a la entrada');
      return;
    }

    final idCaja = CajaActiva().idCaja;
    final idEmpleado = UsuarioActivo().id;

    if (idCaja == null || idEmpleado == null) {
      _mostrarMensaje('Debes tener una caja activa y un usuario activo');
      return;
    }

    final itemsApi = <Map<String, dynamic>>[];

    for (final item in _items) {
      item.sincronizarDesdeControladores();

      if (item.cantidad <= 0) {
        _mostrarMensaje('La cantidad de ${item.nombre} debe ser mayor a cero');
        return;
      }

      if (item.precioUnitario < 0) {
        _mostrarMensaje('El precio de ${item.nombre} no puede ser negativo');
        return;
      }

      itemsApi.add({
        'id_producto': item.idProducto,
        'nombre': item.nombre,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      });
    }

    final totalEntrada = _totalEntrada;

    if (totalEntrada <= 0) {
      _mostrarMensaje('El total de la entrada debe ser mayor a cero');
      return;
    }

    setState(() => _guardando = true);

    try {
      final idProveedor = int.tryParse(widget.proveedor['id'].toString()) ?? 0;
      final res = await widget.service.registrarEntradaProveedor(
        idProveedor: idProveedor,
        proveedor: _nombreProveedor,
        idCaja: idCaja,
        idEmpleado: idEmpleado,
        esCaja: _esCaja,
        metodo: _metodo,
        totalEntrada: totalEntrada,
        items: itemsApi,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final total = CurrencyUtils.parse(res['total'] ?? _totalEntrada);
        if (_esCaja) {
          _actualizarCajaActivaLocal(total);
        }

        _mostrarMensaje('Entrada registrada correctamente', ok: true);
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(res['error'] ?? 'No se pudo registrar la entrada');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error registrando entrada: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _actualizarCajaActivaLocal(double total) {
    final caja = CajaActiva();

    switch (_metodo) {
      case 'efectivo':
        caja.actualizarSaldos(efectivo: caja.efectivo - total);
        break;
      case 'bancolombia':
        caja.actualizarSaldos(bancolombia: caja.bancolombia - total);
        break;
      case 'nequi':
        caja.actualizarSaldos(nequi: caja.nequi - total);
        break;
      case 'daviplata':
        caja.actualizarSaldos(daviplata: caja.daviplata - total);
        break;
    }
  }

  void _mostrarMensaje(String mensaje, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.94,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
          minWidth: 1080,
          minHeight: 640,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 7, child: _buildProductosPanel()),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: _buildResumenPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF536DFE).withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF536DFE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrada a proveedor: $_nombreProveedor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Selecciona productos del proveedor, ajusta cantidades/precios y registra el gasto asociado.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cerrar',
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProductosPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: _buscarCtrl,
              onChanged: _buscarProductos,
              decoration: InputDecoration(
                hintText: 'Buscar productos de $_nombreProveedor...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _cargandoProductos
                ? const Center(child: CircularProgressIndicator())
                : _productos.isEmpty
                ? _emptyBox('Este proveedor no tiene productos activos asociados')
                : GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: _productos.length,
              itemBuilder: (_, index) =>
                  _buildProductoCard(_productos[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto) {
    final seleccionado = _items.any(
          (item) => item.idProducto.toString() == producto['id'].toString(),
    );
    final imageUrl = _urlImagen(producto['url_imagen']);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _agregarProducto(producto),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF536DFE)
                : Colors.grey.shade200,
            width: seleccionado ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isEmpty
                    ? Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey,
                    size: 40,
                  ),
                )
                    : CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto['nombre'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Compra ${CurrencyUtils.formatCop(producto['precio_compra'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${_formatCantidad(producto['stock'])}',
                    style: const TextStyle(color: Colors.black54, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: Color(0xFFc0733d)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Resumen de entrada',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFc0733d).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_items.length} productos',
                    style: const TextStyle(
                      color: Color(0xFF7A4423),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? _emptyBox('Agrega productos desde el panel izquierdo')
                : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _buildItemEntrada(_items[index]),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _esCaja,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFFc0733d),
                  title: const Text(
                    'El gasto sale de caja diaria',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _esCaja
                        ? 'Se descontará del saldo del método elegido.'
                        : 'Quedará asociado a la caja, pero no descontará saldo físico.',
                  ),
                  onChanged: _guardando
                      ? null
                      : (value) => setState(() => _esCaja = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _metodo,
                  decoration: InputDecoration(
                    labelText: 'Método del gasto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(
                      value: 'bancolombia',
                      child: Text('Bancolombia'),
                    ),
                    DropdownMenuItem(value: 'nequi', child: Text('Nequi')),
                    DropdownMenuItem(value: 'daviplata', child: Text('Daviplata')),
                  ],
                  onChanged:
                  _guardando ? null : (value) => setState(() => _metodo = value!),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFc0733d).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFc0733d).withOpacity(0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total entrada',
                              style: TextStyle(
                                color: Color(0xFF7A4423),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_totalEditadoManual)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF7A4423),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onPressed: _guardando ? null : _usarTotalCalculado,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Usar calculado'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _totalEntradaCtrl,
                        enabled: !_guardando,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [ColombianCurrencyInputFormatter()],
                        style: const TextStyle(
                          color: Color(0xFF7A4423),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          hintText: '\$ 0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => _marcarTotalManual(),
                      ),
                      if (_totalEditadoManual) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Calculado por productos: ${CurrencyUtils.formatCop(_totalCalculadoItems)}'
                              '  •  Diferencia: ${CurrencyUtils.formatCop(_diferenciaTotalManual)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                        _guardando ? null : () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFc0733d),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _guardando ? null : _guardarEntrada,
                        icon: _guardando
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.save_outlined),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar entrada'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEntrada(_EntradaItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar producto',
                visualDensity: VisualDensity.compact,
                onPressed: () => _eliminarItem(item),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.cantidadCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    item.sincronizarDesdeControladores();
                    _sincronizarTotalDesdeItems();
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: item.precioCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ColombianCurrencyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Precio compra',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {
                    item.sincronizarDesdeControladores();
                    _sincronizarTotalDesdeItems();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Stock actual: ${_formatCantidad(item.stockActual)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const Spacer(),
              Text(
                CurrencyUtils.formatCop(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4423),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  String _urlImagen(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$_baseImagenUrl$raw';
  }

  static String _formatCantidad(dynamic value) {
    final n = _parseCantidad(value);
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatCantidadInput(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  static double _parseCantidad(dynamic value) {
    if (value is num) return value.toDouble();
    final text = value
        ?.toString()
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.\-]'), '') ??
        '';
    return double.tryParse(text) ?? 0;
  }
}

class _EntradaItem {
  _EntradaItem({
    required this.idProducto,
    required this.nombre,
    required this.stockActual,
    required this.cantidad,
    required this.precioUnitario,
  })  : cantidadCtrl = TextEditingController(
    text: _EntradaProveedorDialogState._formatCantidadInput(cantidad),
  ),
        precioCtrl = TextEditingController(
          text: CurrencyUtils.formatControllerValue(precioUnitario),
        );

  factory _EntradaItem.fromProducto(Map<String, dynamic> producto) {
    return _EntradaItem(
      idProducto: int.tryParse(producto['id'].toString()) ?? 0,
      nombre: producto['nombre'].toString(),
      stockActual: _EntradaProveedorDialogState._parseCantidad(producto['stock']),
      cantidad: 1,
      precioUnitario: CurrencyUtils.parse(producto['precio_compra']),
    );
  }

  final int idProducto;
  final String nombre;
  final double stockActual;
  double cantidad;
  double precioUnitario;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  double get total => cantidad * precioUnitario;

  void sincronizarDesdeControladores() {
    cantidad = _EntradaProveedorDialogState._parseCantidad(cantidadCtrl.text);
    precioUnitario = CurrencyUtils.parse(precioCtrl.text);
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
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