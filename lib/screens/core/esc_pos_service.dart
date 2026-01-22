import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:printing/printing.dart';

class EscPosService {

  /// 🔓 ABRIR CAJÓN
  static Future<void> abrirCajon() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final bytes = <int>[];
    bytes.addAll(generator.drawer());

    await _print(bytes);
  }

  /// 🧾 IMPRIMIR TICKET + CORTE
  static Future<void> imprimirTicket({
    required double total,
    required double cambio,
    required List<Map<String, dynamic>> items,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    final bytes = <int>[];

    /// TÍTULO CENTRADO
    bytes.addAll(generator.row([
      PosColumn(
        text: 'PANADERÍA NICOL',
        width: 12,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]));

    bytes.addAll(generator.hr());

    /// PRODUCTOS
    for (final p in items) {
      bytes.addAll(generator.row([
        PosColumn(
          text: p['nombre'],
          width: 6,
        ),
        PosColumn(
          text: 'x${p['cantidad']}',
          width: 2,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: '\$${p['total'].toStringAsFixed(0)}',
          width: 4,
          styles: const PosStyles(bold: true),
        ),
      ]));
    }

    bytes.addAll(generator.hr());

    /// TOTAL
    bytes.addAll(generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: '\$${total.toStringAsFixed(0)}',
        width: 4,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
    ]));

    /// CAMBIO
    bytes.addAll(generator.row([
      PosColumn(
        text: 'CAMBIO',
        width: 8,
      ),
      PosColumn(
        text: '\$${cambio.toStringAsFixed(0)}',
        width: 4,
      ),
    ]));

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    await _print(bytes);
  }

  /// 🖨️ IMPRIMIR EN IMPRESORA "POS 80"
  static Future<void> _print(List<int> bytes) async {
    final printers = await Printing.listPrinters();

    final printer = printers.firstWhere(
          (p) => p.name == 'POS 80',
      orElse: () => throw Exception('Impresora POS 80 no encontrada'),
    );

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  }
}