import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/categorias_service.dart';

class CrearCategoriaDialog extends StatefulWidget {
  final Map<String, dynamic>? categoria; //

  const CrearCategoriaDialog({super.key, this.categoria});

  @override
  State<CrearCategoriaDialog> createState() => _CrearCategoriaDialogState();
}

class _CrearCategoriaDialogState extends State<CrearCategoriaDialog> {
  final _nombreCtrl = TextEditingController();
  bool _guardando = false;

  final _service = CategoriasService();

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _nombreCtrl.text = widget.categoria!['nombre'] ?? '';
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarCategoria(
      id: widget.categoria!['id'],
      nombre: _nombreCtrl.text.trim(),
    )
        : await _service.crearCategorias(
      nombre: _nombreCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Error al actualizar categoria'
                : 'Error al crear categoria',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar categoria' : 'Crear categoria'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_nombreCtrl, 'Nombre (opcional)'),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
          ),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_esEdicion ? 'Guardar cambios' : 'Crear'),
        ),
      ],
    );
  }

  Widget _input(
      TextEditingController c,
      String label, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          floatingLabelStyle: const TextStyle(color: Colors.black),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }
}