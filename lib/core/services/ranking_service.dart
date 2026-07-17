/// Sistema de rangos Muay Thai basado en asistencia acumulada.
///
/// El rango se deriva directamente del total histórico de clases asistidas:
/// bookings con status == 'attended', que solo se alcanza por check-in QR
/// en el gimnasio o por aprobación del admin (las confirmaciones por app
/// quedan en 'pendingApproval' y no cuentan hasta ser aprobadas). No
/// requiere jobs mensuales ni estado extra, y nunca desciende porque el
/// contador solo crece.
///
/// Progresión: cada [RankingService.clasesPorDivision] clases acumuladas
/// se sube una división. 4 tiers × 4 divisiones = 16 rangos:
/// Nak Rian IV → ... → Nak Rian I → Nak Muay IV → ... → Yod Muay I.
library;

/// Rango alcanzado: tier + división.
class MuayThaiRank {
  /// Índice global 0..15 (0 = Nak Rian IV, 15 = Yod Muay I).
  final int index;
  final String tier;
  final String division;

  const MuayThaiRank({
    required this.index,
    required this.tier,
    required this.division,
  });

  String get nombre => '$tier $division';

  bool get esMaximo => index == RankingService.indiceMaximo;

  @override
  bool operator ==(Object other) =>
      other is MuayThaiRank && other.index == index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'MuayThaiRank($index: $nombre)';
}

class RankingService {
  RankingService._();

  /// Umbral de clases por división. Cambiar este valor reajusta
  /// toda la progresión.
  static const int clasesPorDivision = 12;

  /// Tiers de menor a mayor.
  static const List<String> tiers = [
    'Nak Rian',
    'Nak Muay',
    'Nak Su',
    'Yod Muay',
  ];

  /// Divisiones de menor a mayor dentro de cada tier.
  static const List<String> divisiones = ['IV', 'III', 'II', 'I'];

  static int get totalRangos => tiers.length * divisiones.length;

  static int get indiceMaximo => totalRangos - 1;

  /// Rango correspondiente a un índice global 0..[indiceMaximo].
  static MuayThaiRank rangoPorIndice(int index) {
    final i = index.clamp(0, indiceMaximo);
    return MuayThaiRank(
      index: i,
      tier: tiers[i ~/ divisiones.length],
      division: divisiones[i % divisiones.length],
    );
  }

  /// Rango actual según el total acumulado de clases asistidas.
  ///
  /// division_index = min(floor(clases / clasesPorDivision), indiceMaximo)
  static MuayThaiRank rangoDesdeClases(int clasesTotales) {
    final clases = clasesTotales < 0 ? 0 : clasesTotales;
    return rangoPorIndice(clases ~/ clasesPorDivision);
  }

  /// Clases acumuladas necesarias para alcanzar el rango [index].
  static int clasesParaRango(int index) =>
      index.clamp(0, indiceMaximo) * clasesPorDivision;

  /// Siguiente rango a alcanzar, o `null` si ya está en el máximo.
  static MuayThaiRank? siguienteRango(int clasesTotales) {
    final actual = rangoDesdeClases(clasesTotales);
    if (actual.esMaximo) return null;
    return rangoPorIndice(actual.index + 1);
  }

  /// Progreso dentro de la división actual (0..[clasesPorDivision]).
  ///
  /// En el rango máximo devuelve [clasesPorDivision] (barra llena).
  static int progresoEnDivision(int clasesTotales) {
    final clases = clasesTotales < 0 ? 0 : clasesTotales;
    if (rangoDesdeClases(clases).esMaximo) return clasesPorDivision;
    return clases % clasesPorDivision;
  }

  /// Clases que faltan para subir a la siguiente división
  /// (0 si ya está en el rango máximo).
  static int clasesParaSiguienteRango(int clasesTotales) {
    if (siguienteRango(clasesTotales) == null) return 0;
    return clasesPorDivision - progresoEnDivision(clasesTotales);
  }

  /// Ventana de [count] rangos para mostrar como milestones: los próximos
  /// rangos a alcanzar y, cerca del tope, se completa hacia atrás con los
  /// últimos ya obtenidos (que la UI muestra iluminados).
  static List<MuayThaiRank> ventanaDeRangos(int clasesTotales, {int count = 3}) {
    final actual = rangoDesdeClases(clasesTotales);
    final fin = (actual.index + count).clamp(0, indiceMaximo);
    final inicio = (fin - count + 1).clamp(0, indiceMaximo);
    return [for (var i = inicio; i <= fin; i++) rangoPorIndice(i)];
  }
}
