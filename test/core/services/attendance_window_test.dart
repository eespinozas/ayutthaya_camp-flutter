import 'package:flutter_test/flutter_test.dart';

import 'package:ayutthaya_camp/core/services/attendance_window.dart';

void main() {
  // Clase de las 18:00 (no primera del día): ventana 17:45 – 19:45
  final inicio1800 = DateTime(2026, 7, 14, 18, 0);

  group('AttendanceWindow ventana clase normal (90 min)', () {
    test('abre 15 min antes del inicio', () {
      expect(
        AttendanceWindow.opensAt(inicio1800),
        DateTime(2026, 7, 14, 17, 45),
      );
    });

    test('cierra 15 min después del término: 18:00 + 90 + 15 = 19:45', () {
      expect(
        AttendanceWindow.closesAt(inicio1800, esPrimeraClaseDelDia: false),
        DateTime(2026, 7, 14, 19, 45),
      );
    });

    test('cerrada antes de las 17:45, abierta desde las 17:45', () {
      expect(
        AttendanceWindow.isOpen(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 17, 44),
        ),
        isFalse,
      );
      expect(
        AttendanceWindow.isOpen(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 17, 45),
        ),
        isTrue,
      );
    });

    test('abierta durante la clase y hasta 19:44, cerrada a las 19:45', () {
      expect(
        AttendanceWindow.isOpen(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 19, 0),
        ),
        isTrue,
      );
      expect(
        AttendanceWindow.isOpen(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 19, 44),
        ),
        isTrue,
      );
      expect(
        AttendanceWindow.isOpen(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 19, 45),
        ),
        isFalse,
      );
      expect(
        AttendanceWindow.isClosed(
          inicio1800,
          esPrimeraClaseDelDia: false,
          now: DateTime(2026, 7, 14, 19, 45),
        ),
        isTrue,
      );
    });
  });

  group('AttendanceWindow primera clase del día (60 min)', () {
    // Primera clase 07:00: ventana 06:45 – 08:15
    final inicio0700 = DateTime(2026, 7, 14, 7, 0);

    test('cierra 15 min después del término: 07:00 + 60 + 15 = 08:15', () {
      expect(
        AttendanceWindow.closesAt(inicio0700, esPrimeraClaseDelDia: true),
        DateTime(2026, 7, 14, 8, 15),
      );
    });

    test('abierta a las 08:14, cerrada a las 08:15', () {
      expect(
        AttendanceWindow.isOpen(
          inicio0700,
          esPrimeraClaseDelDia: true,
          now: DateTime(2026, 7, 14, 8, 14),
        ),
        isTrue,
      );
      expect(
        AttendanceWindow.isOpen(
          inicio0700,
          esPrimeraClaseDelDia: true,
          now: DateTime(2026, 7, 14, 8, 15),
        ),
        isFalse,
      );
    });
  });

  group('AttendanceWindow.esPrimeraClaseDelDia', () {
    const horarios = ['07:00', '18:00', '19:30'];

    test('detecta la primera clase', () {
      expect(AttendanceWindow.esPrimeraClaseDelDia('07:00', horarios), isTrue);
    });

    test('las demás no son primera', () {
      expect(AttendanceWindow.esPrimeraClaseDelDia('18:00', horarios), isFalse);
      expect(AttendanceWindow.esPrimeraClaseDelDia('19:30', horarios), isFalse);
    });

    test('lista vacía (horarios sin cargar): conservador, no es primera', () {
      expect(AttendanceWindow.esPrimeraClaseDelDia('07:00', const []), isFalse);
    });

    test('soporta horas sin cero inicial', () {
      expect(
        AttendanceWindow.esPrimeraClaseDelDia('7:00', const ['7:00', '18:00']),
        isTrue,
      );
      expect(
        AttendanceWindow.esPrimeraClaseDelDia('9:00', const ['7:00', '9:00']),
        isFalse,
      );
    });
  });
}
