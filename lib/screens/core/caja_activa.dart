class CajaActiva {
  // ───────────────── SINGLETON ─────────────────
  static final CajaActiva _instance = CajaActiva._internal();

  factory CajaActiva() => _instance;

  CajaActiva._internal();

  // ───────────────── ESTADO ─────────────────
  Map<String, dynamic>? _caja;

  // ───────────────── GETTERS ─────────────────
  Map<String, dynamic>? get caja => _caja;

  bool get tieneCajaActiva => _caja != null;

  int? get idCaja => _caja?['id'];

  // ───────────────── ACCIONES ─────────────────

  /// Activar una caja (uso interno)
  void activar(Map<String, dynamic> caja) {
    _caja = caja;
  }

  /// Activar caja (API pública para UI)
  void activarCaja(Map<String, dynamic> caja) {
    activar(caja);
  }

  /// Limpiar caja activa (cancelar / logout / cierre)
  void limpiar() {
    _caja = null;
  }
}