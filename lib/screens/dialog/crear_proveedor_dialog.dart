import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/proveedores_service.dart';

class CrearProveedorDialog extends StatefulWidget {
  final Map<String, dynamic>? proveedor; //

  const CrearProveedorDialog({super.key, this.proveedor});

  @override
  State<CrearProveedorDialog> createState() => _CrearProveedorDialogState();
}

class _CrearProveedorDialogState extends State<CrearProveedorDialog> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _razonCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  bool _guardando = false;

  final _service = ProveedoresService();

  bool get _esEdicion => widget.proveedor != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _nombreCtrl.text = widget.proveedor!['nombre'] ?? '';
      _apellidoCtrl.text = widget.proveedor!['apellido'] ?? '';
      _razonCtrl.text = widget.proveedor!['razon'] ?? '';
      _telefonoCtrl.text = widget.proveedor!['telefono'] ?? '';
      _correoCtrl.text = widget.proveedor!['correo'] ?? '';
      _direccionCtrl.text = widget.proveedor!['direccion'] ?? '';
    }
  }

  Future<void> _guardar() async {
    if (_razonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarProveedor(
      id: widget.proveedor!['id'],
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      razon: _razonCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
    )
        : await _service.crearProveedor(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      razon: _razonCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Error al actualizar proveedor'
                : 'Error al crear proveedor',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar proveedor' : 'Crear proveedor'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_nombreCtrl, 'Nombre (opcional)'),
            _input(_apellidoCtrl, 'Apellido (opcional)'),
            _input(_razonCtrl, 'Razón Social'),
            _input(
              _telefonoCtrl,
              'Teléfono (opcional)',
              keyboard: TextInputType.phone,
            ),
            _input(
              _correoCtrl,
              'Correo (opcional)',
              keyboard: TextInputType.emailAddress,
            ),
            _input(_direccionCtrl, 'Dirección (opcional)'),
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