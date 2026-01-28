import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:panaderia_nicol_pos/screens/core/usuario_activo.dart';

class LoginService {
  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>?> login(String username, String password) async {
    final Map<String, String> requestBody = {
      'usuario': username,
      'contrasena': password,
    };

    final url = Uri.parse('$_baseUrl/login.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final Map<String, dynamic> responseData =
      json.decode(response.body);

      // ✅ GUARDAR USUARIO ACTIVO SI EL LOGIN ES EXITOSO
      if (responseData['success'] == true) {
        UsuarioActivo().id = responseData['id'];
        UsuarioActivo().nombre = responseData['nombre'];
        UsuarioActivo().usuario = responseData['usuario'];
        UsuarioActivo().rol = responseData['rol'];
      }

      return responseData;

    } catch (e) {
      print('Excepción al conectar con el servidor: $e');
      return {
        'success': false,
        'message':
        'No se pudo conectar al servidor. Verifica tu conexión.'
      };
    }
  }
}
