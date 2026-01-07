class EarningsBreakdown {
  final String period;
  final double totalEarned;
  final double grossEarning;
  final double tipsReceived;
  final double platformFee;
  final double netPayout;
  final String startDate;
  final String endDate;

  EarningsBreakdown({
    required this.period,
    required this.totalEarned,
    required this.grossEarning,
    required this.tipsReceived,
    required this.platformFee,
    required this.netPayout,
    required this.startDate,
    required this.endDate,
  });

  factory EarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdown(
      period: json['period'] ?? '',
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      grossEarning: (json['gross_earning'] ?? 0).toDouble(),
      tipsReceived: (json['tips_received'] ?? 0).toDouble(),
      platformFee: (json['platform_fee'] ?? 0).toDouble(),
      netPayout: (json['net_payout'] ?? 0).toDouble(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}
