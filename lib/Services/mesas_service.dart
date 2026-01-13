import 'dart:convert';
import 'package:http/http.dart' as http;

class MesasService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerMesas({
    String buscar = '',
    String orden = 'id',
    String estado = '',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mesas_listar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buscar': buscar,
        'orden': orden,
        'direccion': direccion,
        'page': page,
        'limit': limit,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<bool> crearMesa({
    required String nombre,
    required String capacidad,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/mesas_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'capacidad': capacidad,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> actualizarMesa({
    required int id,
    required String nombre,
    required String capacidad,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/mesas_actualizar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'nombre': nombre,
        'capacidad': capacidad,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  /*
  Future<bool> cambiarEstadoMesa(int id, int estado) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mesas_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'estado': estado,
      }),
    );

    final data = jsonDecode(response.body);
    return data['success'] == true;
  }
   */
}