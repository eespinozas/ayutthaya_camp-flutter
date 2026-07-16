/// Feriados nacionales de Chile, calculados algorítmicamente (sin APIs).
///
/// Cubre:
/// - Fijos: 1 ene, 1 may, 21 may, 16 jul, 15 ago, 18-19 sep, 1 nov,
///   8 dic, 25 dic.
/// - Semana Santa: Viernes y Sábado Santo (computus gregoriano).
/// - Trasladables (Ley 19.668): San Pedro y San Pablo (29 jun) y
///   Encuentro de Dos Mundos (12 oct) — si caen mar/mié/jue se corren al
///   lunes de esa semana; si caen viernes, al lunes siguiente.
/// - Iglesias Evangélicas (31 oct, Ley 20.299): martes → viernes anterior;
///   miércoles → viernes siguiente.
/// - "Sandwich" de septiembre (Ley 20.215): 18-19 en mar-mié → feriado el
///   lunes 17; en mié-jue → feriado el viernes 20.
/// - 2 de enero cuando el 1 cae domingo (Ley 20.983).
/// - Día de los Pueblos Indígenas (solsticio de invierno, Ley 21.357):
///   tabla por año con fallback al 21 de junio.
///
/// NO incluye feriados regionales ni los decretados por una sola vez
/// (elecciones/plebiscitos): esos no son calculables.
class ChileanHolidays {
  ChileanHolidays._();

  /// Cache por año (el cálculo es barato, pero se consulta en cada build).
  static final Map<int, Set<int>> _cache = {};

  /// Día de los Pueblos Indígenas: fecha del solsticio de invierno en Chile.
  /// Fuente: fechas oficiales publicadas; fallback 21 de junio.
  static const Map<int, int> _diaPueblosIndigenas = {
    2021: 21, 2022: 21, 2023: 21, 2024: 20, 2025: 20,
    2026: 21, 2027: 21, 2028: 20, 2029: 20, 2030: 21,
    2031: 21, 2032: 20, 2033: 20, 2034: 21, 2035: 21,
  };

  static int _key(int month, int day) => month * 100 + day;

  /// Domingo de Pascua (computus gregoriano anónimo).
  static DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Traslado Ley 19.668: mar/mié/jue → lunes de esa semana;
  /// viernes → lunes siguiente. Sáb/dom/lun quedan igual.
  static DateTime _trasladoALunes(DateTime fecha) {
    switch (fecha.weekday) {
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return fecha.subtract(Duration(days: fecha.weekday - DateTime.monday));
      case DateTime.friday:
        return fecha.add(const Duration(days: 3));
      default:
        return fecha;
    }
  }

  /// Feriados del año como set de claves mes*100+día.
  static Set<int> _holidaysForYear(int year) {
    return _cache.putIfAbsent(year, () {
      final set = <int>{
        _key(1, 1), // Año Nuevo
        _key(5, 1), // Día del Trabajo
        _key(5, 21), // Glorias Navales
        _key(7, 16), // Virgen del Carmen
        _key(8, 15), // Asunción de la Virgen
        _key(9, 18), // Independencia Nacional
        _key(9, 19), // Glorias del Ejército
        _key(11, 1), // Todos los Santos
        _key(12, 8), // Inmaculada Concepción
        _key(12, 25), // Navidad
      };

      // 2 de enero cuando el 1 cae domingo (Ley 20.983)
      if (DateTime(year, 1, 1).weekday == DateTime.sunday) {
        set.add(_key(1, 2));
      }

      // Semana Santa
      final pascua = easterSunday(year);
      final viernesSanto = pascua.subtract(const Duration(days: 2));
      final sabadoSanto = pascua.subtract(const Duration(days: 1));
      set.add(_key(viernesSanto.month, viernesSanto.day));
      set.add(_key(sabadoSanto.month, sabadoSanto.day));

      // Día de los Pueblos Indígenas (solsticio de invierno)
      set.add(_key(6, _diaPueblosIndigenas[year] ?? 21));

      // Trasladables (Ley 19.668)
      final sanPedro = _trasladoALunes(DateTime(year, 6, 29));
      set.add(_key(sanPedro.month, sanPedro.day));
      final dosMundos = _trasladoALunes(DateTime(year, 10, 12));
      set.add(_key(dosMundos.month, dosMundos.day));

      // Iglesias Evangélicas (Ley 20.299): martes → viernes anterior;
      // miércoles → viernes siguiente.
      final evangelicas = DateTime(year, 10, 31);
      if (evangelicas.weekday == DateTime.tuesday) {
        set.add(_key(10, 27));
      } else if (evangelicas.weekday == DateTime.wednesday) {
        set.add(_key(11, 2));
      } else {
        set.add(_key(10, 31));
      }

      // Sandwich de septiembre (Ley 20.215)
      final dieciocho = DateTime(year, 9, 18);
      if (dieciocho.weekday == DateTime.tuesday) {
        set.add(_key(9, 17)); // lunes 17
      } else if (dieciocho.weekday == DateTime.wednesday) {
        set.add(_key(9, 20)); // viernes 20
      }

      return set;
    });
  }

  /// ¿Es [date] feriado nacional en Chile?
  static bool isHoliday(DateTime date) {
    return _holidaysForYear(date.year).contains(_key(date.month, date.day));
  }

  /// ¿Es feriado que cae de lunes a viernes?
  static bool isWeekdayHoliday(DateTime date) {
    return date.weekday >= DateTime.monday &&
        date.weekday <= DateTime.friday &&
        isHoliday(date);
  }

  /// Día de la semana EFECTIVO para horarios de clases:
  /// los feriados de lunes a viernes usan el horario del sábado.
  static int effectiveDayOfWeek(DateTime date) {
    if (isWeekdayHoliday(date)) return DateTime.saturday;
    return date.weekday;
  }
}
