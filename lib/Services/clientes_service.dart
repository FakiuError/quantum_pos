import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';

class ClientesService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  Future<Map<String, dynamic>> obtenerClientes({
    String buscar = '',
    String estado = '1', // activos por defecto
    String orden = 'id',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/clientes_listar.php'),
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

  Future<bool> cambiarEstadoCliente(int id, int estado) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/clientes_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'estado': estado,
      }),
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  Future<bool> crearCliente({
    required String nombre,
    required String apellido,
    String identificacion = '',
    String telefono = '',
    String correo = '',
    required double deuda,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/clientes_crear.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'identificacion': identificacion,
        'telefono': telefono,
        'correo': correo,
        'deuda': deuda,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> actualizarCliente({
    required int id,
    required String nombre,
    required String apellido,
    String identificacion = '',
    String telefono = '',
    String correo = '',
    required double deuda,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/clientes_actualizar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'identificacion': identificacion,
        'telefono': telefono,
        'correo': correo,
        'deuda': deuda,
      }),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  Future<bool> registrarAbono({
    required int idCliente,
    required double monto,
    required String metodo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/deudas_abonar.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_cliente': idCliente,
          'valor': monto,
          'metodo': metodo,
        }),
      );

      final data = jsonDecode(res.body);
      return data['success'] == true;

    } catch (e) {
      return false;
    }
  }

  Future<bool> descargarReporteDeuda({
    required int idCliente,
    required DateTime desde,
    required DateTime hasta,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/deudas_reporte.php');

      final response = await http.post(
        url,
        body: jsonEncode({
          'id_cliente': idCliente,
          'desde': desde.toIso8601String(),
          'hasta': hasta.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) return false;

      print(response.body);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/reporte_deuda_${idCliente}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      await OpenFilex.open(file.path);
      return true;
    } catch (e) {
      return false;
    }
  }
}