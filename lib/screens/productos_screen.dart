import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panaderia_nicol_pos/Services/productos_service.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_producto_dialog.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductosService _service = ProductosService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _categorias = [];

  String _buscar = '';
  String _estado = '1';
  String _proveedorId = '';
  String _categoriaId = '';
  String _estadoInventario = '';
  String _orden = 'id';
  String _direccion = 'DESC';

  int _paginaActual = 1;
  int _totalPaginas = 1;
  int _totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _cargarFiltros();
    _cargarProductos();
  }

  Future<void> _cargarFiltros() async {
    _proveedores = await _service.obtenerProveedores();
    _categorias = await _service.obtenerCategorias();
    setState(() {});
  }

  Future<void> _cargarProductos() async {
    final res = await _service.obtenerProductos(
      buscar: _buscar,
      estado: _estado,
      proveedorId: _proveedorId,
      categoriaId: _categoriaId,
      estadoInventario: _estadoInventario,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _productos = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
    });
  }

  void _confirmarReactivar(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar producto'),
        content: Text(
          'En el momento no es posible activar el producto "${producto['nombre']}"',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Deseas eliminar el producto "${producto['nombre']}"?',
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
              _desactivarProducto(producto['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarProducto(int id) async {
    final ok = await _service.cambiarEstadoProducto(id, 0);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Proveedor desactivado')),
      //);
      _cargarProductos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar producto')),
      );
    }
  }

  Future<void> _abrirDialogBajaProducto(Map<String, dynamic> producto) async {
    if (producto['estado'].toString() != '1') {
      _mostrarMensaje('No se puede registrar baja sobre un producto inactivo');
      return;
    }

    if (UsuarioActivo().id == null) {
      _mostrarMensaje('No se encontró el usuario activo');
      return;
    }

    if (!CajaActiva().tieneCajaActiva || CajaActiva().idCaja == null) {
      _mostrarMensaje('Debes activar una caja antes de registrar una baja');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BajaProductoDialog(
        producto: producto,
        service: _service,
      ),
    );

    if (ok == true) {
      await _cargarProductos();
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
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildLista()),
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
              _cargarProductos();
            },
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
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

        _dropdown(
          value: _estado,
          hint: 'Estado',
          items: const {
            '1': 'Activos',
            '0': 'Eliminados',
          },
          onChanged: (v) {
            _estado = v!;
            _cargarProductos();
          },
        ),
        const SizedBox(width: 15),

        _dropdown(
          value: _proveedorId,
          hint: 'Proveedor',
          items: {
            '': 'Todos',
            for (var p in _proveedores) '${p['id']}': p['razon'],
          },
          onChanged: (v) {
            _proveedorId = v!;
            _cargarProductos();
          },
        ),
        const SizedBox(width: 15),

        _dropdown(
          value: _categoriaId,
          hint: 'Categoría',
          items: {
            '': 'Todas',
            for (var c in _categorias) '${c['id']}': c['nombre'],
          },
          onChanged: (v) {
            _categoriaId = v!;
            _cargarProductos();
          },
        ),
        const SizedBox(width: 15),

        _dropdown(
          value: _estadoInventario,
          hint: 'Inventario',
          items: const {
            '': 'Todos',
            '1': 'Disponible',
            '0': 'Agotado',
          },
          onChanged: (v) {
            _estadoInventario = v!;
            _cargarProductos();
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
            _cargarProductos();
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
          label: const Text('Nuevo producto'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => CrearProductoDialog(
                proveedores: _proveedores,
                categorias: _categorias,
              ),
            );

            if (creado == true) {
              _cargarProductos();
            }
          },
        ),
      ],
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _buildHeader() {
    return Row(
      children: const [
        _HeaderCell('Código'),
        _HeaderCell('Nombre'),
        _HeaderCell('Proveedor'),
        _HeaderCell('Categoría'),
        _HeaderCell('Stock'),
        _HeaderCell('Precio'),
        _HeaderCell('Costo'),
        _HeaderCell('Estado'),
        SizedBox(width: 126),
      ],
    );
  }

  // ───────────────── LISTA ─────────────────
  Widget _buildLista() {
    if (_productos.isEmpty) {
      return const Center(child: Text('No hay productos'));
    }

    return ListView.separated(
      itemCount: _productos.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final p = _productos[i];
        final activo = p['estado'] == 1;

        final proveedorNombre =
        p['proveedor'] != null && p['proveedor']['nombre'] != null
            ? p['proveedor']['nombre'].toString()
            : '—';

        final categoriaNombre =
        p['categoria'] != null && p['categoria']['nombre'] != null
            ? p['categoria']['nombre'].toString()
            : '—';

        return Row(
          children: [
            _Cell(p['codigo']?.toString() ?? '—'),
            _Cell(p['nombre']?.toString() ?? '—'),
            _Cell(proveedorNombre),
            _Cell(categoriaNombre),
            _Cell(p['stock']?.toString() ?? '0'),
            _Cell(CurrencyUtils.formatCop(p['precio'] ?? 0)),
            _Cell(CurrencyUtils.formatCop(p['precio_compra'] ?? 0)),
            _Cell(
              activo ? 'Activo' : 'Inactivo',
              color: activo ? Colors.green : Colors.red,
            ),
            SizedBox(
              width: 126,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (activo)
                    IconButton(
                      tooltip: 'Registrar baja de inventario',
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        size: 19,
                        color: Color(0xFFc0733d),
                      ),
                      onPressed: () => _abrirDialogBajaProducto(p),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                    onPressed: () async {
                      final actualizado = await showDialog(
                        context: context,
                        builder: (_) => CrearProductoDialog(
                          producto: p,
                          proveedores: _proveedores,
                          categorias: _categorias,
                        ),
                      );

                      if (actualizado == true) {
                        _cargarProductos();
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
            'Mostrando ${_productos.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarProductos();
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
                  _cargarProductos();
                }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _dropdown({
    required String value,
    required String hint,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      hint: Text(hint),
      items: items.entries
          .map(
            (e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}


// ───────────────── DIALOG BAJA DE PRODUCTO ─────────────────
class BajaProductoDialog extends StatefulWidget {
  final Map<String, dynamic> producto;
  final ProductosService service;

  const BajaProductoDialog({
    super.key,
    required this.producto,
    required this.service,
  });

  @override
  State<BajaProductoDialog> createState() => _BajaProductoDialogState();
}

class _BajaProductoDialogState extends State<BajaProductoDialog> {
  static const String _baseImagenUrl = 'http://200.7.100.146';

  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');
  final TextEditingController _motivoCtrl = TextEditingController();

  bool _guardando = false;

  double get _stockActual => _parseCantidad(widget.producto['stock']);
  double get _cantidad => _parseCantidad(_cantidadCtrl.text);
  double get _stockDespues => _stockActual - _cantidad;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarBaja() async {
    if (_guardando) return;

    final cantidad = _cantidad;
    final motivo = _motivoCtrl.text.trim();
    final idEmpleado = UsuarioActivo().id;
    final idProducto = int.tryParse(widget.producto['id'].toString()) ?? 0;

    if (idEmpleado == null) {
      _mostrarMensaje('No se encontró el usuario activo');
      return;
    }

    if (idProducto <= 0) {
      _mostrarMensaje('Producto inválido');
      return;
    }

    if (cantidad <= 0) {
      _mostrarMensaje('La cantidad de la baja debe ser mayor a cero');
      return;
    }

    if (motivo.isEmpty) {
      _mostrarMensaje('Debes escribir el motivo de la baja');
      return;
    }

    if (_stockDespues < 0) {
      final continuar = await _confirmarStockNegativo();
      if (continuar != true) return;
    }

    setState(() => _guardando = true);

    try {
      final idCaja = CajaActiva().idCaja;

      if (idCaja == null) {
        _mostrarMensaje('Debes activar una caja antes de registrar una baja');
        return;
      }

      final res = await widget.service.registrarBajaProducto(
        idProducto: idProducto,
        idCaja: idCaja,
        idEmpleado: idEmpleado,
        cantidad: cantidad,
        motivo: motivo,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _mostrarMensaje('Baja registrada correctamente', ok: true);
        Navigator.pop(context, true);
      } else {
        _mostrarMensaje(res['error'] ?? 'No se pudo registrar la baja');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje('Error registrando baja: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool?> _confirmarStockNegativo() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Stock quedará negativo'),
        content: Text(
          'La baja dejará el stock de "${widget.producto['nombre']}" en ${_formatCantidad(_stockDespues)}.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFc0733d),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Sí, continuar'),
          ),
        ],
      ),
    );
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
    final imageUrl = _urlImagen(widget.producto['url_imagen']);
    final stockDespues = _stockDespues;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, minWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildProductoResumen(imageUrl),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCantidadField()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildStockProyectado(stockDespues)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _motivoCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Motivo de la baja',
                  hintText: 'Ej: producto vencido, avería, pérdida, consumo interno...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildAcciones(),
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
            color: const Color(0xFFc0733d).withOpacity(0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.remove_circle_outline,
            color: Color(0xFFc0733d),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Registrar baja de inventario',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 3),
              Text(
                'Indica la cantidad y el motivo. El inventario se descontará al guardar.',
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

  Widget _buildProductoResumen(String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 96,
              height: 96,
              child: imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey,
                        size: 38,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto['nombre']?.toString() ?? 'Producto',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  runSpacing: 7,
                  children: [
                    _chipDato('Código', widget.producto['codigo']?.toString() ?? '—'),
                    _chipDato('Stock actual', _formatCantidad(_stockActual)),
                    _chipDato('Precio', CurrencyUtils.formatCop(widget.producto['precio'] ?? 0)),
                    _chipDato('Costo', CurrencyUtils.formatCop(widget.producto['precio_compra'] ?? 0)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipDato(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadField() {
    return TextField(
      controller: _cantidadCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      decoration: InputDecoration(
        labelText: 'Cantidad a dar de baja',
        hintText: 'Ej: 1',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildStockProyectado(double stockDespues) {
    final negativo = stockDespues < 0;
    final color = negativo ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(
            negativo ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock después de la baja',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54),
                ),
                Text(
                  _formatCantidad(stockDespues),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _guardando ? null : _guardarBaja,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando...' : 'Guardar baja'),
          ),
        ),
      ],
    );
  }

  String _urlImagen(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$_baseImagenUrl$raw';
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

  static String _formatCantidad(dynamic value) {
    final n = _parseCantidad(value);
    if (n == n.roundToDouble()) return n.round().toString();
    return n
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

// ───────────────── CELDAS ─────────────────
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
