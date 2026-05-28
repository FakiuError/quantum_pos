import 'package:flutter/material.dart';
import '../services/pedidos_service.dart';
import '../widgets/productos_grid_widget.dart';

class PedidoScreen extends StatefulWidget {
  final int idMesa;
  final int idPedido;
  final int idEmpleado;

  const PedidoScreen({
    super.key,
    required this.idMesa,
    required this.idPedido,
    required this.idEmpleado,
  });

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  final PedidosService _pedidosService = PedidosService();

  bool cargando = true;
  List<Map<String, dynamic>> carrito = [];

  @override
  void initState() {
    super.initState();
    _cargarPedido(mostrarCarga: true);
  }

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  double _toDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  bool _estaFinalizado(Map<String, dynamic> item) {
    return _toInt(item["estado"], defaultValue: 2) == 3;
  }

  String _textoEstado(Map<String, dynamic> item) {
    final estado = _toInt(item["estado"], defaultValue: 2);

    if (estado == 3) return "Finalizado";
    if (estado == 2) return "En preparación";

    return "Pendiente";
  }

  Color _colorEstado(Map<String, dynamic> item) {
    final estado = _toInt(item["estado"], defaultValue: 2);

    if (estado == 3) return Colors.blueGrey;
    if (estado == 2) return Colors.orange.shade700;

    return Colors.grey;
  }

  Future<void> _cargarPedido({bool mostrarCarga = false}) async {
    if (mostrarCarga && mounted) {
      setState(() {
        cargando = true;
      });
    }

    final res = await _pedidosService.obtenerDetallesPedido(
      idPedido: widget.idPedido,
    );

    List<Map<String, dynamic>> nuevoCarrito = [];

    if (res != null && res['success'] == true) {
      final detalles = res['data'];

      if (detalles != null && detalles is List) {
        nuevoCarrito = detalles.map<Map<String, dynamic>>((d) {
          return {
            "idDetalle": d["id"],
            "id_producto": d["id_producto"],
            "id_platillo": d["id_platillo"],
            "nombre": d["nombre"] ?? "",
            "precio": _toDouble(d["precio"]),
            "cantidad": _toDouble(d["cantidad"]),
            "comentario": d["comentario"] ?? "",
            "estado": _toInt(d["estado"], defaultValue: 2),
          };
        }).toList();
      }
    }

    if (!mounted) return;

    setState(() {
      carrito = nuevoCarrito;
      cargando = false;
    });
  }

  Future<void> _mostrarError(String mensaje) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> agregarProducto(producto) async {
    final res = await _pedidosService.agregarProducto(
      idPedido: widget.idPedido,
      idProducto: _toInt(producto["id"]),
      cantidad: 1,
    );

    if (res == null || res['success'] != true) {
      await _mostrarError(
        res?["message"]?.toString() ??
            res?["error"]?.toString() ??
            "No se pudo agregar el producto al pedido",
      );
      return;
    }

    await _cargarPedido();
  }

  double calcularTotal() {
    double total = 0;

    for (var item in carrito) {
      total += _toDouble(item["precio"]) * _toDouble(item["cantidad"]);
    }

    return total;
  }

  Future<void> confirmarPedido() async {
    final res = await _pedidosService.confirmarPedido(
      idPedido: widget.idPedido,
    );

    if (res != null && res['success'] == true) {
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Widget resumenPedido() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: carrito.length,
            itemBuilder: (context, index) {
              final item = carrito[index];
              final bool finalizado = _estaFinalizado(item);
              final int? idDetalle = item["idDetalle"] == null
                  ? null
                  : _toInt(item["idDetalle"]);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: finalizado ? Colors.grey.shade100 : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item["nombre"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _colorEstado(item).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _textoEstado(item),
                              style: TextStyle(
                                color: _colorEstado(item),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              if (idDetalle != null && idDetalle > 0) {
                                final res = await _pedidosService.eliminarDetalle(
                                  idDetalle: idDetalle,
                                );

                                if (res == null || res['success'] != true) {
                                  await _mostrarError(
                                    res?["message"]?.toString() ??
                                        res?["error"]?.toString() ??
                                        "No se pudo eliminar el detalle",
                                  );
                                  return;
                                }
                              }

                              await _cargarPedido();
                            },
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: finalizado
                                ? () async {
                              await _mostrarError(
                                "No puedes disminuir un producto que ya fue finalizado por cocina.",
                              );
                            }
                                : () async {
                              final res = await _pedidosService.agregarProducto(
                                idPedido: widget.idPedido,
                                idDetalle: idDetalle,
                                idProducto: item["id_producto"] == null
                                    ? null
                                    : _toInt(item["id_producto"]),
                                idPlatillo: item["id_platillo"] == null
                                    ? null
                                    : _toInt(item["id_platillo"]),
                                cantidad: -1,
                              );

                              if (res == null || res['success'] != true) {
                                await _mostrarError(
                                  res?["message"]?.toString() ??
                                      res?["error"]?.toString() ??
                                      "No se pudo disminuir la cantidad",
                                );
                                return;
                              }

                              await _cargarPedido();
                            },
                          ),

                          Text(
                            _toDouble(item["cantidad"]).toStringAsFixed(
                              _toDouble(item["cantidad"]) % 1 == 0 ? 0 : 2,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final res = await _pedidosService.agregarProducto(
                                idPedido: widget.idPedido,
                                idDetalle: idDetalle,
                                idProducto: item["id_producto"] == null
                                    ? null
                                    : _toInt(item["id_producto"]),
                                idPlatillo: item["id_platillo"] == null
                                    ? null
                                    : _toInt(item["id_platillo"]),
                                cantidad: 1,
                              );

                              if (res == null || res['success'] != true) {
                                await _mostrarError(
                                  res?["message"]?.toString() ??
                                      res?["error"]?.toString() ??
                                      "No se pudo aumentar la cantidad",
                                );
                                return;
                              }

                              await _cargarPedido();
                            },
                          ),

                          const Spacer(),

                          Text(
                            "\$${(_toDouble(item["precio"]) * _toDouble(item["cantidad"])).toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              final TextEditingController ctrl =
                              TextEditingController(
                                text: item["comentario"] ?? "",
                              );

                              showDialog(
                                context: context,
                                builder: (_) {
                                  return AlertDialog(
                                    title: const Text("Comentario"),
                                    content: TextField(
                                      controller: ctrl,
                                      maxLines: 3,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancelar"),
                                      ),

                                      ElevatedButton(
                                        onPressed: () async {
                                          final res = await _pedidosService.agregarProducto(
                                            idPedido: widget.idPedido,
                                            idDetalle: idDetalle,
                                            idProducto: item["id_producto"] == null
                                                ? null
                                                : _toInt(item["id_producto"]),
                                            idPlatillo: item["id_platillo"] == null
                                                ? null
                                                : _toInt(item["id_platillo"]),
                                            cantidad: 0,
                                            comentario: ctrl.text,
                                          );

                                          if (res == null || res['success'] != true) {
                                            await _mostrarError(
                                              res?["message"]?.toString() ??
                                                  res?["error"]?.toString() ??
                                                  "No se pudo guardar el comentario",
                                            );
                                            return;
                                          }

                                          if (!mounted) return;

                                          Navigator.pop(context);
                                          await _cargarPedido();
                                        },
                                        child: const Text("Guardar"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          if ((item["comentario"] ?? "").toString().isNotEmpty)
                            Expanded(
                              child: Text(
                                item["comentario"],
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "\$${calcularTotal().toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: confirmarPedido,
            child: const Text("Confirmar pedido"),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa ${widget.idMesa}"),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: ProductosGridWidget(
              onProductoSeleccionado: agregarProducto,
            ),
          ),

          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade100,
              child: resumenPedido(),
            ),
          ),
        ],
      ),
    );
  }
}