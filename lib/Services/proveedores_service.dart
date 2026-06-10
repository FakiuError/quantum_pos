import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    return Map<String, dynamic>.from(data);
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

  /// Productos activos asociados a un proveedor específico.
  /// Se usa para crear entradas de inventario desde la pantalla de proveedores.
  Future<Map<String, dynamic>> obtenerProductosProveedor({
    required int idProveedor,
    String buscar = '',
    int limit = 500,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/productos_por_proveedor.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_proveedor': idProveedor,
          'buscar': buscar,
          'limit': limit,
        }),
      );

      if (res.statusCode != 200 || res.body.trim().isEmpty) {
        return {
          'success': false,
          'data': [],
          'error': 'No se pudieron consultar los productos del proveedor',
        };
      }

      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded);
    } catch (e, stack) {
      debugPrint('❌ obtenerProductosProveedor: $e');
      debugPrint(stack.toString());
      return {
        'success': false,
        'data': [],
        'error': 'Error consultando productos del proveedor: $e',
      };
    }
  }

  /// Registra entrada + gasto + incremento de inventario en una sola transacción.
  Future<Map<String, dynamic>> registrarEntradaProveedor({
    required int idProveedor,
    required String proveedor,
    required int idCaja,
    required int idEmpleado,
    required bool esCaja,
    required String metodo,
    required double totalEntrada,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/entrada_proveedor_crear.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_proveedor': idProveedor,
          'proveedor': proveedor,
          'id_caja': idCaja,
          'id_empleado': idEmpleado,
          'esCaja': esCaja ? 1 : 0,
          'metodo': metodo,
          'total_entrada': totalEntrada,
          'items': items,
        }),
      );

      debugPrint('📥 entrada_proveedor_crear STATUS: ${res.statusCode}');
      debugPrint('📥 entrada_proveedor_crear BODY: ${res.body}');

      if (res.statusCode != 200 || res.body.trim().isEmpty) {
        return {
          'success': false,
          'error': 'Error HTTP registrando entrada a proveedor',
        };
      }

      final decoded = jsonDecode(res.body);
      return decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded);
    } catch (e, stack) {
      debugPrint('❌ registrarEntradaProveedor: $e');
      debugPrint(stack.toString());
      return {
        'success': false,
        'error': 'Error registrando entrada a proveedor: $e',
      };
    }
  }
}