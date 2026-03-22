import 'dart:convert';
import 'package:http/http.dart' as http;

class PedidosService {

  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';

  /// CREAR PEDIDO
  Future<Map<String, dynamic>?> crearPedido({
    required int idMesa,
    required int idEmpleado,
  }) async {

    final url = Uri.parse('$_baseUrl/crear_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idMesa': idMesa,
        'idEmpleado': idEmpleado,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
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
    int? idProducto,
    int? idPlatillo,
    required double cantidad,
    String comentario = '',
  }) async {

    final url = Uri.parse('$_baseUrl/agregar_detalle_pedido.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idPedido': idPedido,
        'idProducto': idProducto,
        'idPlatillo': idPlatillo,
        'cantidad': cantidad,
        'comentario': comentario,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
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

  /// OBTENER PEDIDOS ACTIVOS (estado 1 o 2)
  Future<Map<String, dynamic>?> obtenerPedidosActivos() async {

    final url = Uri.parse('$_baseUrl/obtener_pedidos_activos.php');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return null;
    }

    return jsonDecode(response.body);
  }
}