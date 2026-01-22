import 'dart:convert';
import 'package:http/http.dart' as http;

class VentasService {
  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';
  Future<Map<String, dynamic>?> registrarVenta({
    required Map<String, dynamic> cliente,
    required List<Map<String, dynamic>> carrito,
    required double subtotal,
    required double descuento,
    required double total,
    required String metodoPago,
    required double pagaCon,
    required int idCaja,
    required int idEmpleado,
  }) async {
    final url = Uri.parse('$_baseUrl/ventas_registrar.php');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'cliente': cliente,
        'carrito': carrito,
        'subtotal': subtotal,
        'descuento': descuento,
        'total': total,
        'metodoPago': metodoPago,
        'pagaCon': pagaCon,
        'idCaja': idCaja,
        'idEmpleado': idEmpleado,
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }
    print(response.body);
    return jsonDecode(response.body);
  }
}