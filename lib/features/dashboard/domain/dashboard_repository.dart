import 'dashboard_entity.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> fetch();
}
