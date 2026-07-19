import 'package:flutter_test/flutter_test.dart';

import 'package:ayutthaya_camp/core/services/ranking_service.dart';

void main() {
  group('RankingService.rangoDesdeClases', () {
    test('alumno nuevo (0 clases) empieza en Nak Rian IV', () {
      final rango = RankingService.rangoDesdeClases(0);
      expect(rango.nombre, 'Nak Rian IV');
      expect(rango.index, 0);
      expect(rango.esMaximo, isFalse);
    });

    test('valores intermedios no suben de división', () {
      expect(RankingService.rangoDesdeClases(1).nombre, 'Nak Rian IV');
      expect(RankingService.rangoDesdeClases(11).nombre, 'Nak Rian IV');
      expect(RankingService.rangoDesdeClases(13).nombre, 'Nak Rian III');
      expect(RankingService.rangoDesdeClases(23).nombre, 'Nak Rian III');
      expect(RankingService.rangoDesdeClases(47).nombre, 'Nak Rian I');
    });

    test('sube una división en cada múltiplo de 12', () {
      expect(RankingService.rangoDesdeClases(12).nombre, 'Nak Rian III');
      expect(RankingService.rangoDesdeClases(24).nombre, 'Nak Rian II');
      expect(RankingService.rangoDesdeClases(36).nombre, 'Nak Rian I');
    });

    test('cruce de tier: 36 → Nak Rian I, 48 → Nak Muay IV', () {
      expect(RankingService.rangoDesdeClases(36).nombre, 'Nak Rian I');
      expect(RankingService.rangoDesdeClases(48).nombre, 'Nak Muay IV');
      expect(RankingService.rangoDesdeClases(96).nombre, 'Nak Su IV');
      expect(RankingService.rangoDesdeClases(144).nombre, 'Yod Muay IV');
    });

    test('tope en Yod Muay I (180+ clases), sin desbordar', () {
      expect(RankingService.rangoDesdeClases(180).nombre, 'Yod Muay I');
      expect(RankingService.rangoDesdeClases(180).esMaximo, isTrue);
      expect(RankingService.rangoDesdeClases(500).nombre, 'Yod Muay I');
      expect(RankingService.rangoDesdeClases(999999).index, 15);
    });

    test('clases negativas se tratan como 0', () {
      expect(RankingService.rangoDesdeClases(-5).nombre, 'Nak Rian IV');
    });

    test('recorre los 16 rangos en orden', () {
      final nombres = [
        for (var i = 0; i < 16; i++)
          RankingService.rangoDesdeClases(i * 12).nombre,
      ];
      expect(nombres, [
        'Nak Rian IV',
        'Nak Rian III',
        'Nak Rian II',
        'Nak Rian I',
        'Nak Muay IV',
        'Nak Muay III',
        'Nak Muay II',
        'Nak Muay I',
        'Nak Su IV',
        'Nak Su III',
        'Nak Su II',
        'Nak Su I',
        'Yod Muay IV',
        'Yod Muay III',
        'Yod Muay II',
        'Yod Muay I',
      ]);
    });
  });

  group('RankingService.siguienteRango y clasesParaSiguienteRango', () {
    test('con 0 clases faltan 12 para Nak Rian III', () {
      expect(RankingService.siguienteRango(0)?.nombre, 'Nak Rian III');
      expect(RankingService.clasesParaSiguienteRango(0), 12);
    });

    test('con 7 clases faltan 5 para Nak Rian III', () {
      expect(RankingService.clasesParaSiguienteRango(7), 5);
      expect(RankingService.progresoEnDivision(7), 7);
    });

    test('justo al subir de rango el progreso se reinicia', () {
      expect(RankingService.progresoEnDivision(12), 0);
      expect(RankingService.clasesParaSiguienteRango(12), 12);
      expect(RankingService.siguienteRango(12)?.nombre, 'Nak Rian II');
    });

    test('cruce de tier: con 40 clases el siguiente es Nak Muay IV', () {
      expect(RankingService.siguienteRango(40)?.nombre, 'Nak Muay IV');
      expect(RankingService.clasesParaSiguienteRango(40), 8);
    });

    test('en el rango máximo no hay siguiente y la barra queda llena', () {
      expect(RankingService.siguienteRango(180), isNull);
      expect(RankingService.siguienteRango(200), isNull);
      expect(RankingService.clasesParaSiguienteRango(200), 0);
      expect(
        RankingService.progresoEnDivision(200),
        RankingService.clasesPorDivision,
      );
    });
  });

  group('RankingService.clasesParaRango', () {
    test('umbral acumulado por índice', () {
      expect(RankingService.clasesParaRango(0), 0);
      expect(RankingService.clasesParaRango(1), 12);
      expect(RankingService.clasesParaRango(4), 48);
      expect(RankingService.clasesParaRango(15), 180);
    });
  });

  group('RankingService.ventanaDeRangos', () {
    test('al inicio muestra los próximos 3 rangos', () {
      final ventana = RankingService.ventanaDeRangos(0);
      expect(ventana.map((r) => r.nombre), [
        'Nak Rian III',
        'Nak Rian II',
        'Nak Rian I',
      ]);
    });

    test('cerca del tope completa hacia atrás con rangos ya obtenidos', () {
      // 170 clases → Yod Muay II (índice 14): solo queda 1 por alcanzar.
      final ventana = RankingService.ventanaDeRangos(170);
      expect(ventana.map((r) => r.nombre), [
        'Yod Muay III',
        'Yod Muay II',
        'Yod Muay I',
      ]);
    });

    test('en el máximo muestra los últimos 3, todos obtenidos', () {
      final ventana = RankingService.ventanaDeRangos(999);
      expect(ventana.map((r) => r.nombre), [
        'Yod Muay III',
        'Yod Muay II',
        'Yod Muay I',
      ]);
      final actual = RankingService.rangoDesdeClases(999);
      expect(ventana.every((r) => r.index <= actual.index), isTrue);
    });
  });

  group('configurabilidad del umbral', () {
    test('la progresión depende solo de clasesPorDivision', () {
      const umbral = RankingService.clasesPorDivision;
      expect(RankingService.rangoDesdeClases(umbral - 1).index, 0);
      expect(RankingService.rangoDesdeClases(umbral).index, 1);
      expect(
        RankingService.clasesParaRango(RankingService.indiceMaximo),
        umbral * RankingService.indiceMaximo,
      );
    });
  });
}
