import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProductosService {
  final String _baseUrl =
      'http://200.7.100.146/api-panaderia_nicol/pos';

  /// ───────────────── LISTAR PRODUCTOS ─────────────────
  Future<Map<String, dynamic>> obtenerProductos({
    String buscar = '',
    String estado = '1',
    String proveedorId = '',
    String categoriaId = '',
    String estadoInventario = '',
    String orden = 'id',
    String direccion = 'DESC',
    int page = 1,
    int limit = 25,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/productos_listar.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'buscar': buscar,
        'estado': estado,
        'proveedor_id': proveedorId,
        'categoria_id': categoriaId,
        'estado_inventario': estadoInventario,
        'orden': orden,
        'direccion': direccion,
        'page': page,
        'limit': limit,
      }),
    );

    if (res.statusCode != 200 || res.body.isEmpty) {
      return {
        'success': false,
        'data': [],
        'total': 0,
        'page': page,
        'limit': limit,
        'totalPages': 0,
      };
    }

    final data = jsonDecode(res.body);

    return data;
  }

  /// ───────────────── CAMBIAR ESTADO ─────────────────
  Future<bool> cambiarEstadoProducto(int id, int estado) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/productos_cambiar_estado.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'estado': estado}),
    );

    return jsonDecode(res.body)['success'] == true;
  }

  /// ───────────────── PROVEEDORES ─────────────────
  Future<List<Map<String, dynamic>>> obtenerProveedores() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/proveedores_listar_simple.php'),
    );

    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// ───────────────── CATEGORÍAS ─────────────────
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/categorias_listar_simple.php'),
    );

    final data = jsonDecode(res.body);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  Future<bool> crearProducto({
    required String codigo,
    required String nombre,
    required String stock,
    required String precio,
    required String precioCompra,
    required String proveedorId,
    required String categoriaId,
    File? imagen,
  }) async {
    final uri = Uri.parse('$_baseUrl/productos_crear.php');

    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'codigo': codigo,
      'nombre': nombre,
      'stock': stock,
      'precio': precio,
      'precio_compra': precioCompra,
      'proveedor_id': proveedorId,
      'categoria_id': categoriaId,
    });

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    final data = jsonDecode(respStr);
    return data['success'] == true;
  }

  Future<bool> actualizarProducto({
    required int id,
    required String codigo,
    required String nombre,
    required String stock,
    required String precio,
    required String precioCompra,
    required String proveedorId,
    required String categoriaId,
    File? imagen,
  }) async {
    final uri = Uri.parse('$_baseUrl/productos_actualizar.php');

    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'id': id.toString(),
      'codigo': codigo,
      'nombre': nombre,
      'stock': stock,
      'precio': precio,
      'precio_compra': precioCompra,
      'proveedor_id': proveedorId,
      'categoria_id': categoriaId,
    });

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    final data = jsonDecode(respStr);
    return data['success'] == true;
  }

  Future<Map<String, dynamic>?> obtenerProductoPorId(int id) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/productos_obtener_por_id.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
      }),
    );

    final data = jsonDecode(res.body);

    if (data['success'] == true && data['data'] != null) {
      return Map<String, dynamic>.from(data['data']);
    }

    return null;
  }

}
