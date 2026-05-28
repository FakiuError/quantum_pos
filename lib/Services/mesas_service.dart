import 'dart:convert';
import 'package:flutter/cupertino.dart';
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

  Future<void> sincronizarEstadoMesas(List<Map<String, dynamic>> mesas) async {

    final url = Uri.parse('$_baseUrl/sync_mesas_estado.php');

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mesas': mesas.map((m) => {
          'id': m['id'],
          'estado': m['estado'],
        }).toList(),
      }),
    );
  }

  Future<Map<String, dynamic>?> obtenerMesasSalonDomicilios() async {
    try {

      final url = Uri.parse("$_baseUrl/mesas_salon_domicilios.php");

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data;
        }

      }

      return null;

    } catch (e) {
      print("Error obtenerMesasSalonDomicilios: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerMesasSalon() async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/mesas_obtener.php?ts=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Error HTTP ${response.statusCode}: ${response.body}");
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

    } catch (e) {
      debugPrint("❌ Error obteniendo mesas salón: $e");

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>?> crearMesaDomicilio({
    required String nombre,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/crear_mesa_domicilio.php');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
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

    } catch (e) {
      debugPrint("❌ Error crearMesaDomicilio: $e");

      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}