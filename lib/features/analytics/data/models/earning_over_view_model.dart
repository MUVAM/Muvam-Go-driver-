class WeeklyOverviewData {
  final String period;
  final List<DailyEarning> dailyBreakdown;
  final double totalEarnings;
  final String startDate;
  final String endDate;

  WeeklyOverviewData({
    required this.period,
    required this.dailyBreakdown,
    required this.totalEarnings,
    required this.startDate,
    required this.endDate,
  });

  factory WeeklyOverviewData.fromJson(Map<String, dynamic> json) {
    return WeeklyOverviewData(
      period: json['period'] ?? '',
      dailyBreakdown:
          (json['daily_breakdown'] as List?)
              ?.map((item) => DailyEarning.fromJson(item))
              .toList() ??
          [],
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'daily_breakdown': dailyBreakdown.map((item) => item.toJson()).toList(),
      'total_earnings': totalEarnings,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}

class DailyEarning {
  final String date;
  final int dayOfWeek;
  final String dayLabel;
  final double amount;
  final int rideCount;

  DailyEarning({
    required this.date,
    required this.dayOfWeek,
    required this.dayLabel,
    required this.amount,
    required this.rideCount,
  });

  factory DailyEarning.fromJson(Map<String, dynamic> json) {
    return DailyEarning(
      date: json['date'] ?? '',
      dayOfWeek: json['day_of_week'] ?? 0,
      dayLabel: json['day_label'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      rideCount: json['ride_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_of_week': dayOfWeek,
      'day_label': dayLabel,
      'amount': amount,
      'ride_count': rideCount,
    };
  }
}
