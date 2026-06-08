import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TicketVentaPdfService {
  Future<String> generarTicketVentaPdf({
    required Map<String, dynamic> venta,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final ruta = await crearRutaTicketVenta(venta);

    await Isolate.run(() async {
      final bytes = await _TicketVentaPdfBuilder(
        venta: venta,
        detalles: detalles,
      ).build();

      final file = File(ruta);
      await file.writeAsBytes(bytes, flush: true);
    });

    return ruta;
  }

  Future<String> crearRutaTicketVenta(Map<String, dynamic> venta) async {
    final documentos = await _directorioDocumentos();
    final fechaVenta = _parseFecha(_texto(venta['fecha'])) ?? DateTime.now();

    final anio = fechaVenta.year.toString();
    final mes = _nombreMes(fechaVenta.month);
    final dia = fechaVenta.day.toString().padLeft(2, '0');
    final fechaArchivo = _fechaHoraArchivo(fechaVenta);
    final idVenta = _texto(venta['id']).trim().isEmpty ? 'SinId' : _texto(venta['id']);

    final carpeta = Directory(
      '${documentos.path}${Platform.pathSeparator}Tickets de venta'
      '${Platform.pathSeparator}$anio${Platform.pathSeparator}$mes'
      '${Platform.pathSeparator}$dia',
    );

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    final nombreArchivo = _limpiarNombreArchivo(
      'Ticket de Venta ${idVenta}_$fechaArchivo.pdf',
    );

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

  static String _texto(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseFecha(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  static String _fechaHoraArchivo(DateTime fecha) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${fecha.year}-${two(fecha.month)}-${two(fecha.day)}_${two(fecha.hour)}-${two(fecha.minute)}';
  }

  static String _nombreMes(int mes) {
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

  static String _limpiarNombreArchivo(String value) {
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
}

class _TicketVentaPdfBuilder {
  _TicketVentaPdfBuilder({
    required this.venta,
    required this.detalles,
  });

  final Map<String, dynamic> venta;
  final List<Map<String, dynamic>> detalles;

  static final PdfColor _negroSuave = PdfColor.fromHex('#222222');

  Future<Uint8List> build() async {
    final pdf = pw.Document();
    final fechaVenta = _parseFecha(_texto(venta['fecha'])) ?? DateTime.now();
    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      420 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'PANADERIA NICOL',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _negroSuave,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          _center('NIT 39.629.075'),
          _center('Regimen simplificado'),
          pw.SizedBox(height: 5),
          _center('FACTURA No. ${_texto(venta['id'])}', bold: true),
          _center('Fecha: ${_formatFecha(fechaVenta)}'),
          _center('Atiende: ${_texto(venta['empleado']).isEmpty ? 'Sin empleado' : _texto(venta['empleado'])}'),
          _linea(),
          _textoLinea('Cliente', _texto(venta['cliente']).isEmpty ? 'Consumidor final' : _texto(venta['cliente'])),
          _textoLinea('CC/NIT', _texto(venta['identificacion']).isEmpty ? '222222222222' : _texto(venta['identificacion'])),
          _linea(),
          _encabezadoItems(),
          _linea(),
          ...detalles.expand(_detalleItem).toList(),
          _linea(),
          _totalLinea('Subtotal', _num(venta['subtotal'])),
          if (_num(venta['descuento']) > 0)
            _totalLinea('Descuento', -_num(venta['descuento'])),
          if (_num(venta['propina']) > 0)
            _totalLinea('Propina', _num(venta['propina'])),
          pw.SizedBox(height: 3),
          _totalLinea('TOTAL', _num(venta['total']), bold: true, grande: true),
          _linea(),
          _center('Metodo: ${_texto(venta['metodo'])}'),
          pw.SizedBox(height: 8),
          _center('Gracias por tu compra!!', bold: true),
          pw.SizedBox(height: 8),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _center(String text, {bool bold = false}) {
    return pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(
        fontSize: 8.4,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: _negroSuave,
      ),
    );
  }

  pw.Widget _linea() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Text(
        List.filled(42, '-').join(),
        style: const pw.TextStyle(fontSize: 7.2),
      ),
    );
  }

  pw.Widget _textoLinea(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        '$label: $value',
        style: const pw.TextStyle(fontSize: 8.2),
      ),
    );
  }

  pw.Widget _encabezadoItems() {
    return pw.Row(
      children: [
        _cell('PRODUCTO', flex: 5, bold: true),
        _cell('CANT', flex: 2, bold: true, align: pw.TextAlign.center),
        _cell('V.U', flex: 2, bold: true, align: pw.TextAlign.right),
        _cell('TOTAL', flex: 3, bold: true, align: pw.TextAlign.right),
      ],
    );
  }

  Iterable<pw.Widget> _detalleItem(Map<String, dynamic> item) sync* {
    final nombre = _texto(item['nombre']);
    final cantidad = _num(item['cantidad']);
    final precio = _num(item['precio_unitario']);
    final total = _num(item['precio_total']);
    final lineas = _splitText(nombre, 20);

    yield pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _cell(lineas.isEmpty ? '' : lineas.first, flex: 5),
        _cell(_cantidad(cantidad), flex: 2, align: pw.TextAlign.center),
        _cell(_monedaCorta(precio), flex: 2, align: pw.TextAlign.right),
        _cell(_monedaCorta(total), flex: 3, align: pw.TextAlign.right),
      ],
    );

    for (int i = 1; i < lineas.length; i++) {
      yield pw.Row(
        children: [
          _cell(lineas[i], flex: 5),
          _cell('', flex: 2),
          _cell('', flex: 2),
          _cell('', flex: 3),
        ],
      );
    }
  }

  pw.Widget _cell(
    String text, {
    required int flex,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.4,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _totalLinea(
    String label,
    double value, {
    bool bold = false,
    bool grande = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: grande ? 11 : 8.6,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _monedaCorta(value),
            style: pw.TextStyle(
              fontSize: grande ? 11 : 8.6,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static String _texto(dynamic value) => value?.toString() ?? '';

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_texto(value).replaceAll(',', '.')) ?? 0;
  }

  static DateTime? _parseFecha(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  static String _formatFecha(DateTime f) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(f.day)}/${two(f.month)}/${f.year} ${two(f.hour)}:${two(f.minute)}';
  }

  static String _monedaCorta(double value) {
    final n = value.round();
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

    return '$sign\$${buffer.toString()}';
  }

  static String _cantidad(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  static List<String> _splitText(String text, int maxLength) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final lines = <String>[];
    var currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + 1 + word.length) <= maxLength) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.isEmpty ? [''] : lines;
  }
}
