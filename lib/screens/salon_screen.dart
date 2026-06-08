import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:panaderia_nicol_pos/Services/mesas_service.dart';
import 'package:panaderia_nicol_pos/Services/pedidos_service.dart';
import 'pedidos_screen.dart';
import 'package:panaderia_nicol_pos/screens/ventas_screen.dart';
import 'package:panaderia_nicol_pos/Services/ventas_service.dart';
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:panaderia_nicol_pos/utils/currency_utils.dart';

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

  bool actualizandoMesas = false;
  bool creandoPedido = false;
  bool creandoDomicilio = false;
  bool cambiandoMesa = false;
  bool cambiandoEstadoPedido = false;

  OverlayEntry? _notificacionEstadoEntry;

  final MesasService _mesasService = MesasService();
  final PedidosService _pedidosService = PedidosService();

  List<Map<String,dynamic>> mesas = [];

  List<Map<String, dynamic>> get mesasSalon {
    return mesas.where((mesa) {
      return !_esDomicilio(mesa);
    }).toList();
  }

  List<Map<String, dynamic>> get mesasDomicilio {
    return mesas.where((mesa) {
      final bool esDomicilio = _esDomicilio(mesa);
      final int estado = int.parse(mesa['estado'].toString());

      return esDomicilio && (estado == 2 || estado == 3);
    }).toList();
  }

  bool _esDomicilio(Map mesa) {
    final valor = mesa['es_domicilio'];

    return valor == true ||
        valor == 1 ||
        valor == '1' ||
        valor.toString().toLowerCase() == 'true';
  }

  Timer? refresco;

  bool cargando = true;

  @override
  void initState() {
    super.initState();

    _cargarDatos();
    _iniciarRefresco();
  }

  @override
  void dispose() {
    refresco?.cancel();
    _cerrarNotificacionEstado();
    super.dispose();
  }

  void _cerrarNotificacionEstado() {
    _notificacionEstadoEntry?.remove();
    _notificacionEstadoEntry = null;
  }

  void _mostrarNotificacionCambioEstado({
    required String mensaje,
    required Future<void> Function() onDeshacer,
  }) {
    _cerrarNotificacionEstado();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _NotificacionCambioEstadoPedido(
          mensaje: mensaje,
          onCerrar: () {
            if (_notificacionEstadoEntry == entry) {
              _cerrarNotificacionEstado();
            }
          },
          onDeshacer: () async {
            if (_notificacionEstadoEntry == entry) {
              _cerrarNotificacionEstado();
            }

            await onDeshacer();
          },
        );
      },
    );

    _notificacionEstadoEntry = entry;
    Overlay.of(context).insert(entry);
  }

  Future<void> _cambiarEstadoPedidoDesdeMesa({
    required Map mesa,
    required int nuevoEstado,
    bool mostrarNotificacion = true,
  }) async {
    if (cambiandoEstadoPedido) return;

    final int estadoMesa = int.parse(mesa['estado'].toString());
    final int idMesa = int.parse(mesa['id'].toString());

    if (estadoMesa != 2 && nuevoEstado == 3) {
      return;
    }

    cambiandoEstadoPedido = true;
    refresco?.cancel();

    try {
      final resPedido = await _pedidosService.obtenerPedidoMesa(
        idMesa: idMesa,
      );

      if (!mounted) return;

      if (resPedido == null || resPedido['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró un pedido activo para esta mesa."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pedido = resPedido['pedido'];
      final int idPedido = int.parse(pedido['id'].toString());
      final int estadoActualPedido = int.parse(pedido['estado'].toString());

      if (nuevoEstado == 3 && estadoActualPedido != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El pedido ya no está en preparación."),
            backgroundColor: Colors.orange,
          ),
        );

        await _refrescarMesasYEstados();
        return;
      }

      final resCambio = await _pedidosService.cambiarEstadoPedidoYProductos(
        idPedido: idPedido,
        idMesa: idMesa,
        estado: nuevoEstado,
      );

      if (!mounted) return;

      if (resCambio == null || resCambio['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resCambio?['error'] ??
                  resCambio?['message'] ??
                  "No se pudo cambiar el estado del pedido.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _refrescarMesasYEstados();

      if (!mounted) return;

      if (mostrarNotificacion && nuevoEstado == 3) {
        final String nombreMesa = mesa['nombre'].toString();

        _mostrarNotificacionCambioEstado(
          mensaje: "Pedido de $nombreMesa cambiado a ocupado.",
          onDeshacer: () async {
            await _deshacerCambioEstadoPedido(
              idPedido: idPedido,
              idMesa: idMesa,
              nombreMesa: nombreMesa,
            );
          },
        );
      }
    } catch (e) {
      debugPrint("❌ Error cambiando estado del pedido: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cambiando el estado del pedido."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      cambiandoEstadoPedido = false;

      if (mounted) {
        setState(() {});
        _iniciarRefresco();
      }
    }
  }

  Future<void> _deshacerCambioEstadoPedido({
    required int idPedido,
    required int idMesa,
    required String nombreMesa,
  }) async {
    if (cambiandoEstadoPedido) return;

    cambiandoEstadoPedido = true;
    refresco?.cancel();

    try {
      final resCambio = await _pedidosService.cambiarEstadoPedidoYProductos(
        idPedido: idPedido,
        idMesa: idMesa,
        estado: 2,
      );

      if (!mounted) return;

      if (resCambio == null || resCambio['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resCambio?['error'] ??
                  resCambio?['message'] ??
                  "No se pudo deshacer el cambio.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _refrescarMesasYEstados();

      if (!mounted) return;

      //ScaffoldMessenger.of(context).showSnackBar(
      //SnackBar(
//          backgroundColor: Colors.orange,
      //),
      //);
    } catch (e) {
      debugPrint("❌ Error deshaciendo cambio de estado: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error deshaciendo el cambio de estado."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      cambiandoEstadoPedido = false;

      if (mounted) {
        setState(() {});
        _iniciarRefresco();
      }
    }
  }

  Future<bool> _confirmarCambioMesa({
    required Map mesaOrigen,
    required Map mesaDestino,
  }) async {
    final String nombreOrigen = mesaOrigen['nombre'].toString();
    final String nombreDestino = mesaDestino['nombre'].toString();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar cambio de mesa"),
          content: Text(
            "¿Está seguro que desea cambiar el pedido de $nombreOrigen a $nombreDestino?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz),
              label: const Text("Sí, cambiar"),
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _cambiarPedidoDeMesa(
      Map mesaOrigen,
      Map mesaDestino,
      ) async {
    if (cambiandoMesa) return;

    final int idMesaOrigen = int.parse(mesaOrigen['id'].toString());
    final int idMesaDestino = int.parse(mesaDestino['id'].toString());

    final int estadoOrigen = int.parse(mesaOrigen['estado'].toString());
    final int estadoDestino = int.parse(mesaDestino['estado'].toString());

    if (idMesaOrigen == idMesaDestino) {
      return;
    }

    if (estadoOrigen != 2 && estadoOrigen != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solo puedes mover pedidos en preparación u ocupados."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (estadoDestino != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solo puedes cambiar el pedido a una mesa disponible."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_esDomicilio(mesaOrigen) != _esDomicilio(mesaDestino)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No puedes mezclar pedidos de salón con domicilios."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool confirmado = await _confirmarCambioMesa(
      mesaOrigen: mesaOrigen,
      mesaDestino: mesaDestino,
    );

    if (!confirmado) return;

    cambiandoMesa = true;
    refresco?.cancel();

    if (mounted) {
      setState(() {});
    }

    try {
      final resPedido = await _pedidosService.obtenerPedidoMesa(
        idMesa: idMesaOrigen,
      );

      if (!mounted) return;

      if (resPedido == null || resPedido['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se encontró un pedido activo para esta mesa."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pedido = resPedido['pedido'];
      final int idPedido = int.parse(pedido['id'].toString());
      final int estadoPedido = int.parse(pedido['estado'].toString());

      if (estadoPedido != 2 && estadoPedido != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El pedido ya no se puede mover porque cambió de estado."),
            backgroundColor: Colors.orange,
          ),
        );
        await _refrescarMesasYEstados();
        return;
      }

      final resCambio = await _pedidosService.cambiarMesaPedido(
        idPedido: idPedido,
        idMesaOrigen: idMesaOrigen,
        idMesaDestino: idMesaDestino,
      );

      if (!mounted) return;

      if (resCambio == null || resCambio['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resCambio?['error'] ??
                  resCambio?['message'] ??
                  "No se pudo cambiar el pedido de mesa.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      //ScaffoldMessenger.of(context).showSnackBar(
      //SnackBar(
      //content: Text(
      //"Pedido cambiado de ${mesaOrigen['nombre']} a ${mesaDestino['nombre']}.",
      //),
      //backgroundColor: Colors.green,
      //),
      //);

      await _refrescarMesasYEstados();
    } catch (e) {
      debugPrint("❌ Error cambiando pedido de mesa: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cambiando el pedido de mesa."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      cambiandoMesa = false;

      if (mounted) {
        setState(() {});
        _iniciarRefresco();
      }
    }
  }

  Future<String?> _pedirNombreDomicilio() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Crear domicilio"),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: "Dirección o nombre del domicilio",
              hintText: "Ej: Calle 10 # 5-20, Apto 302",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final texto = controller.text.trim();

              if (texto.isNotEmpty) {
                Navigator.pop(dialogContext, texto);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Crear"),
              onPressed: () {
                final texto = controller.text.trim();

                if (texto.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Debes ingresar una dirección o nombre"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, texto);
              },
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _crearDomicilio() async {
    if (creandoDomicilio) return;

    final nombreDomicilio = await _pedirNombreDomicilio();

    if (nombreDomicilio == null || nombreDomicilio.trim().isEmpty) {
      return;
    }

    creandoDomicilio = true;
    refresco?.cancel();

    if (mounted) {
      setState(() {});
    }

    try {
      final resMesa = await _mesasService.crearMesaDomicilio(
        nombre: nombreDomicilio.trim(),
      );

      if (!mounted) return;

      if (resMesa == null || resMesa['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resMesa?['error'] ?? '❌ Error al crear domicilio'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final mesa = Map<String, dynamic>.from(resMesa['mesa']);
      final int idMesa = int.parse(mesa['id'].toString());

      final resPedido = await _pedidosService.crearPedido(
        idMesa: idMesa,
        idEmpleado: UsuarioActivo().id!,
      );

      if (!mounted) return;

      if (resPedido == null || resPedido['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resPedido?['error'] ?? '❌ Error al crear pedido domicilio'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final int idPedido = int.parse(resPedido['pedido']['id'].toString());

      if (!mounted) return;

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

      if (!mounted) return;

      await _refrescarMesasYEstados();

    } catch (e) {
      debugPrint("❌ Error creando domicilio: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error creando domicilio. Revisa conexión con el servidor.'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      creandoDomicilio = false;

      if (mounted) {
        setState(() {});
        _iniciarRefresco();
      }
    }
  }

  void _iniciarRefresco() {
    refresco?.cancel();

    refresco = Timer.periodic(
      const Duration(seconds: 6),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        _refrescarMesasYEstados();
      },
    );
  }

  Future<void> _refrescarMesasYEstados() async {
    if (actualizandoMesas) return;

    actualizandoMesas = true;

    try {
      final resMesas = await _mesasService.obtenerMesasSalon();

      if (!mounted) return;

      if (resMesas == null || resMesas['success'] != true) return;

      final List<Map<String, dynamic>> nuevasMesas =
      List<Map<String, dynamic>>.from(resMesas['data'] ?? []);

      final resPedidos = await _pedidosService.obtenerPedidosActivos();

      if (!mounted) return;

      if (resPedidos == null || resPedidos['success'] != true) return;

      final List pedidos = resPedidos['data'] ?? [];

      Map<int, Map<String, dynamic>> infoMesaPedidoMap = {};

      for (var p in pedidos) {
        final int idMesa = int.parse(p['id_mesa'].toString());
        final int estadoPedido = int.parse(p['estado'].toString());

        final String nombreEmpleado =
        (p['nombre_empleado'] ?? p['empleado'] ?? p['usuario'] ?? '').toString();

        final infoActual = infoMesaPedidoMap[idMesa];
        final int? estadoActual = infoActual == null
            ? null
            : int.tryParse(infoActual['estado'].toString());

        if (estadoPedido == 3 || estadoActual == null || estadoActual != 3) {
          if (estadoPedido == 2 || estadoPedido == 3) {
            infoMesaPedidoMap[idMesa] = {
              'estado': estadoPedido,
              'atendido_por': nombreEmpleado,
            };
          }
        }
      }

      for (var mesa in nuevasMesas) {
        final int idMesa = int.parse(mesa['id'].toString());

        final infoPedido = infoMesaPedidoMap[idMesa];

        if (infoPedido != null) {
          mesa['estado'] = int.parse(infoPedido['estado'].toString());
          mesa['atendido_por'] = infoPedido['atendido_por'] ?? '';
        } else {
          mesa['estado'] = 1;
          mesa['atendido_por'] = '';
        }
      }

      if (!mounted) return;

      setState(() {
        mesas = nuevasMesas;
      });

      await _mesasService.sincronizarEstadoMesas(mesas);

    } catch (e) {
      debugPrint("❌ Error refrescando mesas y estados: $e");
    } finally {
      actualizandoMesas = false;
    }
  }

  Future<void> _cargarDatos() async {
    await _refrescarMesasYEstados();

    if (!mounted) return;

    setState(() {
      cargando = false;
    });
  }

  Future<void> _actualizarEstadoMesas() async {
    if (actualizandoMesas) return;

    actualizandoMesas = true;

    try {
      final res = await _pedidosService.obtenerPedidosActivos();

      if (!mounted) return;

      if (res == null || res['success'] != true) return;

      List pedidos = res['data'] ?? [];

      Map<int, int> estadoMesaMap = {};

      for (var p in pedidos) {
        int idMesa = int.parse(p['id_mesa'].toString());
        int estadoPedido = int.parse(p['estado'].toString());

        // Prioridad: estado 3 > estado 2
        if (estadoPedido == 3) {
          estadoMesaMap[idMesa] = 3;
        } else if (estadoPedido == 2 && estadoMesaMap[idMesa] != 3) {
          estadoMesaMap[idMesa] = 2;
        }
      }

      if (!mounted) return;

      setState(() {
        for (var mesa in mesas) {
          int idMesa = int.parse(mesa['id'].toString());
          bool esDomicilio = _esDomicilio(mesa);

          int? nuevoEstado = estadoMesaMap[idMesa];

          if (nuevoEstado != null) {
            mesa['estado'] = nuevoEstado;
          } else {
            if (esDomicilio) {
              mesa['estado'] = 1;
            } else {
              mesa['estado'] = 1;
            }
          }
        }
      });

      await _mesasService.sincronizarEstadoMesas(mesas);

    } catch (e) {
      debugPrint("❌ Error actualizando estado de mesas: $e");
    } finally {
      actualizandoMesas = false;
    }
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
          idEmpleado: UsuarioActivo().id!,
        ),
      ),
    );

    await _refrescarMesasYEstados();
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
        subtotal: total,
        descuento: 0,
        total: total,
        items: List<Map<String, dynamic>>.from(detalles),
      ),
    );

    if (result != null) {

      print("VENTA CONFIRMADA: $result");

      final cliente = Map<String, dynamic>.from(result['cliente']);
      final String metodoPago = result['metodo_pago'];
      final double propina =
          CurrencyUtils.parse(result['propina_valor']);

      final double totalFinal =
          CurrencyUtils.parse(result['total_con_propina']) > 0 ? CurrencyUtils.parse(result['total_con_propina']) : total;

      final double pagaCon =
          CurrencyUtils.parse(result['paga_con'] ?? totalFinal);

      final double cambio = metodoPago == 'efectivo'
          ? (pagaCon - totalFinal)
          : 0;

      final DateTime fechaHora = DateTime.now();

      final response = await VentasService().registrarVenta(
        cliente: cliente,
        carrito: List<Map<String, dynamic>>.from(detalles),
        subtotal: total,
        descuento: 0,
        propina: propina,
        total: totalFinal,
        metodoPago: metodoPago,
        pagaCon: pagaCon,
        idCaja: CajaActiva().idCaja!,
        idEmpleado: UsuarioActivo().id!,
      );

      if (response == null || response['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al registrar la venta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      int numeroFactura = 0;

      if (response['venta'] != null &&
          response['venta']['id'] != null) {
        numeroFactura = response['venta']['id'];
      } else if (response['id_venta'] != null) {
        numeroFactura = response['id_venta'];
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => DialogoVentaFinal(
          numeroFactura: numeroFactura,
          cliente: '${cliente['nombre']} ${cliente['apellido']}',
          identificacion: cliente['identificacion'] ?? 'N/A',
          usuario: UsuarioActivo().nombre!,
          fechaHora: fechaHora,
          subtotal: total,
          descuento: 0,
          propina: propina,
          total: totalFinal,
          cambio: cambio,
          items: List<Map<String, dynamic>>.from(detalles),
        ),
      );

      await _pedidosService.finalizarPedido(
        idPedido: idPedido,
      );

      await _refrescarMesasYEstados();
    }
  }

  Future<void> _abrirMesa(Map mesa) async {
    if (creandoPedido) return;

    final int estado = int.parse(mesa['estado'].toString());

    if (estado != 1) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ir a facturación mesa ${mesa['nombre']}"),
        ),
      );
      return;
    }

    creandoPedido = true;
    refresco?.cancel();

    try {
      final int idMesa = int.parse(mesa['id'].toString());

      final res = await _pedidosService.crearPedido(
        idMesa: idMesa,
        idEmpleado: UsuarioActivo().id!,
      );

      if (!mounted) return;

      if (res == null || res['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['error'] ?? '❌ Error al crear pedido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final int idPedido = int.parse(res['pedido']['id'].toString());

      if (!mounted) return;

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

      if (!mounted) return;

      await _refrescarMesasYEstados();

    } catch (e) {
      debugPrint("❌ Error abriendo mesa: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error abriendo mesa. Revisa conexión con el servidor.'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      creandoPedido = false;

      if (mounted) {
        _iniciarRefresco();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(
                  icon: Icon(Icons.table_bar),
                  text: "Salón",
                ),
                Tab(
                  icon: Icon(Icons.delivery_dining),
                  text: "Domicilios",
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              children: [
                _gridMesas(
                  mesasFiltradas: mesasSalon,
                  esVistaDomicilio: false,
                ),

                _vistaDomicilios(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridMesas({
    required List<Map<String, dynamic>> mesasFiltradas,
    required bool esVistaDomicilio,
  }) {
    if (mesasFiltradas.isEmpty) {
      return Center(
        child: Text(
          esVistaDomicilio
              ? "No hay domicilios activos"
              : "No hay mesas disponibles",
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.95,
      ),
      itemCount: mesasFiltradas.length,
      itemBuilder: (_, i) {
        final mesa = mesasFiltradas[i];

        return MesaCard(
          key: ValueKey(
            "${mesa['id']}_${mesa['estado']}_${_esDomicilio(mesa)}",
          ),
          mesa: mesa,
          esDomicilio: _esDomicilio(mesa),
          onTap: _abrirMesa,
          onEdit: _editarPedido,
          onFacturar: _abrirFacturacion,
          onCambiarMesa: _cambiarPedidoDeMesa,
          onAvanzarEstado: (mesa) {
            _cambiarEstadoPedidoDesdeMesa(
              mesa: mesa,
              nuevoEstado: 3,
            );
          },
        );
      },
    );
  }

  Widget _vistaDomicilios() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Domicilios activos",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: creandoDomicilio ? null : _crearDomicilio,
                icon: creandoDomicilio
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
                    : const Icon(Icons.add_location_alt),
                label: Text(
                  creandoDomicilio ? "Creando..." : "Crear domicilio",
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 45),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _gridMesas(
            mesasFiltradas: mesasDomicilio,
            esVistaDomicilio: true,
          ),
        ),
      ],
    );
  }
}




class MesaCard extends StatefulWidget {
  final Map mesa;
  final bool esDomicilio;
  final Function(Map) onTap;
  final Function(Map) onEdit;
  final Function(Map) onFacturar;
  final Function(Map, Map) onCambiarMesa;
  final Function(Map) onAvanzarEstado;

  const MesaCard({
    super.key,
    required this.mesa,
    required this.esDomicilio,
    required this.onTap,
    required this.onEdit,
    required this.onFacturar,
    required this.onCambiarMesa,
    required this.onAvanzarEstado,
  });

  @override
  State<MesaCard> createState() => _MesaCardState();
}

class _MesaCardState extends State<MesaCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool cargando = false;
  String accionCarga = '';

  static const String svgDisponible = '''
<svg fill="#000000" height="200px" width="200px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
<g>
<path d="M0,228.174v50.087c0,9.223,7.473,16.696,16.696,16.696h16.696v150.261c0,9.223,7.473,16.696,16.696,16.696h66.783 c9.223,0,16.696-7.473,16.696-16.696V294.957h244.87v150.261c0,9.223,7.473,16.696,16.696,16.696h66.783 c9.223,0,16.696-7.473,16.696-16.696V294.957h16.696c9.223,0,16.696-7.473,16.696-16.696v-50.087H0z"></path>
<path d="M443.679,59.788c-2.728-5.914-8.646-9.701-15.157-9.701H83.478c-6.511,0-12.429,3.788-15.157,9.701L6.016,194.783h499.967 L443.679,59.788z"></path>
</g>
</svg>
''';

  static const String svgPreparacion = '''
<svg fill="#000000" viewBox="0 -2.89 122.88 122.88" version="1.1" xmlns="http://www.w3.org/2000/svg">
<g>
<path d="M36.82,107.86L35.65,78.4l13.25-0.53c5.66,0.78,11.39,3.61,17.15,6.92l10.29-0.41c4.67,0.1,7.3,4.72,2.89,8 c-3.5,2.79-8.27,2.83-13.17,2.58c-3.37-0.03-3.34,4.5,0.17,4.37c1.22,0.05,2.54-0.29,3.69-0.34c6.09-0.25,11.06-1.61,13.94-6.55 l1.4-3.66l15.01-8.2c7.56-2.83,12.65,4.3,7.23,10.1c-10.77,8.51-21.2,16.27-32.62,22.09c-8.24,5.47-16.7,5.64-25.34,1.01 L36.82,107.86z M29.74,62.97h91.9c0.68,0,1.24,0.57,1.24,1.24v5.41c0,0.67-0.56,1.24-1.24,1.24h-91.9 c-0.68,0-1.24-0.56-1.24-1.24v-5.41C28.5,63.53,29.06,62.97,29.74,62.97z M79.26,11.23 c25.16,2.01,46.35,23.16,43.22,48.06l-93.57,0C25.82,34.23,47.09,13.05,72.43,11.2V7.14l-4,0c-0.7,0-1.28-0.58-1.28-1.28V1.28 c0-0.7,0.57-1.28,1.28-1.28h14.72c0.7,0,1.28,0.58,1.28,1.28v4.58c0,0.7-0.58,1.28-1.28,1.28h-3.89L79.26,11.23z M0,77.39l31.55-1.66l1.4,35.25L1.4,112.63L0,77.39z"></path>
</g>
</svg>
''';

  static const String svgOcupada = '''
<svg fill="#000000" version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
<g>
<circle cx="25.3" cy="45.2" r="8.2"></circle>
<path d="M36.9,86.7H23.2V76.5l-7.1-12.1c-0.3-0.5-0.1-1.1,0.3-1.4c0.5-0.3,1.1-0.1,1.4,0.3l8.2,14c0.6,1,1.7,1.8,3,1.8h14 c2,0,3.6-1.7,3.6-3.6c0-2-1.7-3.6-3.6-3.6l-11.8,0.1L22,56.4c-0.7-1.2-2.1-1.9-3.7-1.9c-0.2,0-0.8,0.1-1,0.1s-0.6,0.1-0.8,0.2 C9.7,57.1,4.3,67.9,4.3,79.1c-0.1,3.4,0,6.2,0.2,8.9c-0.3,3.2,1.7,6.4,4.8,7.6c0.8,0.3,1.7,0.5,2.5,0.5h20.5v19.2 c0,2.6,2.1,4.6,4.6,4.6c2.6,0,4.6-2.1,4.6-4.6V91.4c0-1.2-0.5-2.4-1.4-3.3C39.2,87.2,38,86.7,36.9,86.7z"></path>
<path d="M78.5,78.2h0.2v-2.6h-0.2h-2.7c-1.7-5.5-5.9-9.6-11.1-10.2c0.2-0.3,0.4-0.6,0.4-1c0-0.8-0.7-1.5-1.5-1.5 c-0.8,0-1.5,0.7-1.5,1.5c0,0.4,0.1,0.7,0.4,1c-5.2,0.6-9.4,4.7-11.1,10.2h-2.7h-0.2v2.6h0.2H78.5z"></path>
<rect x="28.7" y="80.9" width="69.4" height="3.7"></rect>
<circle cx="101.5" cy="46" r="8.2"></circle>
<path d="M122.6,79.1c0-11.2-5.4-22.1-12.2-24.3c-0.2-0.1-0.6-0.1-0.8-0.2c-0.2-0.1-0.8-0.1-1-0.1c-1.7,0-3,0.7-3.7,1.9l-9.3,15.8 L83.8,72c-1.9,0-3.6,1.6-3.6,3.6c0,1.9,1.6,3.6,3.6,3.6h14c1.3,0,2.4-0.8,3-1.8l8.2-14c0.3-0.4,0.9-0.6,1.4-0.3 c0.4,0.3,0.6,0.9,0.3,1.4l-7.1,12.1v10.2H90c-1.1,0-2.3,0.5-3.3,1.5c-0.9,0.8-1.4,2.1-1.4,3.3v23.9c0,2.6,2,4.6,4.6,4.6 c2.6,0,4.6-2,4.6-4.6V96.1h20.5c0.8,0,1.7-0.2,2.5-0.5c3.2-1.2,5.1-4.4,4.8-7.6C122.6,85.3,122.7,82.5,122.6,79.1z"></path>
</g>
</svg>
''';

  static const String svgEnCamino = '''
<svg fill="#000000" version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="-51.2 -51.2 614.40 614.40">
<g>
<path d="M119.467,413.867c-9.421,0-17.067,7.646-17.067,17.067c0,9.421,7.646,17.067,17.067,17.067s17.067-7.646,17.067-17.067 C136.533,421.513,128.887,413.867,119.467,413.867z"></path>
<path d="M119.467,379.733c-28.237,0-51.2,22.963-51.2,51.2c0,28.237,22.963,51.2,51.2,51.2s51.2-22.963,51.2-51.2 C170.667,402.697,147.703,379.733,119.467,379.733z M119.467,465.067c-18.825,0-34.133-15.309-34.133-34.133 s15.309-34.133,34.133-34.133s34.133,15.309,34.133,34.133S138.291,465.067,119.467,465.067z"></path>
<path d="M452.267,413.867c-9.421,0-17.067,7.646-17.067,17.067c0,9.421,7.646,17.067,17.067,17.067 c9.421,0,17.067-7.646,17.067-17.067C469.333,421.513,461.688,413.867,452.267,413.867z"></path>
<path d="M452.267,379.733c-28.237,0-51.2,22.963-51.2,51.2c0,28.237,22.963,51.2,51.2,51.2c28.237,0,51.2-22.963,51.2-51.2 C503.467,402.697,480.503,379.733,452.267,379.733z M452.267,465.067c-18.825,0-34.133-15.309-34.133-34.133 s15.309-34.133,34.133-34.133c18.825,0,34.133,15.309,34.133,34.133S471.091,465.067,452.267,465.067z"></path>
<path d="M497.374,342.861C484.617,328.337,465.109,320,443.87,320h-1.954c-7.185-25.37-25.156-46.157-49.382-56.909V214.34 l4.719,2.364c1.178,0.589,2.492,0.896,3.814,0.896h17.067c4.719,0,8.533-3.823,8.533-8.533v-51.2c0-4.71-3.814-8.533-8.533-8.533 h-17.067c-1.323,0-2.637,0.307-3.814,0.896l-17.067,8.533c-2.893,1.451-4.719,4.403-4.719,7.637h-76.8 c-4.719,0-8.533,3.823-8.533,8.533h-42.667V153.6c0-14.012-7.629-26.172-18.867-32.879c11.503-9.395,18.867-23.68,18.867-39.654 c0-28.237-22.963-51.2-51.2-51.2s-51.2,22.963-51.2,51.2c0,17.835,9.173,33.545,23.04,42.718 c-8.772,7.04-14.507,17.715-14.507,29.815v128c0,7.893,2.406,15.224,6.502,21.333h-23.569V192c0-4.71-3.814-8.533-8.533-8.533 H93.867v42.667c0,4.71-3.814,8.533-8.533,8.533H51.2c-4.719,0-8.533-3.823-8.533-8.533v-42.667H8.533 C3.814,183.467,0,187.29,0,192v119.467C0,316.177,3.814,320,8.533,320h4.745c-2.935,5.043-4.745,10.82-4.745,17.067v10.59 c0,6.92,3.703,13.517,9.899,17.647c7.177,4.779,9.37,14.336,4.992,21.76l-10.598,18.039c-3.763,5.009-5.146,11.349-3.78,17.493 c1.399,6.366,5.538,11.691,11.375,14.601c2.961,1.485,6.289,2.27,9.609,2.27H51.2c4.719,0,8.533-3.823,8.533-8.533 c0-32.939,26.803-59.733,59.733-59.733s59.733,26.795,59.733,59.733c0,4.71,3.814,8.533,8.533,8.533H384 c4.719,0,8.533-3.823,8.533-8.533c0-32.939,26.803-59.733,59.733-59.733c28.544,0,36.096,5.504,45.167,14.566 c2.449,2.449,6.118,3.174,9.301,1.852c3.192-1.323,5.265-4.437,5.265-7.885C512,366.498,506.94,353.749,497.374,342.861z"></path>
<rect x="59.733" y="183.467" width="17.067" height="34.133"></rect>
</g>
</svg>
''';

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        final String accionFinal = accionCarga;

        setState(() {
          cargando = false;
          accionCarga = '';
        });

        if (accionFinal == 'editar') {
          widget.onEdit(widget.mesa);
        } else if (accionFinal == 'avanzar_estado') {
          widget.onAvanzarEstado(widget.mesa);
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void iniciarCarga() {
    final int estado = int.parse(widget.mesa['estado'].toString());

    if (estado == 2) {
      setState(() {
        cargando = true;
        accionCarga = 'avanzar_estado';
      });

      controller.forward(from: 0);
      return;
    }

    if (estado == 3) {
      setState(() {
        cargando = true;
        accionCarga = 'editar';
      });

      controller.forward(from: 0);
      return;
    }
  }

  Color get colorEstado {
    final int estado = int.parse(widget.mesa['estado'].toString());

    if (estado == 3 && widget.esDomicilio) {
      return Colors.blue;
    }

    switch (estado) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String get textoEstado {
    final int estado = int.parse(widget.mesa['estado'].toString());

    if (estado == 3 && widget.esDomicilio) {
      return "En camino";
    }

    switch (estado) {
      case 3:
        return "Ocupada";
      case 2:
        return "En preparación";
      default:
        return "Disponible";
    }
  }

  String get svgEstado {
    final int estado = int.parse(widget.mesa['estado'].toString());

    if (estado == 3 && widget.esDomicilio) {
      return svgEnCamino;
    }

    switch (estado) {
      case 3:
        return svgOcupada;
      case 2:
        return svgPreparacion;
      default:
        return svgDisponible;
    }
  }

  String get atendidoPor {
    final valor = widget.mesa['atendido_por'] ??
        widget.mesa['nombre_empleado'] ??
        widget.mesa['empleado'] ??
        '';

    return valor.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final int estado = int.parse(widget.mesa['estado'].toString());
    final Color color = colorEstado;
    final bool mostrarAtendidoPor = estado == 2 || estado == 3;

    final Widget tarjeta = GestureDetector(
      onTap: () {
        if (widget.esDomicilio) {
          if (estado == 2) {
            widget.onEdit(widget.mesa);
          } else if (estado == 3) {
            widget.onFacturar(widget.mesa);
          }
          return;
        }

        if (estado == 3) {
          widget.onFacturar(widget.mesa);
        } else if (estado == 2) {
          widget.onEdit(widget.mesa);
        } else {
          widget.onTap(widget.mesa);
        }
      },
      onLongPress: () {
        iniciarCarga();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      svgEstado,
                      width: 46,
                      height: 46,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: 140,
                      child: Text(
                        widget.mesa['nombre'].toString(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        textoEstado,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (mostrarAtendidoPor) ...[
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 145,
                        child: Text(
                          atendidoPor.isEmpty
                              ? "Atendido por: Sin asignar"
                              : "Atendido por: $atendidoPor",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (cargando)
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
                              builder: (_, __) {
                                return SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    value: controller.value,
                                    strokeWidth: 5,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                accionCarga == 'avanzar_estado'
                                    ? Icons.published_with_changes
                                    : Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final bool puedeArrastrarse = estado == 2 || estado == 3;
    final bool puedeRecibirPedido = estado == 1;

    Widget contenido = tarjeta;

    if (puedeArrastrarse) {
      contenido = Draggable<Map>(
        data: widget.mesa,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Opacity(
              opacity: 0.85,
              child: tarjeta,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: tarjeta,
        ),
        child: tarjeta,
      );
    }

    return DragTarget<Map>(
      onWillAccept: (mesaOrigen) {
        if (mesaOrigen == null) return false;

        final int idOrigen = int.parse(mesaOrigen['id'].toString());
        final int idDestino = int.parse(widget.mesa['id'].toString());

        if (idOrigen == idDestino) return false;

        final int estadoOrigen = int.parse(mesaOrigen['estado'].toString());
        final int estadoDestino = int.parse(widget.mesa['estado'].toString());

        final bool origenValido = estadoOrigen == 2 || estadoOrigen == 3;
        final bool destinoValido = estadoDestino == 1;

        return origenValido && destinoValido;
      },
      onAccept: (mesaOrigen) {
        widget.onCambiarMesa(mesaOrigen, widget.mesa);
      },
      builder: (context, candidateData, rejectedData) {
        final bool resaltado = candidateData.isNotEmpty && puedeRecibirPedido;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: resaltado ? const EdgeInsets.all(5) : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: resaltado
                ? Border.all(
              color: Colors.black,
              width: 3,
            )
                : null,
          ),
          child: contenido,
        );
      },
    );
  }
}

class _NotificacionCambioEstadoPedido extends StatefulWidget {
  final String mensaje;
  final VoidCallback onCerrar;
  final Future<void> Function() onDeshacer;

  const _NotificacionCambioEstadoPedido({
    required this.mensaje,
    required this.onCerrar,
    required this.onDeshacer,
  });

  @override
  State<_NotificacionCambioEstadoPedido> createState() =>
      _NotificacionCambioEstadoPedidoState();
}

class _NotificacionCambioEstadoPedidoState
    extends State<_NotificacionCambioEstadoPedido>
    with TickerProviderStateMixin {
  late final AnimationController slideController;
  late final AnimationController progressController;
  late final Animation<Offset> slideAnimation;

  bool cerrando = false;
  bool deshaciendo = false;

  @override
  void initState() {
    super.initState();

    slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
    );

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    slideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: slideController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _iniciarSecuencia();
  }

  Future<void> _iniciarSecuencia() async {
    await slideController.forward();

    if (!mounted || cerrando || deshaciendo) return;

    await progressController.forward();

    if (!mounted || cerrando || deshaciendo) return;

    await _cerrarConAnimacion();
  }

  Future<void> _cerrarConAnimacion() async {
    if (cerrando) return;

    cerrando = true;

    if (mounted) {
      await slideController.reverse();
    }

    widget.onCerrar();
  }

  Future<void> _deshacer() async {
    if (deshaciendo || cerrando) return;

    setState(() {
      deshaciendo = true;
    });

    progressController.stop();

    await widget.onDeshacer();
  }

  @override
  void dispose() {
    slideController.dispose();
    progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      bottom: 24,
      child: SafeArea(
        child: SlideTransition(
          position: slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: progressController,
                    builder: (_, __) {
                      return SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          value: 1 - progressController.value,
                          strokeWidth: 3,
                          color: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.20),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      widget.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  TextButton(
                    onPressed: deshaciendo ? null : _deshacer,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                    ),
                    child: deshaciendo
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orangeAccent,
                      ),
                    )
                        : const Text(
                      "Deshacer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
