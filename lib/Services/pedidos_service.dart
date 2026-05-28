import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class PedidosService {

  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';

  /// CREAR PEDIDO
  Future<Map<String, dynamic>?> crearPedido({
    required int idMesa,
    required int idEmpleado,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/crear_pedido.php');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idMesa': idMesa,
          'idEmpleado': idEmpleado,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ HTTP ${response.statusCode}: ${response.body}");
        return {
          'success': false,
          'error': 'Error HTTP ${response.statusCode}',
        };
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': false,
        'error': 'Respuesta inválida del servidor',
      };

    } on TimeoutException {
      debugPrint("⏱️ Timeout creando pedido");
      return {
        'success': false,
        'error': 'Tiempo de espera agotado al crear el pedido',
      };

    } catch (e) {
      debugPrint("❌ Error crearPedido: $e");
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// BUSCAR PEDIDO ACTIVO DE UNA MESA
  Future<Map<String, dynamic>?> obtenerPedidoMesa({
    required int idMesa,
  }) async {

    final url = Uri.parse('$_baseUrl/obtener_pedido_mesa.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idMesa': idMesa,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /// OBTENER DETALLES DEL PEDIDO
  Future<Map<String, dynamic>?> obtenerDetallesPedido({
    required int idPedido,
  }) async {

    final url = Uri.parse('$_baseUrl/obtener_detalles_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idPedido': idPedido,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /// AGREGAR PRODUCTO AL PEDIDO
  Future<Map<String, dynamic>?> agregarProducto({
    required int idPedido,
    int? idDetalle,
    int? idProducto,
    int? idPlatillo,
    required double cantidad,
    String comentario = '',
  }) async {
    final url = Uri.parse('$_baseUrl/agregar_detalle_pedido.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idPedido': idPedido,
          'idDetalle': idDetalle,
          'idProducto': idProducto,
          'idPlatillo': idPlatillo,
          'cantidad': cantidad,
          'comentario': comentario,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          "❌ Error agregarProducto ${response.statusCode}: ${response.body}",
        );
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Exception agregarProducto: $e");
      return null;
    }
  }

  /// ELIMINAR DETALLE
  Future<Map<String, dynamic>?> eliminarDetalle({
    required int idDetalle,
  }) async {

    final url = Uri.parse('$_baseUrl/eliminar_detalle_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idDetalle': idDetalle,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /// CONFIRMAR PEDIDO (estado 1 -> 2)
  Future<Map<String, dynamic>?> confirmarPedido({
    required int idPedido,
  }) async {

    final url = Uri.parse('$_baseUrl/confirmar_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idPedido': idPedido,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /// FINALIZAR PEDIDO (estado -> 3)
  Future<Map<String, dynamic>?> finalizarPedido({
    required int idPedido,
  }) async {

    final url = Uri.parse('$_baseUrl/finalizar_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idPedido': idPedido,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }

  /// OBTENER PEDIDOS ACTIVOS
  Future<Map<String, dynamic>?> obtenerPedidosActivos() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/obtener_pedidos_activos.php?ts=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ HTTP ${response.statusCode}: ${response.body}");
        return null;
      }

      return jsonDecode(response.body);

    } on TimeoutException {
      debugPrint("⏱️ Timeout obteniendo pedidos activos");
      return null;

    } catch (e) {
      debugPrint("❌ Error obtenerPedidosActivos: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> cambiarMesaPedido({
    required int idPedido,
    required int idMesaOrigen,
    required int idMesaDestino,
  }) async {
    try {
      final url = Uri.parse("$_baseUrl/cambiar_mesa_pedido.php");

      debugPrint("========== CAMBIAR MESA PEDIDO ==========");
      debugPrint("URL: $url");
      debugPrint("ID PEDIDO: $idPedido");
      debugPrint("ID MESA ORIGEN: $idMesaOrigen");
      debugPrint("ID MESA DESTINO: $idMesaDestino");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id_pedido": idPedido,
          "id_mesa_origen": idMesaOrigen,
          "id_mesa_destino": idMesaDestino,
        }),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY RESPONSE: ${response.body}");
      debugPrint("========================================");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "success": false,
        "error": "Error HTTP ${response.statusCode}: ${response.body}",
      };
    } catch (e) {
      debugPrint("ERROR cambiarMesaPedido: $e");

      return {
        "success": false,
        "error": "Error cambiando mesa: $e",
      };
    }
  }

  Future<Map<String, dynamic>?> cambiarEstadoPedidoYProductos({
    required int idPedido,
    required int idMesa,
    required int estado,
  }) async {
    try {
      final url = Uri.parse("$_baseUrl/cambiar_estado_pedido_productos.php");

      debugPrint("========== CAMBIAR ESTADO PEDIDO ==========");
      debugPrint("URL: $url");
      debugPrint("ID PEDIDO: $idPedido");
      debugPrint("ID MESA: $idMesa");
      debugPrint("ESTADO: $estado");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "id_pedido": idPedido,
          "id_mesa": idMesa,
          "estado": estado,
        }),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY RESPONSE: ${response.body}");
      debugPrint("===========================================");

      if (response.body.isEmpty) {
        return {
          "success": false,
          "error": "Respuesta vacía del servidor. HTTP ${response.statusCode}",
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      return {
        "success": false,
        "error": data["error"] ??
            data["message"] ??
            "Error HTTP ${response.statusCode}",
      };
    } catch (e) {
      debugPrint("ERROR cambiarEstadoPedidoYProductos: $e");

      return {
        "success": false,
        "error": "Error cambiando estado del pedido: $e",
      };
    }
  }
}