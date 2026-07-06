import 'package:flutter_test/flutter_test.dart';

import 'package:ayutthaya_camp/utils/currency_formatter.dart';

void main() {
  group('formatCLP', () {
    test('cero', () {
      expect(formatCLP(0), r'$0 CLP');
    });

    test('sin separador bajo 1.000', () {
      expect(formatCLP(850), r'$850 CLP');
    });

    test('miles con punto', () {
      expect(formatCLP(12000), r'$12.000 CLP');
    });

    test('millones con puntos cada 3 dígitos', () {
      expect(formatCLP(1250000), r'$1.250.000 CLP');
    });

    test('decimales se redondean al entero más cercano', () {
      expect(formatCLP(12499.6), r'$12.500 CLP');
      expect(formatCLP(12499.4), r'$12.499 CLP');
    });
  });
}
