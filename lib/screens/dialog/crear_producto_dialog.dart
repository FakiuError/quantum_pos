import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panaderia_nicol_pos/Services/productos_service.dart';

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
  final _stockCtrl = TextEditingController();
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
      _stockCtrl.text = p['stock'].toString();
      _precioCtrl.text = p['precio'].toString();
      _precioCompraCtrl.text = p['precio_compra'].toString();
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
      stock: _stockCtrl.text,
      precio: _precioCtrl.text,
      precioCompra: _precioCompraCtrl.text,
      proveedorId: _proveedorId!,
      categoriaId: _categoriaId!,
      imagen: _imagen,
    )
        : await _service.crearProducto(
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      stock: _stockCtrl.text,
      precio: _precioCtrl.text,
      precioCompra: _precioCompraCtrl.text,
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
              _input(_stockCtrl, 'Stock', keyboard: TextInputType.number),
              _input(_precioCtrl, 'Precio', keyboard: TextInputType.number),
              _input(_precioCompraCtrl, 'Precio compra',
                  keyboard: TextInputType.number),

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

  Widget _input(TextEditingController c, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
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
