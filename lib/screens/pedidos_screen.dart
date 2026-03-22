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

  /// ============================
  /// INIT
  /// ============================

  @override
  void initState() {
    super.initState();
    _cargarPedido();
  }

  /// ============================
  /// CARGAR PEDIDO EXISTENTE (CORREGIDO)
  /// ============================

  Future<void> _cargarPedido() async {

    final res = await _pedidosService.obtenerDetallesPedido(
      idPedido: widget.idPedido,
    );

    print("DETALLES PEDIDO: $res"); // DEBUG

    if (res != null && res['success'] == true) {

      final detalles = res['data']; // 🔥 IMPORTANTE

      if (detalles != null && detalles is List) {

        carrito = detalles.map<Map<String, dynamic>>((d) {

          return {
            "idDetalle": d["id"],
            "id_producto": d["id_producto"],
            "nombre": d["nombre"],
            "precio": double.parse(d["precio"].toString()),
            "cantidad": double.parse(d["cantidad"].toString()),
            "comentario": d["comentario"] ?? "",
          };

        }).toList();

      } else {
        carrito = [];
      }

    } else {
      carrito = [];
    }

    if(!mounted) return;

    setState(() {
      cargando = false;
    });

  }

  /// ============================
  /// AGREGAR PRODUCTO
  /// ============================

  Future agregarProducto(producto) async {

    final index = carrito.indexWhere(
          (item) => item["id_producto"] == producto["id"],
    );

    setState(() {

      if (index != -1) {
        carrito[index]["cantidad"]++;
      } else {
        carrito.add({
          "id_producto": producto["id"],
          "nombre": producto["nombre"],
          "precio": double.parse(producto["precio"].toString()),
          "cantidad": 1,
          "comentario": "",
        });
      }

    });

    await _pedidosService.agregarProducto(
      idPedido: widget.idPedido,
      idProducto: producto["id"],
      cantidad: 1,
    );
  }

  /// ============================
  /// TOTAL
  /// ============================

  double calcularTotal() {

    double total = 0;

    for (var item in carrito) {
      total += item["precio"] * item["cantidad"];
    }

    return total;
  }

  /// ============================
  /// CONFIRMAR
  /// ============================

  Future confirmarPedido() async {

    final res = await _pedidosService.confirmarPedido(
      idPedido: widget.idPedido,
    );

    if (res != null && res['success']) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido confirmado")),
      );

      Navigator.pop(context, true);
    }
  }

  /// ============================
  /// UI RESUMEN
  /// ============================

  Widget resumenPedido() {

    return Column(
      children: [

        /// LISTA
        Expanded(
          child: ListView.builder(
            itemCount: carrito.length,
            itemBuilder: (context, index) {

              final item = carrito[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [

                      /// HEADER
                      Row(
                        children: [

                          Expanded(
                            child: Text(
                              item["nombre"],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {

                              if(item["idDetalle"] != null){
                                await _pedidosService.eliminarDetalle(
                                  idDetalle: item["idDetalle"],
                                );
                              }

                              setState(() {
                                carrito.removeAt(index);
                              });
                            },
                          )
                        ],
                      ),

                      /// CONTROLES
                      Row(
                        children: [

                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () async {

                              if(item["cantidad"] > 1){

                                setState(() {
                                  item["cantidad"]--;
                                });

                                await _pedidosService.agregarProducto(
                                  idPedido: widget.idPedido,
                                  idProducto: item["id_producto"],
                                  cantidad: -1,
                                );

                              } else {

                                if(item["idDetalle"] != null){
                                  await _pedidosService.eliminarDetalle(
                                    idDetalle: item["idDetalle"],
                                  );
                                }

                                setState(() {
                                  carrito.removeAt(index);
                                });

                              }

                            },
                          ),

                          Text(
                            item["cantidad"].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {

                              setState(() {
                                item["cantidad"]++;
                              });

                              await _pedidosService.agregarProducto(
                                idPedido: widget.idPedido,
                                idProducto: item["id_producto"],
                                cantidad: 1,
                              );

                            },
                          ),

                          const Spacer(),

                          Text(
                            "\$${(item["precio"] * item["cantidad"]).toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      /// COMENTARIO
                      Row(
                        children: [

                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {

                              TextEditingController ctrl =
                              TextEditingController(text: item["comentario"]);

                              showDialog(
                                context: context,
                                builder: (_) {

                                  return AlertDialog(
                                    title: const Text("Comentario"),
                                    content: TextField(controller: ctrl),
                                    actions: [

                                      TextButton(
                                        onPressed: ()=> Navigator.pop(context),
                                        child: const Text("Cancelar"),
                                      ),

                                      ElevatedButton(
                                        onPressed: () async {

                                          setState(() {
                                            item["comentario"] = ctrl.text;
                                          });

                                          await _pedidosService.agregarProducto(
                                            idPedido: widget.idPedido,
                                            idProducto: item["id_producto"],
                                            cantidad: 0,
                                            comentario: ctrl.text,
                                          );

                                          Navigator.pop(context);
                                        },
                                        child: const Text("Guardar"),
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          if(item["comentario"] != "")
                            Expanded(
                              child: Text(
                                item["comentario"],
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        /// TOTAL
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL", style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
              Text("\$${calcularTotal().toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold))
            ],
          ),
        ),

        /// BOTON
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: confirmarPedido,
            child: const Text("Confirmar pedido"),
          ),
        )
      ],
    );
  }

  /// ============================
  /// BUILD
  /// ============================

  @override
  Widget build(BuildContext context) {

    if(cargando){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
          )
        ],
      ),
    );
  }
}