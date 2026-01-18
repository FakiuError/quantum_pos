import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/categorias_service.dart';
import 'package:panaderia_nicol_pos/screens/dialog/crear_categoria_dialog.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final CategoriasService _service = CategoriasService();
  final TextEditingController _buscarCtrl = TextEditingController();

  List<Map<String, dynamic>> _categorias = [];

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
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final res = await _service.obtenerCategorias(
      buscar: _buscar,
      estado: _estado,
      orden: _orden,
      direccion: _direccion,
      page: _paginaActual,
    );

    setState(() {
      _categorias = List<Map<String, dynamic>>.from(res['data']);
      _totalRegistros = res['total'];
      _totalPaginas = res['totalPages'];
    });
  }

  void _confirmarReactivar(Map<String, dynamic> categoria) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar categoria'),
        content: Text(
          '¿Deseas reactivar la categoria "${categoria['nombre']}"?',
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
              _reactivarCategoria(categoria['id']);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivarCategoria(int id) async {
    final ok = await _service.cambiarEstadoCategoria(id, 1);
    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Categoria reactivada')),
      //);
      _cargarCategorias();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reactivar categoria')),
      );
    }
  }

  void _confirmarEliminar(Map<String, dynamic> categoria) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar categoria'),
        content: Text(
          '¿Deseas desactivar la categoria "${categoria['nombre']}"?',
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
              _desactivarCategoria(categoria['id']);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarCategoria(int id) async {
    final ok = await _service.cambiarEstadoCategoria(id, 0);

    if (ok) {
      //ScaffoldMessenger.of(context).showSnackBar(
      //const SnackBar(content: Text('Categoria desactivada')),
      //);
      _cargarCategorias();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al desactivar categoria')),
      );
    }
  }

  void _mostrarDialogCrearCategoria() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CrearCategoriaDialog(),
    ).then((creado) {
      if (creado == true) {
        _cargarCategorias();
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
          Expanded(child: _buildCategorias()),
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
              _cargarCategorias();
            },
            decoration: InputDecoration(
              hintText: 'Buscar categoria...',
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
            _cargarCategorias();
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
            _cargarCategorias();
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
          label: const Text('Nueva categoria'),
          onPressed: () async {
            final creado = await showDialog(
              context: context,
              builder: (_) => const CrearCategoriaDialog(),
            );

            if (creado == true) {
              _cargarCategorias();
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
        _HeaderCell('Estado'),
        SizedBox(width: 80),
      ],
    );
  }

  // ───────────────── LIST ─────────────────
  Widget _buildCategorias() {
    if (_categorias.isEmpty) {
      return const Center(child: Text('No hay categorias'));
    }

    return ListView.separated(
      itemCount: _categorias.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final c = _categorias[i];
        final activo = c['estado'] == 1;

        String _val(String? v) =>
            (v == null || v.trim().isEmpty) ? 'No tiene' : v;

        return Row(
          children: [
            _Cell(c['nombre']),
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
                        builder: (_) => CrearCategoriaDialog(categoria: c),
                      );

                      if (actualizado == true) {
                        _cargarCategorias();
                      }
                    },
                  ),
                  IconButton(
                    tooltip: activo
                        ? 'Desactivar categoria'
                        : 'Reactivar categoria',
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
            'Mostrando ${_categorias.length} de $_totalRegistros registros',
            style: const TextStyle(color: Colors.black54),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _paginaActual > 1
                    ? () {
                  setState(() => _paginaActual--);
                  _cargarCategorias();
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
                  _cargarCategorias();
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