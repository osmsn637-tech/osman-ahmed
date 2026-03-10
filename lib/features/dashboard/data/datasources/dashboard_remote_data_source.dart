import '../../../../core/network/api_client.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/exception_entity.dart';
import '../../domain/entities/ai_alert_entity.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final ApiClient _client;

  Future<DashboardSummaryEntity> fetchSummary() async {
    final result = await _client.get<DashboardSummaryEntity>(
      '/dashboard/tasks',
      parser: (data) => DashboardSummaryModel.fromJson(data).toEntity(),
    );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<List<AiAlertEntity>> fetchAiAlerts() async {
    final result = await _client.get<List<AiAlertEntity>>(
      '/ai-alerts',
      parser: (data) => (data as List<dynamic>)
          .map((e) => AiAlertEntity(
                id: e['id'] as String,
                itemId: e['item_id'] as int,
                locationId: e['location_id'] as int,
                riskScore: e['risk_score'] as int,
                alertType: e['alert_type'] as String,
                message: (e['message'] as String?) ?? '',
                createdAt: DateTime.parse(e['created_at'] as String),
                resolved: e['resolved'] as bool? ?? false,
              ))
          .toList(),
    );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<List<ExceptionEntity>> fetchExceptions() async {
    final result = await _client.get<List<ExceptionEntity>>(
      '/exceptions',
      parser: (data) => (data as List<dynamic>)
          .map((e) => ExceptionEntity(
                id: e['id'] as int,
                itemName: e['item_name'] as String,
                expectedLocation: e['expected_location'] as String,
                warehouseId: e['warehouse_id'] as int,
                status: e['status'] as String,
              ))
          .toList(),
    );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }

  Future<void> resolveException({required int id, required String action}) async {
    final result = await _client.post<void>(
      '/exceptions/resolve',
      data: {'id': id, 'action': action},
    );
    return result.when(
      success: (_) => null,
      failure: (error) => throw error,
    );
  }
}
