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

  double get efectivo => (_caja?['efectivo'] ?? 0).toDouble();
  double get nequi => (_caja?['nequi'] ?? 0).toDouble();
  double get daviplata => (_caja?['daviplata'] ?? 0).toDouble();

  // ───────────────── ACCIONES ─────────────────

  /// Activar una caja (uso interno)
  void activar(Map<String, dynamic> caja) {
    _caja = Map<String, dynamic>.from(caja);
  }

  /// Activar caja (API pública para UI)
  void activarCaja(Map<String, dynamic> caja) {
    activar(caja);
  }

  /// 🔄 ACTUALIZAR SALDOS EN TIEMPO REAL (POST-VENTA)
  void actualizarSaldos({
    double? efectivo,
    double? nequi,
    double? daviplata,
  }) {
    if (_caja == null) return;

    _caja = {
      ..._caja!,
      if (efectivo != null) 'efectivo': efectivo,
      if (nequi != null) 'nequi': nequi,
      if (daviplata != null) 'daviplata': daviplata,
    };
  }

  /// 🔄 ACTUALIZAR CAJA COMPLETA DESDE BACKEND
  void actualizarDesdeBackend(Map<String, dynamic> nuevaCaja) {
    if (_caja == null) return;

    _caja = {
      ..._caja!,
      ...nuevaCaja,
    };
  }

  /// Limpiar caja activa (cancelar / logout / cierre)
  void limpiar() {
    _caja = null;
  }
}
