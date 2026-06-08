import 'package:flutter/services.dart';

/// Utilidades centralizadas para manejar dinero en pesos colombianos.
///
/// Regla del sistema:
/// - En pantalla se muestra como pesos colombianos legibles: $ 30.000
/// - Para cálculos y API/base de datos se convierte a decimal: 30000.0 / 30000.00
class CurrencyUtils {
  CurrencyUtils._();

  static double parse(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    var text = value.toString().trim();
    if (text.isEmpty) return 0.0;

    text = text
        .replaceAll('\$', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^0-9,\.\-]'), '');

    if (text.isEmpty || text == '-' || text == ',' || text == '.') {
      return 0.0;
    }

    final isNegative = text.startsWith('-');
    text = text.replaceAll('-', '');

    if (text.contains(',') && text.contains('.')) {
      // Formato colombiano con decimales: 1.234.567,89
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains(',')) {
      // Decimal con coma o miles con coma. Para Colombia se interpreta como decimal.
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains('.')) {
      final parts = text.split('.');
      final last = parts.last;
      final allGroupsLookLikeThousands = parts.length > 1 &&
          parts.skip(1).every((part) => part.length == 3) &&
          parts.first.isNotEmpty &&
          parts.first.length <= 3;

      if (allGroupsLookLikeThousands) {
        text = parts.join();
      } else if (last.length == 3 && parts.length > 1) {
        // Caso común: $ 30.000
        text = parts.join();
      }
      // Si no parece miles, se conserva como decimal: 30000.50
    }

    final parsed = double.tryParse(text) ?? 0.0;
    return isNegative ? -parsed : parsed;
  }

  static String formatCop(
    dynamic value, {
    bool includeSymbol = true,
    int decimalDigits = 0,
    bool showNegativeBeforeSymbol = true,
  }) {
    final number = parse(value);
    final isNegative = number < 0;
    final absolute = number.abs();
    final fixed = absolute.toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final integerPart = _groupThousands(parts[0]);
    final decimalPart = decimalDigits > 0 && parts.length > 1 ? ',${parts[1]}' : '';
    final amount = '$integerPart$decimalPart';

    if (!includeSymbol) {
      return '${isNegative ? '-' : ''}$amount';
    }

    if (isNegative && showNegativeBeforeSymbol) {
      return '-\$ $amount';
    }

    return '${isNegative ? '-' : ''}\$ $amount';
  }

  static String toDatabaseString(dynamic value, {int decimalDigits = 2}) {
    return parse(value).toStringAsFixed(decimalDigits);
  }

  static String formatControllerValue(dynamic value) {
    return formatCop(value, decimalDigits: 0);
  }

  static String _groupThousands(String raw) {
    if (raw.isEmpty) return '0';

    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final posFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

/// Formateador para campos monetarios.
///
/// El usuario escribe números, pero el campo se ve como "$ 30.000".
/// Para guardar o calcular use CurrencyUtils.parse(controller.text).
class ColombianCurrencyInputFormatter extends TextInputFormatter {
  const ColombianCurrencyInputFormatter({this.allowNegative = false});

  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    if (raw.trim().isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final negative = allowNegative && raw.contains('-');
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final amount = double.tryParse(digits) ?? 0.0;
    final formatted = CurrencyUtils.formatCop(
      negative ? -amount : amount,
      decimalDigits: 0,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
