import 'dart:convert';
import 'package:http/http.dart' as http;

class CajasService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerCajasAbiertas() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/cajas_listar_abiertas.php'),
    );

    return jsonDecode(res.body);
  }

  Future<bool> crearCaja({
    required int idEmpleado,
    required double saldoBase,
    required double nequi,
    required double daviplata,
    required double bancolombia,
    String observaciones = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/cajas_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_empleado': idEmpleado,
        'saldo_base': saldoBase,
        'nequi': nequi,
        'daviplata': daviplata,
        'bancolombia': bancolombia,
        'observaciones': observaciones,
      }),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  Future<bool> cancelarCaja(int id) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/cajas_cancelar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id}),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }
}