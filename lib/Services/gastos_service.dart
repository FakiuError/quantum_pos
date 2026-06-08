import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:panaderia_nicol_pos/screens/core/caja_activa.dart';

class GastosService {
  final String _baseUrl = 'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<bool> crearGasto({
    required String descripcion,
    required double monto,
    required bool esCaja,
    required String metodo,
  }) async {
    try {
      final caja = CajaActiva();

      // Todo gasto, incluso si NO sale de caja, debe quedar asociado
      // a la caja diaria activa para que los reportes no repitan gastos.
      if (caja.idCaja == null || caja.idEmpleado == null) {
        debugPrint('❌ No hay caja activa para asociar el gasto');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/gastos_crear.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'descripcion': descripcion,
          'monto': monto,
          'esCaja': esCaja ? 1 : 0,
          'metodo': metodo,
          'id_caja': caja.idCaja,
          'id_empleado': caja.idEmpleado,
        }),
      );

      debugPrint('📥 STATUS CODE: ${response.statusCode}');
      debugPrint('📥 RESPONSE BODY: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('❌ Error HTTP');
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint('❌ Respuesta no es JSON válido');
        return false;
      }

      if (decoded['success'] == true) {
        debugPrint('✅ Gasto registrado correctamente');
        return true;
      }

      debugPrint('❌ ERROR BACKEND: ${decoded['error']}');
      return false;
    } catch (e, stack) {
      debugPrint('❌ EXCEPCIÓN EN SERVICE: $e');
      debugPrint(stack.toString());
      return false;
    }
  }
}
