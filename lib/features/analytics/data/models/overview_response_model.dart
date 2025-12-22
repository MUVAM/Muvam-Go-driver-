class OverviewResponse {
  final WeeklyOverviewData overview;
  final RecentRides recentRides;

  OverviewResponse({required this.overview, required this.recentRides});

  factory OverviewResponse.fromJson(Map<String, dynamic> json) {
    return OverviewResponse(
      overview: WeeklyOverviewData.fromJson(json['overview'] ?? {}),
      recentRides: RecentRides.fromJson(json['recent_rides'] ?? {}),
    );
  }
}

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
}

class RecentRides {
  final List<RecentRide> rides;
  final int count;

  RecentRides({required this.rides, required this.count});

  factory RecentRides.fromJson(Map<String, dynamic> json) {
    return RecentRides(
      rides:
          (json['rides'] as List?)
              ?.map((item) => RecentRide.fromJson(item))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class RecentRide {
  final int id;
  final String destinationAddress;
  final double amount;
  final String createdAt;

  RecentRide({
    required this.id,
    required this.destinationAddress,
    required this.amount,
    required this.createdAt,
  });

  factory RecentRide.fromJson(Map<String, dynamic> json) {
    return RecentRide(
      id: json['id'] ?? 0,
      destinationAddress: json['destination_address'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: json['created_at'] ?? '',
    );
  }
}
