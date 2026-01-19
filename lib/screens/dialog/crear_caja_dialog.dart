import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/cajas_service.dart';

class CrearCajaDialog extends StatefulWidget {
  const CrearCajaDialog({Key? key}) : super(key: key);

  @override
  State<CrearCajaDialog> createState() => _CrearCajaDialogState();
}

class _CrearCajaDialogState extends State<CrearCajaDialog> {
  final _baseCtrl = TextEditingController(text: '0');
  final _efectivoCtrl = TextEditingController(text: '0');
  final _nequiCtrl = TextEditingController(text: '0');
  final _daviplataCtrl = TextEditingController(text: '0');
  final _obsCtrl = TextEditingController();

  bool _guardando = false;
  final _service = CajasService();

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    final ok = await _service.crearCaja(
      idEmpleado: 1, // luego lo conectas al usuario logueado
      saldoBase: double.parse(_baseCtrl.text),
      efectivo: double.parse(_efectivoCtrl.text),
      nequi: double.parse(_nequiCtrl.text),
      daviplata: double.parse(_daviplataCtrl.text),
      observaciones: _obsCtrl.text,
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva caja'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(_baseCtrl, 'Saldo base'),
            _input(_efectivoCtrl, 'Efectivo inicial'),
            _input(_nequiCtrl, 'Nequi inicial'),
            _input(_daviplataCtrl, 'Daviplata inicial'),
            _input(_obsCtrl, 'Observaciones'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Crear'),
        ),
      ],
    );
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}