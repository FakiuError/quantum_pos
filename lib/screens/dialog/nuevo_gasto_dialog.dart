import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/gastos_service.dart';

class NuevoGastoDialog extends StatefulWidget {
  const NuevoGastoDialog({super.key});

  @override
  State<NuevoGastoDialog> createState() => _NuevoGastoDialogState();
}

class _NuevoGastoDialogState extends State<NuevoGastoDialog> {
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _montoCtrl = TextEditingController();

  bool? esCaja; // null = no seleccionado
  String? metodoPago;

  final List<String> _metodosPago = [
    'efectivo',
    'bancolombia',
    'nequi',
    'daviplata',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Nuevo gasto',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// DESCRIPCIÓN
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción del gasto',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              /// MONTO
              TextField(
                controller: _montoCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// ¿SALE DE CAJA?
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '¿Sale de caja diaria?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              RadioListTile<bool>(
                title: const Text('Sí'),
                value: true,
                groupValue: esCaja,
                onChanged: (v) => setState(() => esCaja = v),
              ),

              RadioListTile<bool>(
                title: const Text('No'),
                value: false,
                groupValue: esCaja,
                onChanged: (v) => setState(() => esCaja = v),
              ),

              const Divider(height: 28),

              /// MÉTODO DE PAGO
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Método de pago',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _metodosPago.map((m) {
                  final seleccionado = metodoPago == m;

                  return ChoiceChip(
                    label: Text(
                      m.toUpperCase(),
                      style: TextStyle(
                        color: seleccionado
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    selected: seleccionado,
                    selectedColor: const Color(0xFFc0733d),
                    onSelected: (_) {
                      setState(() => metodoPago = m);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
            foregroundColor: Colors.white,
          ),
          onPressed: _guardar,
          child: const Text('Guardar gasto'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    final descripcion = _descCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text) ?? 0;

    if (descripcion.isEmpty ||
        monto <= 0 ||
        esCaja == null ||
        metodoPago == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete todos los campos obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ok = await GastosService().crearGasto(
      descripcion: descripcion,
      monto: monto,
      esCaja: esCaja!,
      metodo: metodoPago!,
    );

    if (ok && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar el gasto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
