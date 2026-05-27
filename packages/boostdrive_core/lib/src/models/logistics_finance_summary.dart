import 'delivery_order.dart';

/// Aggregated earnings and delivery stats for BaTLorriH logistics providers.
class LogisticsFinanceSummary {
  final double lifetimeEarnings;
  final double periodEarnings;
  final double pendingPayouts;
  final int completedCount;
  final int activeCount;
  final int cancelledCount;
  final List<DeliveryOrder> recentCompleted;

  const LogisticsFinanceSummary({
    required this.lifetimeEarnings,
    required this.periodEarnings,
    required this.pendingPayouts,
    required this.completedCount,
    required this.activeCount,
    required this.cancelledCount,
    this.recentCompleted = const [],
  });
}
