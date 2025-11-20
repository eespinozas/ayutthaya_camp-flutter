import '../domain/dashboard_entity.dart';

class DashboardDto {
  final String? planName;
  final int classesRemaining;
  final String? vigenciaHasta;
  final String membershipStatus;
  final int agendadas;
  final int asistidas;
  final int noAsistidas;
  final int lastAmountCents;
  final String? lastStatus;

  DashboardDto({
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

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    final lp = (json['last_payment'] as Map?) ?? {};
    return DashboardDto(
      planName: json['plan_name'] as String?,
      classesRemaining: (json['classes_remaining'] ?? 0) as int,
      vigenciaHasta: (json['vigencia_hasta'] as String?),
      membershipStatus: (json['membership_status'] ?? '—') as String,
      agendadas: (json['agendadas'] ?? 0) as int,
      asistidas: (json['asistidas'] ?? 0) as int,
      noAsistidas: (json['no_asistidas'] ?? 0) as int,
      lastAmountCents: (lp['amount_cents'] ?? 0) as int,
      lastStatus: (lp['status'] ?? '—') as String?,
    );
  }

  DashboardEntity toEntity() => DashboardEntity(
        planName: planName,
        classesRemaining: classesRemaining,
        vigenciaHasta: vigenciaHasta,
        membershipStatus: membershipStatus,
        agendadas: agendadas,
        asistidas: asistidas,
        noAsistidas: noAsistidas,
        lastAmountCents: lastAmountCents,
        lastStatus: lastStatus,
      );
}
