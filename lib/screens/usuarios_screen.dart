import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/usuarios_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_usuario_dialog.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosService _service = UsuariosService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _usuarios = [];
  final Map<int, bool> _verPassword = {};

  String _buscar = '';
  String _rol = '';
  String _estado = '';
  String _orden = 'id';
  String _direccion = 'DESC';
  bool _ascendente = false;
  int _paginaActual = 1;
  int _totalPaginas = 1;
  int _totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final res = await _service.obtenerUsuarios(
      buscar: _buscar,
      rol: _rol,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _usuarios = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
    });
  }

  void _confirmarReactivar(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar usuario'),
        content: Text(
          '¿Deseas reactivar al usuario "${usuario['nombre']}"?',
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
              _reactivarUsuario(usuario['id']);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivarUsuario(int id) async {
    final ok = await _service.cambiarEstadoUsuario(id, 1);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
        //const SnackBar(content: Text('Usuario reactivado')),
      //);
      _cargarUsuarios();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reactivar usuario')),
      );
    }
  }

  void _confirmarEliminar(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar usuario'),
        content: Text(
          '¿Deseas desactivar al usuario "${usuario['nombre']}"?',
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
              _desactivarUsuario(usuario['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarUsuario(int id) async {
    final ok = await _service.cambiarEstadoUsuario(id, 0);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
        //const SnackBar(content: Text('Usuario desactivado')),
      //);
      _cargarUsuarios();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar usuario')),
      );
    }
  }

  void _mostrarDialogCrearUsuario() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CrearUsuarioDialog(),
    ).then((creado) {
      if (creado == true) {
        _cargarUsuarios(); // refresca tabla
      }
    });
  }


  void _toggleOrden() {
    setState(() {
      _ascendente = !_ascendente;
      _direccion = _ascendente ? 'ASC' : 'DESC';
    });
    _cargarUsuarios();
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
          Expanded(child: _buildUsuarios()),
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
        /// 🔍 BUSCAR
        Expanded(
          child: TextField(
            controller: _buscarCtrl,
            onChanged: (value) {
              _buscar = value;
              _cargarUsuarios();
            },
            decoration: InputDecoration(
              hintText: 'Buscar usuario...',
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

        /// 👤 ROL
        DropdownButton<String>(
          value: _rol.isEmpty ? null : _rol,
          hint: const Text('Rol'),
          items: const [
            DropdownMenuItem(
              value: 'Administrador',
              child: Text('Administrador'),
            ),
            DropdownMenuItem(value: 'Cajero', child: Text('Cajero')),
            DropdownMenuItem(value: 'Mesero', child: Text('Mesero')),
          ],
          onChanged: (v) {
            setState(() {
              _rol = v ?? '';
            });
            _cargarUsuarios();
          },
        ),

        const SizedBox(width: 12),

        /// 🔵 ESTADO
        DropdownButton<String>(
          value: _estado.isEmpty ? null : _estado,
          hint: const Text('Estado'),
          items: const [
            DropdownMenuItem(value: '1', child: Text('Activo')),
            DropdownMenuItem(value: '0', child: Text('Inactivo')),
          ],
          onChanged: (v) {
            setState(() {
              _estado = v ?? '';
            });
            _cargarUsuarios();
          },
        ),

        const SizedBox(width: 12),

        /// ⬆⬇ ORDEN
        IconButton(
          icon: Icon(
            _direccion == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
            color: _direccion == 'ASC' ? Colors.red : Colors.green,
          ),
          onPressed: () {
            setState(() {
              _direccion = _direccion == 'ASC' ? 'DESC' : 'ASC';
            });
            _cargarUsuarios();
          },
        ),

        const SizedBox(width: 12),

        /// ➕ NUEVO
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo usuario'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => const CrearUsuarioDialog(),
            );

            if (creado == true) {
              _cargarUsuarios();
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
        _HeaderCell('Usuario'),
        _HeaderCell('Contraseña'),
        _HeaderCell('Teléfono'),
        _HeaderCell('Rol'),
        _HeaderCell('Estado'),
        SizedBox(width: 80),
      ],
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildUsuarios() {
    if (_usuarios.isEmpty) {
      return const Center(child: Text('No hay usuarios'));
    }

    return ListView.separated(
      itemCount: _usuarios.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final u = _usuarios[i];
        final int id = u['id'];
        final bool activo = u['estado'] == 1;
        final bool verPass = _verPassword[id] ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Cell(u['nombre']),
              _Cell(u['usuario']),

              /// ───────── CONTRASEÑA ─────────
              Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _verPassword[u['id']] = !(_verPassword[u['id']] ?? false);
                      });
                    },
                    child: Text(
                      (_verPassword[u['id']] ?? false)
                          ? u['pass']
                          : '••••••••',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        letterSpacing: 1,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),

              _Cell(
                (u['telefono'] == null || u['telefono'].toString().trim().isEmpty)
                    ? 'No tiene'
                    : u['telefono'],
                color: (u['telefono'] == null || u['telefono'].toString().trim().isEmpty)
                    ? Colors.grey
                    : null,
              ),
              _Cell(u['rol']),
              _Cell(
                activo ? 'Activo' : 'Inactivo',
                color: activo ? Colors.green : Colors.red,
              ),

              /// ───────── ACCIONES ─────────
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
                          builder: (_) => CrearUsuarioDialog(usuario: u),
                        );

                        if (actualizado == true) {
                          _cargarUsuarios();
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
                          ? _confirmarEliminar(u)
                          : _confirmarReactivar(u),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            'Mostrando ${_usuarios.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarUsuarios();
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
                  _cargarUsuarios();
                }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────
  Widget _dropdown({
    required String value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButton<String>(
      value: value.isEmpty ? null : value,
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
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