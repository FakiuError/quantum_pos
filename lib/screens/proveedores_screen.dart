import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/proveedores_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_proveedor_dialog.dart';

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

  Future<void> _cargarProveedores() async {
    final res = await _service.obtenerProveedores(
      buscar: _buscar,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _proveedores = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Proveedor reactivado')),
      //);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Proveedor desactivado')),
      //);
      _cargarProveedores();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar proveedor')),
      );
    }
  }

  void _mostrarDialogCrearProveedor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CrearProveedorDialog(),
    ).then((creado) {
      if (creado == true) {
        _cargarProveedores();
      }
    });
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

        /// ➕ NUEVO
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
    return Row(
      children: const [
        _HeaderCell('Nombre'),
        _HeaderCell('Apellido'),
        _HeaderCell('Razón'),
        _HeaderCell('Teléfono'),
        _HeaderCell('Correo'),
        _HeaderCell('Dirección'),
        _HeaderCell('Estado'),
        SizedBox(width: 80),
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
        final activo = p['estado'] == 1;

        String _val(String? v) =>
            (v == null || v.trim().isEmpty) ? 'No tiene' : v;

        return Row(
          children: [
            _Cell(_val(p['nombre'])),
            _Cell(_val(p['apellido'])),
            _Cell(p['razon']),
            _Cell(_val(p['telefono'])),
            _Cell(_val(p['correo'])),
            _Cell(_val(p['direccion'])),
            _Cell(
              activo ? 'Activo' : 'Eliminado',
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