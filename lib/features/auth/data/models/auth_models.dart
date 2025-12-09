<<<<<<< HEAD
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
=======
class SendOtpRequest {
  final String phone;

  SendOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {"phone": phone};
}

class VerifyOtpRequest {
  final String code;
  final String phone;

  VerifyOtpRequest({required this.code, required this.phone});

  Map<String, dynamic> toJson() => {"code": code, "phone": phone};
}

class RegisterUserRequest {
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String role;

  RegisterUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
    "phone": phone,
    "role": role,
  };
}

class ApiResponse {
  final String message;

  ApiResponse({required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      ApiResponse(message: json['message']);
}

class VerifyOtpResponse {
  final bool isNew;
  final String message;
  final String token;
  final Map<String, dynamic> user;

  VerifyOtpResponse({
    required this.isNew,
    required this.message,
    required this.token,
    required this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        isNew: json['isNew'],
        message: json['message'],
        token: json['token'],
        user: json['user'],
      );
}

class RegisterUserResponse {
  final String message;
  final Map<String, dynamic> user;

  RegisterUserResponse({required this.message, required this.user});

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) =>
      RegisterUserResponse(message: json['message'], user: json['user']);
>>>>>>> 2289b2e4d7d38c7d08cda86f7e37c3cd9ca96808
}

class CompleteProfileRequest {
  final String firstName;
<<<<<<< HEAD
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
=======
  final String? middleName;
  final String lastName;
  final String email;
  final String? profilePhotoPath;

  CompleteProfileRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.profilePhotoPath,
  });
}
>>>>>>> 2289b2e4d7d38c7d08cda86f7e37c3cd9ca96808
