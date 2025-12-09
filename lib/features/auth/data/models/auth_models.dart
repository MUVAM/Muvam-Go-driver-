class VerifyOtpResponse {
  final String token;
  final String message;
  final bool isNew;

  VerifyOtpResponse({required this.token, required this.message, required this.isNew});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      token: json['token'] ?? '',
      message: json['message'] ?? '',
      isNew: json['isNew'] ?? true,
    );
  }
}

class RegisterUserResponse {
  final String token;
  final String message;
  final Map<String, dynamic> user;

  RegisterUserResponse({required this.token, required this.message, required this.user});

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) {
    return RegisterUserResponse(
      token: json['token'] ?? '',
      message: json['message'] ?? '',
      user: json['user'] ?? {},
    );
  }
}

class RegisterUserRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String city;
  final String location;

  RegisterUserRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.city,
    required this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName ?? '',
      'last_name': lastName,
      'email': email,
      'Phone': phoneNumber,
      'date_of_birth': dateOfBirth,
      'city': city,
      'role': 'driver',
      'location': location,
    };
  }
}

class CompleteProfileRequest {
  final String firstName;
  final String lastName;
  final String email;

  CompleteProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }
}