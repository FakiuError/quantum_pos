import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class EscPosService {
  static const _channel = MethodChannel('escpos_usb');

  /// 🔓 ABRIR CAJÓN
  static Future<void> abrirCajon() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final bytes = <int>[];
    bytes.addAll(generator.drawer());

    await _print(bytes);
  }

  /// 🧾 IMPRIMIR FACTURA
  static Future<void> imprimirTicket({
    required int numeroFactura,
    required String cliente,
    required String identificacion,
    required String usuario,
    required DateTime fechaHora,
    required double subtotal,
    required double descuento,
    required double total,
    required double cambio,
    required List<Map<String, dynamic>> items,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);

    final bytes = <int>[];

    // ───────── ENCABEZADO ─────────
    bytes.addAll(gen.text(
      'PANADERIA NICOL',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
      ),
    ));

    bytes.addAll(gen.text(
      'Regimen simplificado',
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(gen.text(
      'FACTURA No. $numeroFactura',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));

    // 📅 FECHA / HORA
    bytes.addAll(gen.text(
      'Fecha: ${_formatFecha(fechaHora)}',
      styles: const PosStyles(align: PosAlign.center),
    ));

    // 👤 USUARIO
    bytes.addAll(gen.text(
      'Atiende: $usuario',
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(gen.hr());

    // ───────── CLIENTE ─────────
    bytes.addAll(gen.text('Cliente: $cliente'));
    bytes.addAll(gen.text('CC/NIT: $identificacion'));

    bytes.addAll(gen.hr());

    // ───────── CABECERA DE COLUMNAS ─────────
    bytes.addAll(gen.row([
      PosColumn(text: 'PRODUCTO', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(text: 'CANT', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'V.U', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'TOTAL', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));

    bytes.addAll(gen.hr());

    // ───────── ITEMS ─────────
    for (final p in items) {
      final nombre = (p['nombre'] ?? '').toString();
      final cantidad = p['cantidad'];
      final precio = p['precio'];
      final totalItem = precio * cantidad;

      final lineasNombre = _splitText(nombre, 20);

      // Primera línea
      bytes.addAll(gen.row([
        PosColumn(text: lineasNombre[0], width: 5),
        PosColumn(text: cantidad.toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: '\$${precio.toStringAsFixed(0)}', width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: '\$${totalItem.toStringAsFixed(0)}', width: 3, styles: const PosStyles(align: PosAlign.right)),
      ]));

      // Líneas adicionales del nombre
      for (int i = 1; i < lineasNombre.length; i++) {
        bytes.addAll(gen.row([
          PosColumn(text: lineasNombre[i], width: 5),
          PosColumn(text: '', width: 2),
          PosColumn(text: '', width: 2),
          PosColumn(text: '', width: 3),
        ]));
      }
    }

    bytes.addAll(gen.hr());

    // ───────── TOTALES ─────────
    bytes.addAll(gen.text('Subtotal: \$${subtotal.toStringAsFixed(0)}'));

    if (descuento > 0) {
      bytes.addAll(gen.text('Descuento: -\$${descuento.toStringAsFixed(0)}'));
    }

    bytes.addAll(gen.text(
      'TOTAL: \$${total.toStringAsFixed(0)}',
      styles: const PosStyles(bold: true, height: PosTextSize.size2),
    ));

    // 🔄 CAMBIO (AQUÍ ESTÁ LA CORRECCIÓN)
    if (cambio > 0) {
      bytes.addAll(gen.text(
        'Cambio: \$${cambio.toStringAsFixed(0)}',
        styles: const PosStyles(bold: true),
      ));
    }

    bytes.addAll(gen.hr());

    // ───────── MENSAJE FINAL ─────────
    bytes.addAll(gen.text(
      'Gracias por tu compra!!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    await _print(bytes);
  }

  /// 🖨️ ENVÍO A WINDOWS
  static Future<void> _print(List<int> bytes) async {
    await _channel.invokeMethod(
      'printEscPos',
      Uint8List.fromList(bytes),
    );
  }

  static List<String> _splitText(String text, int maxLength) {
    final words = text.split(' ');
    final lines = <String>[];

    String currentLine = '';

    for (final word in words) {
      if ((currentLine + word).length <= maxLength) {
        currentLine += (currentLine.isEmpty ? '' : ' ') + word;
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  static String _formatFecha(DateTime f) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(f.day)}/${two(f.month)}/${f.year} '
        '${two(f.hour)}:${two(f.minute)}';
  }
}
