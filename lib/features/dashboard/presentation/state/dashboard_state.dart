import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/entities/exception_entity.dart';
import '../../domain/entities/ai_alert_entity.dart';

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.summary,
    this.exceptions = const [],
    this.aiAlerts = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final DashboardSummaryEntity? summary;
  final List<ExceptionEntity> exceptions;
  final List<AiAlertEntity> aiAlerts;
  final String? errorMessage;

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummaryEntity? summary,
    List<ExceptionEntity>? exceptions,
    List<AiAlertEntity>? aiAlerts,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      exceptions: exceptions ?? this.exceptions,
      aiAlerts: aiAlerts ?? this.aiAlerts,
      errorMessage: errorMessage,
    );
  }
}
