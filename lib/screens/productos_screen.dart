import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/productos_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_producto_dialog.dart';

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
        SizedBox(width: 80),
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
            _Cell('\$${p['precio'] ?? 0}'),
            _Cell('\$${p['precio_compra'] ?? 0}'),
            _Cell(
              activo ? 'Activo' : 'Inactivo',
              color: activo ? Colors.green : Colors.red,
            ),
            SizedBox(
              width: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
