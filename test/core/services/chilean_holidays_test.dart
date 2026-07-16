import 'package:flutter_test/flutter_test.dart';

import 'package:ayutthaya_camp/core/services/chilean_holidays.dart';

void main() {
  group('ChileanHolidays feriados fijos', () {
    test('fijos de 2026', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 1, 1)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 5, 1)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 5, 21)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 7, 16)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 8, 15)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 9, 18)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 9, 19)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 11, 1)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 12, 8)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 12, 25)), isTrue);
    });

    test('días normales no son feriado', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 3, 11)), isFalse);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 7, 15)), isFalse);
    });

    test('2 de enero feriado solo cuando el 1 cae domingo (Ley 20.983)', () {
      // 1 ene 2023 fue domingo → 2 ene feriado
      expect(ChileanHolidays.isHoliday(DateTime(2023, 1, 2)), isTrue);
      // 1 ene 2026 es jueves → 2 ene NO es feriado
      expect(ChileanHolidays.isHoliday(DateTime(2026, 1, 2)), isFalse);
    });
  });

  group('ChileanHolidays Semana Santa (computus)', () {
    test('Pascua de años conocidos', () {
      expect(ChileanHolidays.easterSunday(2024), DateTime(2024, 3, 31));
      expect(ChileanHolidays.easterSunday(2025), DateTime(2025, 4, 20));
      expect(ChileanHolidays.easterSunday(2026), DateTime(2026, 4, 5));
      expect(ChileanHolidays.easterSunday(2027), DateTime(2027, 3, 28));
    });

    test('Viernes y Sábado Santo 2026 (3 y 4 de abril)', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 4, 3)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 4, 4)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 4, 5)), isFalse); // domingo no es feriado legal
    });
  });

  group('ChileanHolidays trasladables (Ley 19.668)', () {
    test('29 jun 2026 es lunes: no se traslada', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 6, 29)), isTrue);
    });

    test('29 jun 2027 es martes: se traslada al lunes 28', () {
      expect(ChileanHolidays.isHoliday(DateTime(2027, 6, 28)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2027, 6, 29)), isFalse);
    });

    test('12 oct 2027 es martes: se traslada al lunes 11', () {
      expect(ChileanHolidays.isHoliday(DateTime(2027, 10, 11)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2027, 10, 12)), isFalse);
    });
  });

  group('ChileanHolidays 31 de octubre (Ley 20.299)', () {
    test('2017 cayó martes: feriado fue el viernes 27', () {
      expect(ChileanHolidays.isHoliday(DateTime(2017, 10, 27)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2017, 10, 31)), isFalse);
    });

    test('2018 cayó miércoles: feriado fue el viernes 2 nov', () {
      expect(ChileanHolidays.isHoliday(DateTime(2018, 11, 2)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2018, 10, 31)), isFalse);
    });

    test('2026 cae sábado: queda el 31', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 10, 31)), isTrue);
    });
  });

  group('ChileanHolidays sandwich de septiembre (Ley 20.215)', () {
    test('2024: 18-19 fueron mié-jue → viernes 20 feriado', () {
      expect(ChileanHolidays.isHoliday(DateTime(2024, 9, 20)), isTrue);
    });

    test('2029: 18 cae martes → lunes 17 feriado', () {
      expect(ChileanHolidays.isHoliday(DateTime(2029, 9, 17)), isTrue);
    });

    test('2026: 18 cae viernes → ni 17 ni 20 son feriado', () {
      expect(ChileanHolidays.isHoliday(DateTime(2026, 9, 17)), isFalse);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 9, 20)), isFalse);
    });
  });

  group('ChileanHolidays Pueblos Indígenas (solsticio)', () {
    test('2025 fue 20 de junio, 2026 es 21 de junio', () {
      expect(ChileanHolidays.isHoliday(DateTime(2025, 6, 20)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 6, 21)), isTrue);
      expect(ChileanHolidays.isHoliday(DateTime(2026, 6, 20)), isFalse);
    });
  });

  group('ChileanHolidays.effectiveDayOfWeek', () {
    test('feriado de lunes a viernes usa horario del sábado', () {
      // 18 sep 2026 es viernes feriado → sábado (6)
      expect(
        ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 9, 18)),
        DateTime.saturday,
      );
      // Viernes Santo 2026 (3 abr, viernes) → sábado
      expect(
        ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 4, 3)),
        DateTime.saturday,
      );
      // 21 may 2026 es jueves feriado → sábado
      expect(
        ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 5, 21)),
        DateTime.saturday,
      );
    });

    test('día de semana normal se mantiene', () {
      // 11 mar 2026 es miércoles normal
      expect(ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 3, 11)), 3);
    });

    test('feriado en fin de semana no cambia nada', () {
      // 31 oct 2026 es sábado feriado → sigue siendo sábado
      expect(ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 10, 31)), 6);
      // 1 nov 2026 es domingo feriado → sigue siendo domingo
      expect(ChileanHolidays.effectiveDayOfWeek(DateTime(2026, 11, 1)), 7);
    });

    test('isWeekdayHoliday', () {
      expect(ChileanHolidays.isWeekdayHoliday(DateTime(2026, 9, 18)), isTrue); // viernes
      expect(ChileanHolidays.isWeekdayHoliday(DateTime(2026, 10, 31)), isFalse); // sábado
      expect(ChileanHolidays.isWeekdayHoliday(DateTime(2026, 3, 11)), isFalse); // normal
    });
  });
}
