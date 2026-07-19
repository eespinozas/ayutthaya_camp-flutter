/// Ventana horaria para confirmar asistencia a una clase.
///
/// Regla de negocio: el botón "Confirmar Asistencia" se habilita desde
/// [aperturaAntes] antes del inicio de la clase y hasta [gracia] después
/// de su término. La primera clase del día dura 60 minutos; todas las
/// demás, 90. Ej: clase de 18:00 (no primera) → ventana 17:45–19:45.
class AttendanceWindow {
  AttendanceWindow._();

  /// Cuánto antes del inicio se abre la ventana.
  static const Duration aperturaAntes = Duration(minutes: 15);

  /// Gracia después del término de la clase.
  static const Duration gracia = Duration(minutes: 15);

  /// La primera clase del día dura 1 hora.
  static const Duration duracionPrimeraClase = Duration(minutes: 60);

  /// Todas las demás clases duran 1.5 horas.
  static const Duration duracionResto = Duration(minutes: 90);

  static Duration duracionClase({required bool esPrimeraClaseDelDia}) =>
      esPrimeraClaseDelDia ? duracionPrimeraClase : duracionResto;

  /// Momento en que se habilita la confirmación.
  static DateTime opensAt(DateTime inicioClase) =>
      inicioClase.subtract(aperturaAntes);

  /// Momento en que se cierra la confirmación (término + gracia).
  static DateTime closesAt(
    DateTime inicioClase, {
    required bool esPrimeraClaseDelDia,
  }) => inicioClase
      .add(duracionClase(esPrimeraClaseDelDia: esPrimeraClaseDelDia))
      .add(gracia);

  /// ¿Está abierta la ventana de confirmación en [now]?
  static bool isOpen(
    DateTime inicioClase, {
    required bool esPrimeraClaseDelDia,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return !t.isBefore(opensAt(inicioClase)) &&
        t.isBefore(
          closesAt(inicioClase, esPrimeraClaseDelDia: esPrimeraClaseDelDia),
        );
  }

  /// ¿Ya se cerró la ventana en [now]?
  static bool isClosed(
    DateTime inicioClase, {
    required bool esPrimeraClaseDelDia,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return !t.isBefore(
      closesAt(inicioClase, esPrimeraClaseDelDia: esPrimeraClaseDelDia),
    );
  }

  /// Convierte "HH:mm" (o "H:mm") a minutos desde medianoche.
  static int _aMinutos(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// ¿Es [time] la primera clase entre los horarios del día [horariosDelDia]?
  ///
  /// Con lista vacía se asume que NO es la primera (duración estándar de 90
  /// minutos): es el caso conservador mientras los horarios aún no cargan.
  static bool esPrimeraClaseDelDia(
    String time,
    Iterable<String> horariosDelDia,
  ) {
    if (horariosDelDia.isEmpty) return false;
    final minutos = _aMinutos(time);
    return horariosDelDia.every((h) => _aMinutos(h) >= minutos);
  }
}
