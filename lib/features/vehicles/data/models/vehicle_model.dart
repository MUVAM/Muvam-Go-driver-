class VehicleResponse {
  final List<Vehicle> vehicles;

  VehicleResponse({required this.vehicles});

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    return VehicleResponse(
      vehicles: (json['vehicles'] as List)
          .map((vehicle) => Vehicle.fromJson(vehicle))
          .toList(),
    );
  }
}

class Vehicle {
  final int id;
  final String createdAt;
  final String updatedAt;
  final int driverId;
  final String make;
  final String modelType;
  final int year;
  final String color;
  final String licensePlate;
  final int seats;
  final List<VehiclePhoto> photos;
  final bool ac;
  final String vehicleType;
  final String registrationPath;
  final String insurancePath;
  final bool isDefault;
  final bool isVerified;
  final int verifiedBy;
  final String? verifiedAt;
  final String rejectedReason;

  Vehicle({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.driverId,
    required this.make,
    required this.modelType,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.seats,
    required this.photos,
    required this.ac,
    required this.vehicleType,
    required this.registrationPath,
    required this.insurancePath,
    required this.isDefault,
    required this.isVerified,
    required this.verifiedBy,
    this.verifiedAt,
    required this.rejectedReason,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['ID'] ?? 0,
      createdAt: json['CreatedAt'] ?? '',
      updatedAt: json['UpdatedAt'] ?? '',
      driverId: json['DriverID'] ?? 0,
      make: json['Make'] ?? '',
      modelType: json['ModelType'] ?? '',
      year: json['Year'] ?? 0,
      color: json['Color'] ?? '',
      licensePlate: json['LicensePlate'] ?? '',
      seats: json['Seats'] ?? 0,
      photos:
          (json['Photos'] as List?)
              ?.map((photo) => VehiclePhoto.fromJson(photo))
              .toList() ??
          [],
      ac: json['Ac'] ?? false,
      vehicleType: json['VehicleType'] ?? '',
      registrationPath: json['RegistrationPath'] ?? '',
      insurancePath: json['InsurancePath'] ?? '',
      isDefault: json['IsDefault'] ?? false,
      isVerified: json['IsVerified'] ?? false,
      verifiedBy: json['VerifiedBy'] ?? 0,
      verifiedAt: json['VerifiedAt'],
      rejectedReason: json['RejectedReason'] ?? '',
    );
  }
}

class VehiclePhoto {
  final int id;
  final String createdAt;
  final String updatedAt;
  final int vehicleId;
  final String url;
  final bool isPrimary;

  VehiclePhoto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.vehicleId,
    required this.url,
    required this.isPrimary,
  });

  factory VehiclePhoto.fromJson(Map<String, dynamic> json) {
    return VehiclePhoto(
      id: json['ID'] ?? 0,
      createdAt: json['CreatedAt'] ?? '',
      updatedAt: json['UpdatedAt'] ?? '',
      vehicleId: json['VehicleID'] ?? 0,
      url: json['URL'] ?? '',
      isPrimary: json['IsPrimary'] ?? false,
    );
  }
}
