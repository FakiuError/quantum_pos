import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class ProductosGridWidget extends StatefulWidget {

  final Function(Map<String, dynamic>) onProductoSeleccionado;

  const ProductosGridWidget({
    super.key,
    required this.onProductoSeleccionado,
  });

  @override
  State<ProductosGridWidget> createState() => _ProductosGridWidgetState();
}

class _ProductosGridWidgetState extends State<ProductosGridWidget>
    with SingleTickerProviderStateMixin {

  static const String baseUrl = "http://200.7.100.146";
  static const String _baseImagenUrl = 'http://200.7.100.146';
  static const String apiUrl =
      "http://200.7.100.146/api-panaderia_nicol/pos/obtener_productos_pos.php";

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> categorias = [];

  String categoriaSeleccionada = "";
  bool loading = true;

  final ScrollController scrollController = ScrollController();
  final TextEditingController buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  /// ===============================
  /// CARGAR PRODUCTOS
  /// ===============================

  Future<void> cargarProductos() async {

    setState(() {
      loading = true;
    });

    final uri = Uri.parse(apiUrl).replace(queryParameters: {
      "buscar": buscarController.text,
      "categoria": categoriaSeleccionada,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      if (data["success"]) {

        productos = List<Map<String, dynamic>>.from(data["productos"]);
        categorias = List<Map<String, dynamic>>.from(data["categorias"]);
      }
    }

    setState(() {
      loading = false;
    });
  }

  /// ===============================
  /// SKELETON LOADER
  /// ===============================

  Widget skeletonCard() {

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            height: 12,
            width: 80,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 6),

          Container(
            height: 10,
            width: 40,
            color: Colors.grey.shade300,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// ===============================
  /// TARJETA PRODUCTO
  /// ===============================

  Widget productoCard(Map<String, dynamic> p) {

    final imageUrl = "$baseUrl${p['url_imagen'] ?? ''}";

    return _HoverWidget(
      builder: (hovering) {

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: hovering
              ? (Matrix4.identity()..scale(1.04))
              : Matrix4.identity(),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onProductoSeleccionado(p);
            },
            child: Card(
              elevation: hovering ? 6 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  /// IMAGEN
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  /// NOMBRE
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Text(
                      p['nombre'],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  /// PRECIO
                  Text(
                    "\$${p['precio']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ===============================
  /// UI
  /// ===============================

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        /// ===============================
        /// BUSCADOR
        /// ===============================

        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: buscarController,
            decoration: InputDecoration(
              hintText: "Buscar producto...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) {
              cargarProductos();
            },
          ),
        ),

        /// ===============================
        /// GRID PRODUCTOS
        /// ===============================

        Expanded(
          child: loading
              ? GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: 10,
            itemBuilder: (_, __) => skeletonCard(),
          )
              : GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(10),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final p = productos[index];

              return AnimatedOpacity(
                opacity: 1,
                duration: Duration(
                    milliseconds: 200 + (index * 10)),
                child: productoCard(p),
              );
            },
          ),
        ),

        /// ===============================
        /// CATEGORÍAS POS
        /// ===============================

        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length,
            itemBuilder: (context, index) {

              final c = categorias[index];
              final selected =
                  categoriaSeleccionada == c['id'].toString();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(c['nombre']),
                  selected: selected,
                  selectedColor: Colors.orange,
                  onSelected: (v) {

                    setState(() {
                      categoriaSeleccionada =
                          c['id'].toString();
                    });

                    cargarProductos();
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }
}


/// =================================
/// HOVER WIDGET (PC)
// =================================

class _HoverWidget extends StatefulWidget {

  final Widget Function(bool hovering) builder;

  const _HoverWidget({
    required this.builder,
  });

  @override
  State<_HoverWidget> createState() => _HoverWidgetState();
}

class _HoverWidgetState extends State<_HoverWidget> {

  bool hovering = false;

  @override
  Widget build(BuildContext context) {

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: widget.builder(hovering),
    );
  }
}