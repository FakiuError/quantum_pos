import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/usuarios_service.dart';

class CrearUsuarioDialog extends StatefulWidget {
  final Map<String, dynamic>? usuario; // 👈 NUEVO

  const CrearUsuarioDialog({super.key, this.usuario});

  @override
  State<CrearUsuarioDialog> createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<CrearUsuarioDialog> {
  final _nombreCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String _rol = 'Mesero';
  bool _verPassword = false;
  bool _guardando = false;

  final _service = UsuariosService();

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      _nombreCtrl.text = widget.usuario!['nombre'] ?? '';
      _usuarioCtrl.text = widget.usuario!['usuario'] ?? '';
      _telefonoCtrl.text = widget.usuario!['telefono'] ?? '';
      _passCtrl.text = widget.usuario!['pass'] ?? '';
      _rol = widget.usuario!['rol'] ?? 'Mesero';
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _usuarioCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    if (!_esEdicion && _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña es obligatoria')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarUsuario(
      id: widget.usuario!['id'],
      nombre: _nombreCtrl.text.trim(),
      usuario: _usuarioCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      pass: _passCtrl.text.trim(),
      rol: _rol,
    )
        : await _service.crearUsuario(
      nombre: _nombreCtrl.text.trim(),
      usuario: _usuarioCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      pass: _passCtrl.text.trim(),
      rol: _rol,
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esEdicion
                ? 'Error al actualizar usuario'
                : 'Error al crear usuario',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar usuario' : 'Crear usuario'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_nombreCtrl, 'Nombre'),
            _input(_usuarioCtrl, 'Usuario'),
            _input(
              _telefonoCtrl,
              'Teléfono (opcional)',
              keyboard: TextInputType.phone,
            ),

            /// CONTRASEÑA
            TextField(
              controller: _passCtrl,
              obscureText: !_verPassword,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(color: Colors.black),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black54),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _verPassword = !_verPassword),
                  color: const Color(0xFFc0733d),
                ),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _rol,
              items: const [
                DropdownMenuItem(
                    value: 'Administrador', child: Text('Administrador')),
                DropdownMenuItem(value: 'Cajero', child: Text('Cajero')),
                DropdownMenuItem(value: 'Mesero', child: Text('Mesero')),
              ],
              onChanged: (v) => setState(() => _rol = v!),
              decoration: const InputDecoration(
                labelText: 'Rol',
                labelStyle: TextStyle(color: Colors.black),
              ),
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