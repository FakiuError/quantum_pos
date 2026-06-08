import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReporteCajaPdfService {
  Future<String> generarReporteCajaDiario(Map<String, dynamic> reporte) async {
    final pdf = pw.Document();
    final caja = _map(reporte['caja']);
    final resumen = _map(reporte['resumen']);
    final metodos = _list(reporte['resumen_por_metodo']);
    final ventas = _list(reporte['ventas']);
    final productosVendidos = _list(reporte['productos_vendidos']);
    final gastosCaja = _list(reporte['gastos_caja']);
    final gastosNoCaja = _list(reporte['gastos_no_caja']);
    final inventario = _list(reporte['inventario']);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(26),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          _encabezado(caja, reporte),
          pw.SizedBox(height: 14),
          _tarjetasResumen(resumen),
          pw.SizedBox(height: 14),
          _seccionTitulo('Resumen por medio de pago'),
          _tablaMetodos(metodos),
          pw.SizedBox(height: 16),
          _seccionTitulo('Ventas asignadas a esta caja'),
          _tablaVentas(ventas),
          pw.SizedBox(height: 16),
          _seccionTitulo('Productos vendidos'),
          _tablaProductosVendidos(productosVendidos),
          pw.SizedBox(height: 16),
          _seccionTitulo('Gastos que salieron de caja'),
          _nota('Estos gastos sí disminuyen el saldo físico de la caja.'),
          _tablaGastos(gastosCaja),
          pw.SizedBox(height: 16),
          _seccionTitulo('Gastos no asociados a caja'),
          _nota('Estos gastos se muestran para análisis administrativo del turno, pero no disminuyen el saldo físico de la caja.'),
          _tablaGastos(gastosNoCaja),
          pw.SizedBox(height: 16),
          _seccionTitulo('Balance de inventario del turno'),
          _nota('Stock inicial estimado = stock final actual + vendido + bajas - entradas. Para tener inventario físico exacto, a futuro conviene crear un conteo diario de apertura y cierre.'),
          _tablaInventario(inventario),
        ],
      ),
    );

    final ruta = await crearRutaReporteCaja(caja);
    final file = File(ruta);
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file.path;
  }

  Future<String> crearRutaReporteCaja(Map<String, dynamic> caja) async {
    final documentos = await _directorioDocumentos();
    final fechaApertura = _parseFecha(_texto(caja['fecha_apertura'])) ?? DateTime.now();
    final anio = fechaApertura.year.toString();
    final mes = _nombreMes(fechaApertura.month);

    final observacion = _texto(caja['observaciones_apertura']).trim();
    final observacionArchivo = observacion.isEmpty ? 'Sin_observacion' : observacion;
    final fechaArchivo = _fechaArchivo(fechaApertura);
    final nombreArchivo = _limpiarNombreArchivo('ReporteCaja_${fechaArchivo}_$observacionArchivo.pdf');

    final carpeta = Directory('${documentos.path}${Platform.pathSeparator}Reportes de Caja Diarios${Platform.pathSeparator}$anio${Platform.pathSeparator}$mes');

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    return '${carpeta.path}${Platform.pathSeparator}$nombreArchivo';
  }

  Future<Directory> _directorioDocumentos() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.trim().isNotEmpty) {
        return Directory('$userProfile${Platform.pathSeparator}Documents');
      }
    }

    return getApplicationDocumentsDirectory();
  }

  pw.Widget _encabezado(Map<String, dynamic> caja, Map<String, dynamic> reporte) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#7A4423'),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE DE CAJA DIARIO',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Panadería Nicol',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'Caja #${_texto(caja['id'])}',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#7A4423'),
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _datoHeader('Empleado', caja['empleado']),
              _datoHeader('Apertura', caja['fecha_apertura']),
              _datoHeader('Cierre', caja['fecha_cierre']),
              _datoHeader('Generado', reporte['generado_en']),
            ],
          ),
          pw.SizedBox(height: 8),
          _datoHeader(
            'Observación apertura',
            _texto(caja['observaciones_apertura']).trim().isEmpty ? 'Sin observación' : caja['observaciones_apertura'],
          ),
        ],
      ),
    );
  }

  pw.Widget _datoHeader(String label, dynamic value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: _texto(value),
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _tarjetasResumen(Map<String, dynamic> resumen) {
    final items = [
      ['Ventas', _moneda(resumen['total_ventas'])],
      ['Gastos de caja', _moneda(resumen['total_gastos_caja'])],
      ['Gastos no caja', _moneda(resumen['total_gastos_no_caja'])],
      ['Resultado caja', _moneda(resumen['resultado_caja'])],
      ['Resultado admin.', _moneda(resumen['resultado_administrativo'])],
      ['Ventas registradas', _texto(resumen['cantidad_ventas'])],
    ];

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _tarjeta(item[0], item[1])).toList(),
    );
  }

  pw.Widget _tarjeta(String label, String value) {
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F1EC'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#E8D4C6')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _seccionTitulo(String titulo) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EFEFEF'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _nota(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
      child: pw.Text(
        texto,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _tablaMetodos(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _sinDatos();

    final data = <List<String>>[
      ['Medio', 'Inicial', 'Ventas', 'Gastos caja', 'Esperado', 'Sistema', 'Diferencia'],
      ...rows.map((r) => [
            _capitalizar(_texto(r['metodo'])),
            _moneda(r['saldo_inicial']),
            _moneda(r['ventas']),
            _moneda(r['gastos_caja']),
            _moneda(r['saldo_esperado']),
            _moneda(r['saldo_sistema']),
            _moneda(r['diferencia']),
          ]),
    ];

    return _tabla(data, columnWidths: {
      0: const pw.FlexColumnWidth(1.25),
      1: const pw.FlexColumnWidth(1.15),
      2: const pw.FlexColumnWidth(1.15),
      3: const pw.FlexColumnWidth(1.15),
      4: const pw.FlexColumnWidth(1.15),
      5: const pw.FlexColumnWidth(1.15),
      6: const pw.FlexColumnWidth(1.15),
    });
  }

  pw.Widget _tablaVentas(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _sinDatos('No hay ventas asignadas a esta caja.');

    final data = <List<String>>[
      ['#', 'Fecha', 'Cliente', 'Método', 'Subtotal', 'Desc.', 'Propina', 'Total'],
      ...rows.map((r) => [
            _texto(r['id']),
            _fechaCorta(r['fecha']),
            _recortar(_texto(r['cliente']), 26),
            _capitalizar(_texto(r['metodo'])),
            _moneda(r['subtotal']),
            _moneda(r['descuento']),
            _moneda(r['propina']),
            _moneda(r['total']),
          ]),
    ];

    return _tabla(data, fontSize: 7.2, columnWidths: {
      0: const pw.FlexColumnWidth(0.45),
      1: const pw.FlexColumnWidth(1.15),
      2: const pw.FlexColumnWidth(1.75),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(0.9),
      6: const pw.FlexColumnWidth(0.9),
      7: const pw.FlexColumnWidth(1),
    });
  }

  pw.Widget _tablaProductosVendidos(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _sinDatos('No hay productos vendidos para mostrar.');

    final data = <List<String>>[
      ['Código', 'Producto', 'Cantidad vendida', 'Total vendido'],
      ...rows.map((r) => [
            _texto(r['codigo']),
            _recortar(_texto(r['nombre']), 42),
            _cantidad(r['cantidad_vendida']),
            _moneda(r['total_vendido']),
          ]),
    ];

    return _tabla(data, columnWidths: {
      0: const pw.FlexColumnWidth(0.9),
      1: const pw.FlexColumnWidth(2.7),
      2: const pw.FlexColumnWidth(1.1),
      3: const pw.FlexColumnWidth(1.1),
    });
  }

  pw.Widget _tablaGastos(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _sinDatos('No hay gastos para mostrar en esta sección.');

    final data = <List<String>>[
      ['#', 'Fecha', 'Descripción', 'Método', 'Empleado', 'Monto'],
      ...rows.map((r) => [
            _texto(r['id']),
            _fechaCorta(r['fecha_gasto']),
            _recortar(_texto(r['descripcion']), 42),
            _capitalizar(_texto(r['metodo'])),
            _recortar(_texto(r['empleado']), 20),
            _moneda(r['monto']),
          ]),
    ];

    return _tabla(data, fontSize: 7.4, columnWidths: {
      0: const pw.FlexColumnWidth(0.45),
      1: const pw.FlexColumnWidth(1.15),
      2: const pw.FlexColumnWidth(2.6),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1.15),
      5: const pw.FlexColumnWidth(1),
    });
  }

  pw.Widget _tablaInventario(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _sinDatos('No hay movimientos de inventario relacionados con esta caja/turno.');

    final data = <List<String>>[
      ['Código', 'Producto', 'Stock inicial estimado', 'Entradas', 'Vendido', 'Bajas', 'Stock final', 'Mov. neto'],
      ...rows.map((r) => [
            _texto(r['codigo']),
            _recortar(_texto(r['nombre']), 30),
            _cantidad(r['stock_inicial_estimado']),
            _cantidad(r['entradas']),
            _cantidad(r['vendido']),
            _cantidad(r['bajas']),
            _cantidad(r['stock_final']),
            _cantidad(r['movimiento_neto']),
          ]),
    ];

    return _tabla(data, fontSize: 6.7, columnWidths: {
      0: const pw.FlexColumnWidth(0.75),
      1: const pw.FlexColumnWidth(2.1),
      2: const pw.FlexColumnWidth(1.0),
      3: const pw.FlexColumnWidth(0.75),
      4: const pw.FlexColumnWidth(0.75),
      5: const pw.FlexColumnWidth(0.7),
      6: const pw.FlexColumnWidth(0.8),
      7: const pw.FlexColumnWidth(0.8),
    });
  }

  pw.Widget _tabla(
    List<List<String>> data, {
    double fontSize = 7.8,
    Map<int, pw.TableColumnWidth>? columnWidths,
  }) {
    return pw.TableHelper.fromTextArray(
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#7A4423')),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: fontSize,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: fontSize, color: PdfColors.grey900),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      columnWidths: columnWidths,
    );
  }

  pw.Widget _sinDatos([String mensaje = 'No hay información para mostrar.']) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(mensaje, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value.map((e) => _map(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _texto(dynamic value) => value?.toString() ?? '';

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_texto(value).replaceAll(',', '.')) ?? 0;
  }

  String _moneda(dynamic value) {
    final n = _num(value).round();
    final sign = n < 0 ? '-' : '';
    final raw = n.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final posFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return '$sign\$ ${buffer.toString()}';
  }

  String _cantidad(dynamic value) {
    final n = _num(value);
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toStringAsFixed(2);
  }

  String _capitalizar(String value) {
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  DateTime? _parseFecha(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  String _fechaCorta(dynamic value) {
    final fecha = _parseFecha(_texto(value));
    if (fecha == null) return _texto(value);
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    final hh = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${fecha.year} $hh:$min';
  }

  String _fechaArchivo(DateTime fecha) {
    final dd = fecha.day.toString().padLeft(2, '0');
    final mm = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$mm-$dd';
  }

  String _nombreMes(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (mes < 1 || mes > 12) return 'Mes';
    return meses[mes - 1];
  }

  String _limpiarNombreArchivo(String value) {
    var sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '-')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();

    while (sanitized.contains('_.')) {
      sanitized = sanitized.replaceAll('_.', '.');
    }

    return sanitized;
  }

  String _recortar(String value, int max) {
    if (value.length <= max) return value;
    if (max <= 3) return value.substring(0, max);
    return '${value.substring(0, max - 3)}...';
  }
}
