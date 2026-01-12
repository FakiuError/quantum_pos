import 'dart:convert';
import 'package:http/http.dart' as http;

class UsuariosService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerUsuarios({
    String buscar = '',
    String rol = '',
    String estado = '',
    String orden = 'id',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios_listar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buscar': buscar,
        'rol': rol,
        'estado': estado,
        'orden': orden,
        'direccion': direccion,
        'page': page,
        'limit': limit,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<bool> cambiarEstadoUsuario(int id, int estado) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/usuarios_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'estado': estado,
      }),
    );

    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  Future<bool> crearUsuario({
    required String nombre,
    required String usuario,
    String telefono = '',
    required String pass,
    required String rol,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/usuarios_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'usuario': usuario,
        'telefono': telefono,
        'pass': pass,
        'rol': rol,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> actualizarUsuario({
    required int id,
    required String nombre,
    required String usuario,
    String telefono = '',
    required String pass,
    required String rol,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/usuarios_actualizar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'nombre': nombre,
        'usuario': usuario,
        'telefono': telefono,
        'pass': pass,
        'rol': rol,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }
}
