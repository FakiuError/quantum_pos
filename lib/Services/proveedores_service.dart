import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

class ProveedoresService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerProveedores({
    String buscar = '',
    String estado = '1', // activos por defecto
    String orden = 'id',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/proveedores_listar.php'),
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

  Future<bool> cambiarEstadoProveedor(int id, int estado) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/proveedores_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'estado': estado,
      }),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  Future<bool> crearProveedor({
    String nombre = '',
    String apellido = '',
    required String razon,
    String telefono = '',
    String correo = '',
    String direccion = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/proveedores_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'razon': razon,
        'telefono': telefono,
        'correo': correo,
        'direccion': direccion,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> actualizarProveedor({
    required int id,
    String nombre = '',
    String apellido = '',
    required String razon,
    String telefono = '',
    String correo = '',
    String direccion = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/proveedores_actualizar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'razon': razon,
        'telefono': telefono,
        'correo': correo,
        'direccion': direccion,
      }),
    );
    return jsonDecode(res.body)['success'] == true;
  }
}