import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/clientes_service.dart';
import 'package:panaderia_nicol_pos/screens/crear_cliente_dialog.dart';

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
  String _estado = '1'; // activos por defecto
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
        SizedBox(width: 80),
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
            _Cell('\$${c['deuda']}'),
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
