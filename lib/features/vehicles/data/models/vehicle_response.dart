class VehicleResponse {
  final List<VehicleDetail> vehicles;

  VehicleResponse({required this.vehicles});

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    return VehicleResponse(
      vehicles: (json['vehicles'] as List<dynamic>?)
              ?.map((v) => VehicleDetail.fromJson(v))
              .toList() ??
          [],
    );
  }
}

class VehicleDetail {
  final int id;
  final String make;
  final String modelType;
  final int year;
  final String color;
  final String licensePlate;
  final int seats;
  final List<VehiclePhoto> photos;
  final bool ac;
  final String vehicleType;
  final bool isDefault;
  final bool isVerified;

  VehicleDetail({
    required this.id,
    required this.make,
    required this.modelType,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.seats,
    required this.photos,
    required this.ac,
    required this.vehicleType,
    required this.isDefault,
    required this.isVerified,
  });

  factory VehicleDetail.fromJson(Map<String, dynamic> json) {
    return VehicleDetail(
      id: json['ID'] ?? 0,
      make: json['Make'] ?? '',
      modelType: json['ModelType'] ?? '',
      year: json['Year'] ?? 0,
      color: json['Color'] ?? '',
      licensePlate: json['LicensePlate'] ?? '',
      seats: json['Seats'] ?? 0,
      photos: (json['Photos'] as List<dynamic>?)
              ?.map((p) => VehiclePhoto.fromJson(p))
              .toList() ??
          [],
      ac: json['Ac'] ?? false,
      vehicleType: json['VehicleType'] ?? '',
      isDefault: json['IsDefault'] ?? false,
      isVerified: json['IsVerified'] ?? false,
    );
  }

  VehiclePhoto? get primaryPhoto {
    try {
      return photos.firstWhere((photo) => photo.isPrimary);
    } catch (e) {
      return photos.isNotEmpty ? photos.first : null;
    }
  }

  String get displayName => '$make $modelType';
}

class VehiclePhoto {
  final int id;
  final String url;
  final bool isPrimary;

  VehiclePhoto({
    required this.id,
    required this.url,
    required this.isPrimary,
  });

  factory VehiclePhoto.fromJson(Map<String, dynamic> json) {
    return VehiclePhoto(
      id: json['ID'] ?? 0,
      url: json['URL'] ?? '',
      isPrimary: json['IsPrimary'] ?? false,
    );
  }
}
