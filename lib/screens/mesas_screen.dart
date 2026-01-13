import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/mesas_service.dart';
import 'package:panaderia_nicol_pos/screens/crear_mesa_dialog.dart';

class MesasScreen extends StatefulWidget {
  const MesasScreen({super.key});

  @override
  State<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends State<MesasScreen> {
  final MesasService _service = MesasService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _mesas = [];

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
    _cargarMesas();
  }

  Future<void> _cargarMesas() async {
    final res = await _service.obtenerMesas(
      buscar: _buscar,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _mesas = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
    });
  }

  /*
  void _confirmarReactivar(Map<String, dynamic> mesa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar Mesa'),
        content: Text(
          '¿Deseas reactivar la mesa "${mesa['nombre']}"?',
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
              _reactivarMesa(mesa['id']);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivarMesa(int id) async {
    final ok = await _service.cambiarEstadoMesa(id, 1);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Mesa reactivada')),
      //);
      _cargarMesas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reactivar mesa')),
      );
    }
  }


  void _confirmarEliminar(Map<String, dynamic> mesa) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar mesa'),
        content: Text(
          '¿Deseas desactivar la mesa "${mesa['nombre']}"?',
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
              _desactivarMesa(mesa['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarMesa(int id) async {
    final ok = await _service.cambiarEstadoMesa(id, 0);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Mesa desactivada')),
      //);
      _cargarMesas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar mesa')),
      );
    }
  }
   */

  void _mostrarDialogCrearMesa() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CrearMesaDialog(),
    ).then((creado) {
      if (creado == true) {
        _cargarMesas();
      }
    });
  }


  void _toggleOrden() {
    setState(() {
      _ascendente = !_ascendente;
      _direccion = _ascendente ? 'ASC' : 'DESC';
    });
    _cargarMesas();
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
          Expanded(child: _buildMesas()),
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
              _cargarMesas();
            },
            decoration: InputDecoration(
              hintText: 'Buscar Mesa...',
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
            _cargarMesas();
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
          label: const Text('Nueva Mesa'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => const CrearMesaDialog(),
            );

            if (creado == true) {
              _cargarMesas();
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
        _HeaderCell('Capacidad'),
        SizedBox(width: 80),
      ],
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildMesas() {
    if (_mesas.isEmpty) {
      return const Center(child: Text('No hay mesas'));
    }

    return ListView.separated(
      itemCount: _mesas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = _mesas[i];
        final int id = m['id'];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Cell(m['nombre']),
              _Cell(m['capacidad']),

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
                          builder: (_) => CrearMesaDialog(mesa: m),
                        );

                        if (actualizado == true) {
                          _cargarMesas();
                        }
                      },
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
            'Mostrando ${_mesas.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarMesas();
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
                  _cargarMesas();
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