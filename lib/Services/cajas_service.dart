import 'dart:convert';
import 'package:flutter/cupertino.dart';
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
    try {
      final url = Uri.parse('$_baseUrl/cajas_crear.php');

      print('URL crearCaja: $url');

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_empleado': idEmpleado,
          'saldo_base': saldoBase,
          'nequi': nequi,
          'daviplata': daviplata,
          'bancolombia': bancolombia,
          'observaciones': observaciones,
        }),
      );

      print('Status Code crearCaja: ${res.statusCode}');
      print('Response Body crearCaja: ${res.body}');

      if (res.statusCode != 200) {
        print('Error HTTP crearCaja: ${res.statusCode}');
        return false;
      }

      try {
        final data = jsonDecode(res.body);

        print('JSON decodificado crearCaja: $data');

        if (data['success'] == true) {
          return true;
        } else {
          print('Error API crearCaja: ${data['error'] ?? data['message'] ?? 'Sin mensaje'}');
          return false;
        }
      } catch (e) {
        print('Error al convertir respuesta a JSON crearCaja: $e');
        print('Respuesta NO JSON recibida: ${res.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al conectar con crearCaja: $e');
      return false;
    }
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

  Future<Map<String, dynamic>> cerrarCaja({
    required int idCaja,
    required int idEmpleado,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/caja_cerrar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_caja': idCaja,
        'id_empleado': idEmpleado,
      }),
    );

    // 👇 DEBUG CLAVE
    debugPrint('RESPUESTA RAW cerrarCaja: ${res.body}');

    try {
      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Respuesta inválida del servidor',
        'raw': res.body,
      };
    }
  }

  Future<Map<String, dynamic>> obtenerVentasPorCaja(int idCaja) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/ventas_por_caja.php?id_caja=$idCaja'),
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Error HTTP ${res.statusCode}',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al consultar ventas: $e',
      };
    }
  }

  Future<Map<String, dynamic>> obtenerGastosPorCaja(int idCaja) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/gastos_por_caja.php?id_caja=$idCaja'),
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Error HTTP ${res.statusCode}',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al consultar gastos: $e',
      };
    }
  }

  Future<Map<String, dynamic>> obtenerCajasFinalizadas() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/cajas_finalizadas.php'),
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Error HTTP ${res.statusCode}',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al consultar cajas finalizadas: $e',
      };
    }
  }

  Future<Map<String, dynamic>> obtenerDetalleVenta(int idVenta) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/detalle_venta.php?id_venta=$idVenta'),
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Error HTTP ${res.statusCode}',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al consultar detalle de venta: $e',
      };
    }
  }

  Future<Map<String, dynamic>> anularVenta({
    required int idVenta,
    String motivo = 'Anulación desde caja',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/venta_anular.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_venta': idVenta,
          'motivo': motivo,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al anular venta: $e',
      };
    }
  }

  Future<Map<String, dynamic>> actualizarDetalleVenta({
    required int idVenta,
    required double propina,
    required List<Map<String, dynamic>> detalles,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/venta_actualizar_detalle.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_venta': idVenta,
          'propina': propina,
          'detalles': detalles,
        }),
      );

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al actualizar venta: $e',
      };
    }
  }

  Future<Map<String, dynamic>> anularGasto({
    required int idGasto,
    String motivo = 'Anulación desde caja',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/gasto_anular.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_gasto': idGasto,
          'motivo': motivo,
        }),
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Error HTTP ${res.statusCode}',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al anular gasto: $e',
      };
    }
  }
}