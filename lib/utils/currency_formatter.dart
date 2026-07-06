import 'package:intl/intl.dart';

/// Formatea un monto en pesos chilenos para presentación.
///
/// Siempre entero completo (sin K/M ni decimales), con separador de miles
/// chileno (punto) y sufijo CLP. El peso chileno no usa decimales: si el
/// valor llega con decimales se redondea al entero más cercano.
///
/// Ejemplos: 0 → "$0 CLP" · 12000 → "$12.000 CLP" · 1250000 → "$1.250.000 CLP"
String formatCLP(num monto) {
  final formatter = NumberFormat.decimalPattern('es_CL');
  return '\$${formatter.format(monto.round())} CLP';
}
