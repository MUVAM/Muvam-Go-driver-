class UrlConstants {
  static const String baseUrl = "http://44.222.121.219/api/v1";
  static const String webSocketUrl = "ws://44.222.121.219/api/v1/ws";
  static const String wsUrl = "ws://44.222.121.219/api/v1/ws";
  static const String googleMapsApiKey =
      "AIzaSyBcA7Yq13sDyx-8nrLn0y0XMjY6xVcYVlE";

  // Authentication endpoints
  static const String sendOtp = "/otp/send";
  static const String resendOtp = "/otp/resend";
  static const String verifyOtp = "/otp/verify";
  static const String registerUser = "/users/register";
  static const String completeProfile = "/api/v1/users/profile/complete";
  static const String favouriteLocation = "/api/v1/users/favouriteLocation";
  static const String rideEstimate = "/rides/estimate";
  static const String rideRequest = "/rides/request";
  static const String walletSummary = "/wallet/summary";
  static const String rides = "/rides";
}
