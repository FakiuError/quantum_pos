import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

class CategoriasService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerCategorias({
    String buscar = '',
    String estado = '1',
    String orden = 'id',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/categorias_listar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buscar': buscar,
        'estado': estado,
        'orden': orden,
        'direccion': direccion,
        'page': page,
        'limit': limit,
      }),
    );
    final data = jsonDecode(res.body);
    return data;
  }

  Future<bool> cambiarEstadoCategoria(int id, int estado) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/categorias_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'estado': estado,
      }),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  Future<bool> crearCategorias({
    required nombre,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/categorias_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> actualizarCategoria({
    required int id,
    required nombre,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/categorias_actualizar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'nombre': nombre,
      }),
    );
    return jsonDecode(res.body)['success'] == true;
  }
}