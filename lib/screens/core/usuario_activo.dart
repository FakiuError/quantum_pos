class UsuarioActivo {
  static final UsuarioActivo _instance = UsuarioActivo._internal();
  factory UsuarioActivo() => _instance;
  UsuarioActivo._internal();

  int? id;
  String? nombre;
  String? usuario;
  String? rol;

  bool get estaLogueado => id != null;

  void limpiar() {
    id = null;
    nombre = null;
    usuario = null;
    rol = null;
  }
}