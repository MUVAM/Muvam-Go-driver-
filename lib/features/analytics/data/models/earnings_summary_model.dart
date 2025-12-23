class EarningsSummary {
  final double totalEarnings;
  final double totalTips;
  final double totalBonuses;
  final double commission;
  final double netPayout;
  final double cashEarnings;
  final double cardEarnings;
  final int totalRides;
  final int onlineHours;
  final int onlineMinutes;
  final double earningsPerHour;
  final String period;
  final String startDate;
  final String endDate;
  final double commissionRemitted;
  final double commissionPending;
  final double cashRidesRemitted;
  final double cashRidesPending;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalTips,
    required this.totalBonuses,
    required this.commission,
    required this.netPayout,
    required this.cashEarnings,
    required this.cardEarnings,
    required this.totalRides,
    required this.onlineHours,
    required this.onlineMinutes,
    required this.earningsPerHour,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.commissionRemitted,
    required this.commissionPending,
    required this.cashRidesRemitted,
    required this.cashRidesPending,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      totalTips: (json['total_tips'] ?? 0).toDouble(),
      totalBonuses: (json['total_bonuses'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      netPayout: (json['net_payout'] ?? 0).toDouble(),
      cashEarnings: (json['cash_earnings'] ?? 0).toDouble(),
      cardEarnings: (json['card_earnings'] ?? 0).toDouble(),
      totalRides: (json['total_rides'] ?? 0).toInt(),
      onlineHours: (json['online_hours'] ?? 0).toInt(),
      onlineMinutes: (json['online_minutes'] ?? 0).toInt(),
      earningsPerHour: (json['earnings_per_hour'] ?? 0).toDouble(),
      period: json['period'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      commissionRemitted: (json['commission_remitted'] ?? 0).toDouble(),
      commissionPending: (json['commission_pending'] ?? 0).toDouble(),
      cashRidesRemitted: (json['cash_rides_remitted'] ?? 0).toDouble(),
      cashRidesPending: (json['cash_rides_pending'] ?? 0).toDouble(),
    );
  }
}

class EarningsOverview {
  final String period;
  final double totalEarnings;
  final String startDate;
  final String endDate;

  EarningsOverview({
    required this.period,
    required this.totalEarnings,
    required this.startDate,
    required this.endDate,
  });

  factory EarningsOverview.fromJson(Map<String, dynamic> json) {
    return EarningsOverview(
      period: json['period'] ?? '',
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}
