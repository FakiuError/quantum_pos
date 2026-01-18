import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/clientes_service.dart';

class CrearClienteDialog extends StatefulWidget {
  final Map<String, dynamic>? cliente; //

  const CrearClienteDialog({super.key, this.cliente});

  @override
  State<CrearClienteDialog> createState() => _CrearClienteDialogState();
}

class _CrearClienteDialogState extends State<CrearClienteDialog> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _identificacionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _deudaCtrl = TextEditingController();
  bool _guardando = false;

  final _service = ClientesService();

  bool get _esEdicion => widget.cliente != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _nombreCtrl.text = widget.cliente!['nombre'] ?? '';
      _apellidoCtrl.text = widget.cliente!['apellido'] ?? '';
      _identificacionCtrl.text = widget.cliente!['identificacion'] ?? '';
      _telefonoCtrl.text = widget.cliente!['telefono'] ?? '';
      _correoCtrl.text = widget.cliente!['correo'] ?? '';
      _deudaCtrl.text = widget.cliente!['deuda']?.toString() ?? '';
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _apellidoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarCliente(
      id: widget.cliente!['id'],
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      identificacion: _identificacionCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      deuda: double.tryParse(_deudaCtrl.text.trim()) ?? 0.0,
    )
        : await _service.crearCliente(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      identificacion: _identificacionCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      deuda: double.tryParse(_deudaCtrl.text.trim()) ?? 0.0,
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Error al actualizar cliente'
                : 'Error al crear cliente',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar cliente' : 'Crear cliente'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_nombreCtrl, 'Nombre'),
            _input(_apellidoCtrl, 'Apellido'),
            _input(
              _identificacionCtrl,
              'Identificación (opcional)',
              keyboard: TextInputType.phone,
            ),
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
            _input(
              _deudaCtrl,
              'Deuda',
              keyboard: TextInputType.number,
            ),
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