import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/cajas_service.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

class CrearCajaDialog extends StatefulWidget {
  const CrearCajaDialog({Key? key}) : super(key: key);

  @override
  State<CrearCajaDialog> createState() => _CrearCajaDialogState();
}

class _CrearCajaDialogState extends State<CrearCajaDialog> {
  final _baseCtrl = TextEditingController(text: CurrencyUtils.formatControllerValue(0));
  final _bancolombiaCtrl = TextEditingController(text: CurrencyUtils.formatControllerValue(0));
  final _nequiCtrl = TextEditingController(text: CurrencyUtils.formatControllerValue(0));
  final _daviplataCtrl = TextEditingController(text: CurrencyUtils.formatControllerValue(0));
  final _obsCtrl = TextEditingController();

  bool _guardando = false;
  final _service = CajasService();

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    final ok = await _service.crearCaja(
      idEmpleado: UsuarioActivo().id!, // ✅ CAMBIO CLAVE
      saldoBase: CurrencyUtils.parse(_baseCtrl.text),
      nequi: CurrencyUtils.parse(_nequiCtrl.text),
      daviplata: CurrencyUtils.parse(_daviplataCtrl.text),
      bancolombia: CurrencyUtils.parse(_bancolombiaCtrl.text),
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
            _input(_baseCtrl, 'Saldo base', money: true),
            _input(_bancolombiaCtrl, 'Bancolombia inicial', money: true),
            _input(_nequiCtrl, 'Nequi inicial', money: true),
            _input(_daviplataCtrl, 'Daviplata inicial', money: true),
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

  Widget _input(TextEditingController c, String label, {bool money = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: money ? TextInputType.number : TextInputType.text,
        inputFormatters:
            money ? const [ColombianCurrencyInputFormatter()] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: money ? '\$ 0' : null,
        ),
      ),
    );
  }
}
