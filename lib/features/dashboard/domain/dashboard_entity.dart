class DashboardEntity {
  final String? planName;
  final int classesRemaining;
  final String? vigenciaHasta;
  final String membershipStatus;

  final int agendadas;
  final int asistidas;
  final int noAsistidas;

  final int lastAmountCents;
  final String? lastStatus;

  DashboardEntity({
    required this.planName,
    required this.classesRemaining,
    required this.vigenciaHasta,
    required this.membershipStatus,
    required this.agendadas,
    required this.asistidas,
    required this.noAsistidas,
    required this.lastAmountCents,
    required this.lastStatus,
  });

  factory DashboardEntity.empty() => DashboardEntity(
        planName: 'sin_plan',
        classesRemaining: 0,
        vigenciaHasta: null,
        membershipStatus: '—',
        agendadas: 0,
        asistidas: 0,
        noAsistidas: 0,
        lastAmountCents: 0,
        lastStatus: '—',
      );
}
