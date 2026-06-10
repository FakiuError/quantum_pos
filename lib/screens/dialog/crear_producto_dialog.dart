import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panaderia_nicol_pos/Services/productos_service.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

class CrearProductoDialog extends StatefulWidget {
  final Map<String, dynamic>? producto;
  final List proveedores;
  final List categorias;

  const CrearProductoDialog({
    super.key,
    this.producto,
    required this.proveedores,
    required this.categorias,
  });

  @override
  State<CrearProductoDialog> createState() => _CrearProductoDialogState();
}

class _CrearProductoDialogState extends State<CrearProductoDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();

  String? _proveedorId;
  String? _categoriaId;

  File? _imagen;
  bool _guardando = false;

  final _service = ProductosService();

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();

    if (_esEdicion) {
      final p = widget.producto!;
      _codigoCtrl.text = p['codigo'] ?? '';
      _nombreCtrl.text = p['nombre'] ?? '';
      _precioCtrl.text = CurrencyUtils.formatControllerValue(p['precio']);
      _precioCompraCtrl.text = CurrencyUtils.formatControllerValue(p['precio_compra']);
      _proveedorId = p['proveedor']?['id']?.toString();
      _categoriaId = p['categoria']?['id']?.toString();
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _imagen = File(img.path));
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty ||
        _precioCtrl.text.isEmpty ||
        _proveedorId == null ||
        _categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete los campos obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);

    final ok = _esEdicion
        ? await _service.actualizarProducto(
      id: widget.producto!['id'],
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      stock: widget.producto?['stock']?.toString() ?? '0',
      precio: CurrencyUtils.toDatabaseString(_precioCtrl.text),
      precioCompra: CurrencyUtils.toDatabaseString(_precioCompraCtrl.text),
      proveedorId: _proveedorId!,
      categoriaId: _categoriaId!,
      imagen: _imagen,
    )
        : await _service.crearProducto(
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      stock: '0',
      precio: CurrencyUtils.toDatabaseString(_precioCtrl.text),
      precioCompra: CurrencyUtils.toDatabaseString(_precioCompraCtrl.text),
      proveedorId: _proveedorId!,
      categoriaId: _categoriaId!,
      imagen: _imagen,
    );

    setState(() => _guardando = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar producto')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar producto' : 'Crear producto'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _input(_codigoCtrl, 'Código'),
              _input(_nombreCtrl, 'Nombre'),
              if (_esEdicion)
                _stockSoloLectura(widget.producto?['stock'] ?? 0)
              else
                _avisoStockInicial(),
              _input(_precioCtrl, 'Precio', keyboard: TextInputType.number, money: true),
              _input(_precioCompraCtrl, 'Precio compra',
                  keyboard: TextInputType.number, money: true),

              _dropdown(
                value: _proveedorId,
                hint: 'Proveedor',
                items: {
                  for (var p in widget.proveedores)
                    '${p['id']}': p['razon']
                },
                onChanged: (v) => setState(() => _proveedorId = v),
              ),

              _dropdown(
                value: _categoriaId,
                hint: 'Categoría',
                items: {
                  for (var c in widget.categorias)
                    '${c['id']}': c['nombre']
                },
                onChanged: (v) => setState(() => _categoriaId = v),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _seleccionarImagen,
                    icon: const Icon(Icons.image),
                    label: const Text('Seleccionar imagen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc0733d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_imagen != null) const Text('Imagen seleccionada'),
                ],
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
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
          ),
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

  Widget _stockSoloLectura(dynamic stock) {
    final texto = _formatCantidad(stock);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFFc0733d)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock actual',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  texto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const Tooltip(
            message: 'El stock se modifica solo con entradas o bajas de inventario.',
            child: Icon(Icons.lock_outline, size: 18, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _avisoStockInicial() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFc0733d).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFc0733d).withOpacity(0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Color(0xFFc0733d)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'El producto se creará con stock 0. Para aumentar inventario usa Entradas a proveedor.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCantidad(dynamic value) {
    final n = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
    if (n == n.roundToDouble()) return n.round().toString();
    return n
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool money = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: money ? TextInputType.number : keyboard,
        inputFormatters:
            money ? const [ColombianCurrencyInputFormatter()] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: money ? '\$ 0' : null,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        items: items.entries
            .map((e) =>
            DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
