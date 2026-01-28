import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/productos_service.dart';
import 'package:panaderia_nicol_pos/Services/categorias_service.dart';
import 'package:panaderia_nicol_pos/Services/clientes_service.dart';
import 'package:panaderia_nicol_pos/Services/ventas_service.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';
import 'package:panaderia_nicol_pos/screens/core/esc_pos_service.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';

class VentasScreen extends StatefulWidget {
  final int idUsuario;

  const VentasScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _productosService = ProductosService();
  final _categoriasService = CategoriasService();

  final List<Map<String, dynamic>> _productos = [];
  final List<Map<String, dynamic>> _categorias = [];
  final List<Map<String, dynamic>> carrito = [];

  String _categoriaSeleccionada = '';
  double descuento = 0;

  bool get hayCajaActiva => CajaActiva().caja != null;

  static const String _baseImagenUrl = 'http://200.7.100.146';

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarProductos();
  }

  Future<void> _cargarCategorias() async {
    final res = await _categoriasService.obtenerCategorias();
    if (res['success'] == true) {
      setState(() {
        _categorias
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(res['data']));
      });
    }
  }

  Future<void> _cargarProductos() async {
    final res = await _productosService.obtenerProductos(
      categoriaId: _categoriaSeleccionada,
    );
    if (res['success'] == true) {
      setState(() {
        _productos
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(res['data']));
      });
    }
  }

  void _incrementarProducto(Map<String, dynamic> p) {
    setState(() {
      p['cantidad']++;
    });
  }

  void _decrementarProducto(Map<String, dynamic> p) {
    setState(() {
      if (p['cantidad'] > 1) {
        p['cantidad']--;
      } else {
        carrito.remove(p);
      }
    });
  }

  void _eliminarProducto(Map<String, dynamic> p) {
    setState(() {
      carrito.remove(p);
    });
  }

  void _agregarProducto(Map<String, dynamic> p) {
    final i = carrito.indexWhere((e) => e['id'] == p['id']);
    setState(() {
      if (i == -1) {
        carrito.add({
          'id': p['id'],
          'nombre': p['nombre'],
          'precio': p['precio'],
          'cantidad': 1,
        });
      } else {
        carrito[i]['cantidad']++;
      }
    });
  }

  Future<void> _abrirDialogoPan() async {
    final producto = await _productosService.obtenerProductoPorId(1);

    if (producto == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoPan(
        producto: producto,
        onConfirmar: _agregarPanAlCarrito,
      ),
    );
  }

  void _agregarPanAlCarrito({
    required int cantidad,
    required double valorTotal,
    required Map<String, dynamic> producto,
  }) {
    final precioUnitario = producto['precio'];
    final totalReal = precioUnitario * cantidad;
    final descuentoGenerado = totalReal - valorTotal;

    setState(() {
      carrito.add({
        'id': producto['id'],
        'nombre': producto['nombre'],
        'precio': precioUnitario,
        'cantidad': cantidad,
        'es_pan': true,
      });

      if (descuentoGenerado > 0) {
        descuento += descuentoGenerado;
      }
    });
  }


  double get subtotal =>
      carrito.fold(0, (s, p) => s + p['precio'] * p['cantidad']);

  double get total => subtotal - descuento;

  // ───────────────── LAYOUT ─────────────────

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildResumen(),
        Container(width: 1, color: Colors.grey.shade300),
        Expanded(child: _buildProductos()),
      ],
    );
  }

  // ───────────────── RESUMEN ─────────────────

  Widget _buildResumen() {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _actionButton(
                Icons.bakery_dining,
                'Pan',
                onTap: _abrirDialogoPan,
              ),
              const SizedBox(width: 10),
              _actionButton(
                Icons.percent,
                'Descuento',
                outlined: true,
                onTap: _aplicarDescuentoManual,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Resumen de venta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Divider(height: 30),
          Expanded(
            child: carrito.isEmpty
                ? const Center(child: Text('No hay productos'))
                : ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: carrito.length,
              separatorBuilder: (_, __) => const Divider(height: 10),
              itemBuilder: (_, i) {
                final p = carrito[i];

                return Dismissible(
                  key: ValueKey(p['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      carrito.removeAt(i);
                    });
                  },
                  child: Row(
                    children: [
                      /// NOMBRE
                      Expanded(
                        child: Text(
                          p['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),

                      /// CONTROLES CANTIDAD
                      Row(
                        children: [
                          _btnCantidad(
                            icon: Icons.remove,
                            onTap: () {
                              setState(() {
                                if (p['cantidad'] > 1) {
                                  p['cantidad']--;
                                }
                              });
                            },
                          ),

                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${p['cantidad']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          _btnCantidad(
                            icon: Icons.add,
                            onTap: () {
                              setState(() {
                                p['cantidad']++;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      /// PRECIO
                      Text(
                        '\$${(p['precio'] * p['cantidad']).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(width: 6),

                      /// ELIMINAR (ICONO)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            carrito.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 30),
          _rowTotal('Subtotal', subtotal),
          if (descuento > 0) _rowTotal('Descuento', -descuento),
          const Divider(),
          _rowTotal('Total', total, bold: true),
          const SizedBox(height: 20),
          Row(
            children: [
              if (!hayCajaActiva)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'No hay una caja activa',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      carrito.clear();
                      descuento = 0;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFc0733d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (total <= 0 || !hayCajaActiva)
                        ? null
                        : () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => ConfirmarVentaDialog(
                          total: total,
                        ),
                      );

                      if (result == null) return;

                      final cliente =
                      Map<String, dynamic>.from(result['cliente']);

                      final String metodoPago =
                      result['metodo_pago'] as String;

                      final double pagaCon =
                      (result['paga_con'] ?? total).toDouble();

                      final double cambioCalculado =
                      metodoPago == 'Efectivo'
                          ? (pagaCon - total)
                          : 0;

                      final double totalFinal = total;

                      // 📅 FECHA Y HORA DE LA FACTURA (SE CONGELA AQUÍ)
                      final DateTime fechaHoraFactura = DateTime.now();

                      final response = await VentasService().registrarVenta(
                        cliente: cliente,
                        carrito: carrito,
                        subtotal: subtotal,
                        descuento: descuento,
                        total: totalFinal,
                        metodoPago: metodoPago,
                        pagaCon: pagaCon,
                        idCaja: CajaActiva().idCaja!,
                        idEmpleado: UsuarioActivo().id!,
                      );

                      if (response == null || response['success'] != true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                response?['error'] ??
                                    '❌ Error al registrar la venta'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ───── NUMERO DE FACTURA SEGURO ─────
                      int numeroFactura = 0;

                      if (response['venta'] != null &&
                          response['venta'] is Map &&
                          response['venta']['id'] != null) {
                        numeroFactura = response['venta']['id'];
                      } else if (response['id_venta'] != null) {
                        numeroFactura = response['id_venta'];
                      }

                      // 👤 NOMBRE DEL USUARIO QUE ATIENDE
                      // 👉 Ajusta según cómo manejes usuarios
                      final String usuarioAtiende =
                          response['usuario']?['nombre'] ??
                              'Usuario ${UsuarioActivo().id!}';

                      if (response['caja'] != null) {
                        CajaActiva().actualizarDesdeBackend(
                          Map<String, dynamic>.from(response['caja']),
                        );
                      }

                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => DialogoVentaFinal(
                          numeroFactura: numeroFactura,
                          cliente:
                          '${cliente['nombre']} ${cliente['apellido']}',
                          identificacion:
                          cliente['identificacion'] ?? 'N/A',
                          usuario: usuarioAtiende,          // 👤 NUEVO
                          fechaHora: fechaHoraFactura,      // 📅 NUEVO
                          subtotal: subtotal,
                          descuento: descuento,
                          total: totalFinal,
                          cambio: cambioCalculado,
                          items:
                          List<Map<String, dynamic>>.from(carrito),
                        ),
                      );

                      setState(() {
                        carrito.clear();
                        descuento = 0;
                      });
                    },
                    child: const Text(
                      'Cobrar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btnCantidad({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.black87,
        ),
      ),
    );
  }


  Widget _rowTotal(String t, double v, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t,
            style:
            TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w400)),
        Text('\$${v.toStringAsFixed(0)}',
            style:
            TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w400)),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label,
      {bool outlined = false, required VoidCallback onTap}) {
    return Expanded(
      child: outlined
          ? OutlinedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      )
          : ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFc0733d),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
      ),
    );
  }

  // ───────────────── PRODUCTOS ─────────────────

  Widget _buildProductos() {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: _productos.length,
            itemBuilder: (_, i) => _productoCard(_productos[i]),
          ),
        ),
        _buildCategorias(),
      ],
    );
  }

  Widget _productoCard(Map<String, dynamic> p) {
    final img = p['url_imagen'];
    return InkWell(
      onTap: () => _agregarProducto(p),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Expanded(
              child: img != null && img.toString().isNotEmpty
                  ? Image.network(
                _baseImagenUrl + img,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image_not_supported, size: 40),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                p['nombre'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── CATEGORÍAS ─────────────────

  Widget _buildCategorias() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = _categorias[i];
          final selected = _categoriaSeleccionada == c['id'].toString();

          return InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              setState(() {
                _categoriaSeleccionada =
                selected ? '' : c['id'].toString();
              });
              _cargarProductos();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFc0733d)
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFc0733d)
                      : Colors.grey.shade300,
                ),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color:
                    const Color(0xFFc0733d).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: Text(
                  c['nombre'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  // ───────────────── DESCUENTO ─────────────────

  void _aplicarDescuentoManual() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aplicar descuento'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final valor = double.tryParse(c.text) ?? subtotal;
              setState(() {
                descuento = subtotal - valor;
                if (descuento < 0) descuento = 0;
              });
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

class _DialogoPan extends StatefulWidget {
  final Map<String, dynamic> producto;
  final void Function({
  required int cantidad,
  required double valorTotal,
  required Map<String, dynamic> producto,
  }) onConfirmar;

  const _DialogoPan({
    required this.producto,
    required this.onConfirmar,
  });

  @override
  State<_DialogoPan> createState() => _DialogoPanState();
}

class _DialogoPanState extends State<_DialogoPan> {
  final TextEditingController _valorCtrl = TextEditingController();

  double precio = 0;
  double stock = 0;
  int cantidad = 0;
  double valor = 0;

  @override
  void initState() {
    super.initState();
    precio = double.tryParse(widget.producto['precio'].toString()) ?? 0;
    stock = double.tryParse(widget.producto['stock'].toString()) ?? 0;;
    _valorCtrl.text = '';
  }

  void _recalcularCantidad() {
    setState(() {
      cantidad = precio > 0 ? (valor / precio).floor() : 0;
    });
  }

  void _agregarNumero(String n) {
    setState(() {
      _valorCtrl.text += n;
      valor = double.tryParse(_valorCtrl.text) ?? 0;
      _recalcularCantidad();
    });
  }

  void _borrarNumero() {
    setState(() {
      if (_valorCtrl.text.isNotEmpty) {
        _valorCtrl.text =
            _valorCtrl.text.substring(0, _valorCtrl.text.length - 1);
        valor = double.tryParse(_valorCtrl.text) ?? 0;
        _recalcularCantidad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sinStock = cantidad > stock;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 560,
        height: 420, // 🔥 ALTURA CONTROLADA
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              /// ───────── INFO PAN ─────────
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bakery_dining,
                      size: 46,
                      color: Color(0xFFc0733d),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      widget.producto['nombre'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _valorCtrl,
                      readOnly: true,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Valor a gastar',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Cantidad de panes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 30,
                          onPressed: cantidad > 0
                              ? () => setState(() => cantidad--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$cantidad',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 30,
                          onPressed: () => setState(() => cantidad++),
                        ),
                      ],
                    ),

                    if (sinStock)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Stock insuficiente ($stock disponibles)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    const Spacer(),

                    /// BOTONES
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFc0733d),
                            ),
                            onPressed: (cantidad <= 0 || sinStock)
                                ? null
                                : () {
                              widget.onConfirmar(
                                cantidad: cantidad,
                                valorTotal: valor,
                                producto: widget.producto,
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// ───────── SEPARADOR ─────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: VerticalDivider(thickness: 1),
              ),

              /// ───────── TECLADO ─────────
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var fila in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['0', '⌫'],
                    ])
                      Row(
                        children: fila.map((n) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFFc0733d),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: n == '⌫'
                                    ? _borrarNumero
                                    : () => _agregarNumero(n),
                                child: Text(
                                  n,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmarVentaDialog extends StatefulWidget {
  final double total;

  const ConfirmarVentaDialog({
    super.key,
    required this.total,
  });

  @override
  State<ConfirmarVentaDialog> createState() => _ConfirmarVentaDialogState();
}

class _ConfirmarVentaDialogState extends State<ConfirmarVentaDialog> {
  final ClientesService _clientesService = ClientesService();

  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? _clienteSeleccionado;

  final TextEditingController _buscarClienteCtrl = TextEditingController();

  String metodoPago = 'efectivo';

  final TextEditingController _efectivoCtrl = TextEditingController();
  double pagaCon = 0;

  bool cargandoClientes = true;

  bool get hayCajaActiva => CajaActiva().caja != null;

  double get cambio => pagaCon - widget.total;

  bool get puedeConfirmar {
    if (!hayCajaActiva) return false;

    switch (metodoPago) {
      case 'efectivo':
        return pagaCon >= widget.total;
      case 'fiado':
        return _clienteSeleccionado != null &&
            _clienteSeleccionado!['id'] != 1;
      default:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  // ───────────── CLIENTES ─────────────
  Future<void> _cargarClientes() async {
    final res = await _clientesService.obtenerClientes(buscar: '');

    if (res['success'] == true && res['data'] is List) {
      final list = List<Map<String, dynamic>>.from(res['data']);

      setState(() {
        _clientes = list;
        _clienteSeleccionado =
            list.firstWhere((c) => c['id'] == 1, orElse: () => list.first);
        cargandoClientes = false;
      });
    }
  }

  void _filtrarClientes(String v) async {
    final res = await _clientesService.obtenerClientes(buscar: v);
    if (res['success'] == true) {
      setState(() {
        _clientes = List<Map<String, dynamic>>.from(res['data']);
      });
    }
  }

  // ───────────── TECLADO ─────────────
  void _agregarNumero(String n) {
    setState(() {
      _efectivoCtrl.text += n;
      pagaCon = double.tryParse(_efectivoCtrl.text) ?? 0;
    });
  }

  void _borrarNumero() {
    setState(() {
      if (_efectivoCtrl.text.isNotEmpty) {
        _efectivoCtrl.text =
            _efectivoCtrl.text.substring(0, _efectivoCtrl.text.length - 1);
        pagaCon = double.tryParse(_efectivoCtrl.text) ?? 0;
      }
    });
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 780,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirmar venta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ───── CLIENTES ─────
                _buildClientes(),

                const SizedBox(width: 20),

                /// ───── PAGO ─────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetodosPago(),
                      const SizedBox(height: 20),
                      if (metodoPago == 'efectivo')
                        Row(
                          children: [
                            _buildPanelEfectivo(),
                            const SizedBox(width: 20),
                            _buildTeclado(),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: \$${widget.total.toStringAsFixed(0)}',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (!hayCajaActiva)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '⚠ Debe activar una caja para poder cobrar',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      actionsPadding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFc0733d),
          ),
          onPressed: puedeConfirmar
              ? () {
            Navigator.pop(context, {
              'cliente': _clienteSeleccionado,
              'metodo_pago': metodoPago,
              'paga_con': pagaCon,
            });
          }
              : null,
          child: const Text(
            'Confirmar venta',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ───────── CLIENTES ─────────
  Widget _buildClientes() {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cliente',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _buscarClienteCtrl,
            onChanged: _filtrarClientes,
            decoration: const InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: cargandoClientes
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _clientes.length,
              itemBuilder: (_, i) {
                final c = _clientes[i];
                final selected = _clienteSeleccionado?['id'] == c['id'];

                return ListTile(
                  selected: selected,
                  selectedTileColor:
                  const Color(0xFFc0733d).withOpacity(0.12),
                  title: Text(c['nombre'] + " " + c["apellido"]),
                  subtitle: Text(c['identificacion'] ?? ''),
                  onTap: () {
                    setState(() {
                      _clienteSeleccionado = c;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────── MÉTODOS ─────────
  Widget _buildMetodosPago() {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metodoPagoCard('efectivo', 'Efectivo', Icons.payments),
        _metodoPagoCard('bancolombia', 'Bancolombia', Icons.account_balance,),
        _metodoPagoCard('nequi', 'Nequi', Icons.phone_android),
        _metodoPagoCard('daviplata', 'Daviplata', Icons.account_balance_wallet),
        _metodoPagoCard('fiado', 'Fiado', Icons.schedule),
      ],
    );
  }

  Widget _metodoPagoCard(String value, String label, IconData icon) {
    final selected = metodoPago == value;

    return InkWell(
      onTap: () => setState(() => metodoPago = value),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFc0733d) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
            selected ? const Color(0xFFc0733d) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────── EFECTIVO ─────────
  Widget _buildPanelEfectivo() {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paga con'),
          const SizedBox(height: 6),
          TextField(
            controller: _efectivoCtrl,
            readOnly: true,
            decoration: const InputDecoration(
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            cambio >= 0
                ? 'Cambio: \$${cambio.toStringAsFixed(0)}'
                : 'Faltan: \$${cambio.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: cambio >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── TECLADO ─────────
  Widget _buildTeclado() {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          for (var fila in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['0', '⌫']
          ])
            Row(
              children: fila.map((n) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFc0733d),
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                      n == '⌫' ? _borrarNumero : () => _agregarNumero(n),
                      child: Text(
                        n,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class DialogoVentaFinal extends StatefulWidget {
  final int numeroFactura;
  final String cliente;
  final String identificacion;

  final double subtotal;
  final double descuento;
  final double total;
  final double cambio;

  final String usuario;
  final DateTime fechaHora;
  final List<Map<String, dynamic>> items;

  const DialogoVentaFinal({
    super.key,
    required this.numeroFactura,
    required this.cliente,
    required this.identificacion,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.cambio,
    required this.items,
    required this.usuario,
    required this.fechaHora,

  });

  @override
  State<DialogoVentaFinal> createState() => _DialogoVentaFinalState();
}

class _DialogoVentaFinalState extends State<DialogoVentaFinal> {
  @override
  void initState() {
    super.initState();

    /// 🔓 ABRIR CAJÓN AUTOMÁTICAMENTE AL MOSTRAR LA VENTANA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EscPosService.abrirCajon();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🧾 ICONO
              const Icon(
                Icons.receipt_long,
                size: 64,
                color: Color(0xFFc0733d),
              ),

              const SizedBox(height: 16),

              /// 💰 TOTAL
              Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${widget.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// 🔄 CAMBIO
              if (widget.cambio > 0) ...[
                Text(
                  'CAMBIO',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${widget.cambio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Divider(height: 30),

              /// ❓ PREGUNTA
              const Text(
                '¿Desea imprimir la factura?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 26),

              /// 🔘 BOTONES
              Row(
                children: [

                  /// ❌ NO IMPRIMIR
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black54),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'No',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// 🧾 IMPRIMIR
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFc0733d),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        try {
                          await EscPosService.imprimirTicket(
                            numeroFactura: widget.numeroFactura,
                            cliente: widget.cliente,
                            identificacion: widget.identificacion,
                            usuario: widget.usuario,              // ← NUEVO
                            fechaHora: DateTime.now(),             // ← NUEVO
                            subtotal: widget.subtotal,
                            descuento: widget.descuento,
                            total: widget.total,
                            cambio: widget.cambio,
                            items: widget.items,
                          );

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Sí',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}