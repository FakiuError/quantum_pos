import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/mesas_service.dart';

class CrearMesaDialog extends StatefulWidget {
  final Map<String, dynamic>? mesa; //

  const CrearMesaDialog({super.key, this.mesa});

  @override
  State<CrearMesaDialog> createState() => _CrearMesaDialogState();
}

class _CrearMesaDialogState extends State<CrearMesaDialog> {
  final _nombreCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  bool _guardando = false;

  final _service = MesasService();

  bool get _esEdicion => widget.mesa != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _nombreCtrl.text = widget.mesa!['nombre'] ?? '';
      _capacidadCtrl.text = widget.mesa!['capacidad'] ?? '';
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _capacidadCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarMesa(
      id: widget.mesa!['id'],
      nombre: _nombreCtrl.text.trim(),
      capacidad: _capacidadCtrl.text.trim(),
    )
        : await _service.crearMesa(
      nombre: _nombreCtrl.text.trim(),
      capacidad: _capacidadCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Error al actualizar mesa'
                : 'Error al crear mesa',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar mesa' : 'Crear mesa'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_nombreCtrl, 'Nombre'),
            _input(_capacidadCtrl, 'Capacidad'),
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