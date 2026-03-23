import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/mesas_service.dart';
import 'package:panaderia_nicol_pos/Services/pedidos_service.dart';
import 'pedidos_screen.dart';
import 'package:panaderia_nicol_pos/screens/ventas_screen.dart';

class SalonScreen extends StatefulWidget {

  final int idUsuario;

  const SalonScreen({
    super.key,
    required this.idUsuario,
  });

  @override
  State<SalonScreen> createState() => _SalonScreenState();
}

class _SalonScreenState extends State<SalonScreen> {

  final MesasService _mesasService = MesasService();
  final PedidosService _pedidosService = PedidosService();

  List<Map<String,dynamic>> mesas = [];

  Timer? refresco;

  bool cargando = true;

  @override
  void initState() {
    super.initState();

    _cargarDatos();

    refresco = Timer.periodic(
      const Duration(seconds:2), // 🔥 más rápido
          (timer){
        if(!mounted){
          timer.cancel();
          return;
        }
        _actualizarEstadoMesas();
      },
    );
  }

  @override
  void dispose() {
    refresco?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {

    final res = await _mesasService.obtenerMesas();

    if(res['success'] == true){
      mesas = List<Map<String,dynamic>>.from(res['data']);
    }

    await _actualizarEstadoMesas();

    if(!mounted) return;

    setState(() {
      cargando = false;
    });
  }

  Future<void> _actualizarEstadoMesas() async {

    final res = await _pedidosService.obtenerPedidosActivos();

    if(res == null || res['success'] != true) return;

    List pedidos = res['data'];

    /// 🔥 Convertimos correctamente a int
    Set<int> mesasOcupadas = pedidos
        .where((p) => int.parse(p['estado'].toString()) == 2) // 🔥 FILTRO CLAVE
        .map<int>((p) => int.parse(p['id_mesa'].toString()))
        .toSet();

    if(!mounted) return;

    setState(() {

      for(var mesa in mesas){

        int idMesa = int.parse(mesa['id'].toString());

        mesa['estado'] = mesasOcupadas.contains(idMesa) ? 2 : 1;

      }

    });
  }

  Future<void> _editarPedido(Map mesa) async {

    final res = await _pedidosService.obtenerPedidoMesa(
      idMesa: mesa['id'],
    );

    if(res == null || res['success'] != true){
      return;
    }

    int idPedido = res['pedido']['id'];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedidoScreen(
          idMesa: mesa['id'],
          idPedido: idPedido,
          idEmpleado: widget.idUsuario,
        ),
      ),
    );

    /// 🔥 IMPORTANTE: refrescar SIEMPRE
    await _actualizarEstadoMesas();
  }

  Future<void> _abrirFacturacion(Map mesa) async {
    int idMesa = mesa['id'];

    final resPedido = await _pedidosService.obtenerPedidoMesa(
      idMesa: idMesa,
    );
    if (resPedido == null || resPedido['success'] != true) return;

    int idPedido = resPedido['pedido']['id'];

    final resDetalles = await _pedidosService.obtenerDetallesPedido(
      idPedido: idPedido,
    );
    if (resDetalles == null || resDetalles['success'] != true) return;

    final detalles = resDetalles['data'] ?? [];

    double total = 0;
    for (var d in detalles) {
      double precio = double.parse(d["precio"].toString());
      double cantidad = double.parse(d["cantidad"].toString());
      total += precio * cantidad;
    }

    final result = await showDialog(
      context: context,
      builder: (_) => ConfirmarVentaDialog(
        total: total,
      ),
    );

    if (result != null) {

      print("VENTA CONFIRMADA: $result");

      /// 🔥 FINALIZAR PEDIDO (estado = 3)
      await _pedidosService.finalizarPedido(
        idPedido: idPedido,
      );

      /// 🔥 refrescar mesas
      await _actualizarEstadoMesas();
    }
  }

  Future<void> _abrirMesa(Map mesa) async {

    if(mesa['estado'] == 1){

      int idMesa = mesa['id'];

      final res = await _pedidosService.crearPedido(
        idMesa: idMesa,
        idEmpleado: widget.idUsuario,
      );

      if(res == null || res['success'] != true){
        return;
      }

      int idPedido = res['pedido']['id'];

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PedidoScreen(
            idMesa: idMesa,
            idPedido: idPedido,
            idEmpleado: widget.idUsuario,
          ),
        ),
      );

      /// 🔥 IMPORTANTE: SIEMPRE refrescar al volver
      await _actualizarEstadoMesas();

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ir a facturación mesa ${mesa['nombre']}"),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    if(cargando){
      return const Center(child:CircularProgressIndicator());
    }

    return GridView.builder(

      padding: const EdgeInsets.all(20),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),

      itemCount: mesas.length,

      itemBuilder: (_,i){

        return MesaCard(
          key: ValueKey(mesas[i]['id'].toString() + "_" + mesas[i]['estado'].toString()),
          mesa: mesas[i],
          onTap: _abrirMesa,
          onEdit: _editarPedido,
          onFacturar: _abrirFacturacion,
        );

      },
    );
  }
}

class MesaCard extends StatefulWidget {

  final Map mesa;
  final Function(Map) onTap;
  final Function(Map) onEdit;
  final Function(Map) onFacturar;

  const MesaCard({
    super.key,
    required this.mesa,
    required this.onTap,
    required this.onEdit,
    required this.onFacturar,
  });

  @override
  State<MesaCard> createState() => _MesaCardState();
}

class _MesaCardState extends State<MesaCard>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  bool cargando = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds:800),
    );

    controller.addStatusListener((status) {

      if(status == AnimationStatus.completed){

        setState(() {
          cargando = false;
        });

        widget.onEdit(widget.mesa);
      }

    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void iniciarCarga(){

    if(widget.mesa['estado'] != 2) return;

    setState(() {
      cargando = true;
    });

    controller.forward(from:0);
  }

  @override
  Widget build(BuildContext context) {

    int estado = widget.mesa['estado'];

    Color color = estado == 2
        ? Colors.red
        : Colors.green;

    return GestureDetector(

      onTap: () {

        if(widget.mesa['estado'] == 2){
          widget.onFacturar(widget.mesa);
        } else {
          widget.onTap(widget.mesa);
        }

      },

      onLongPress: (){
        iniciarCarga();
      },

      child: AnimatedContainer(

        duration: const Duration(milliseconds:300),

        decoration: BoxDecoration(

          color: color,

          borderRadius: BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0,4),
            )
          ],

        ),

        child: Stack(

          children: [

            Center(

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  const Icon(
                    Icons.table_bar,
                    color: Colors.white,
                    size:40,
                  ),

                  const SizedBox(height:10),

                  Text(
                    widget.mesa['nombre'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize:18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],

              ),
            ),

            if(cargando)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(

                    filter: ImageFilter.blur(
                      sigmaX: 5,
                      sigmaY: 5,
                    ),

                    child: Container(

                      color: Colors.black.withOpacity(0.4),

                      child: Center(

                        child: Stack(

                          alignment: Alignment.center,

                          children: [

                            AnimatedBuilder(

                              animation: controller,

                              builder: (_,__){

                                return SizedBox(
                                  width:70,
                                  height:70,
                                  child: CircularProgressIndicator(
                                    value: controller.value,
                                    strokeWidth:5,
                                    color: Colors.white,
                                  ),
                                );

                              },
                            ),

                            Container(
                              width:40,
                              height:40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size:20,
                              ),
                            )

                          ],

                        ),

                      ),

                    ),

                  ),
                ),
              )

          ],

        ),

      ),
    );
  }
}