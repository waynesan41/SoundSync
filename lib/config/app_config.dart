class AppConfig {
  // Backend URL - 10.0.2.2 reaches localhost from Android emulator
  static const String baseURL = 'http://10.0.2.2:8080';

  // Auth
  static const String loginEndpoint  = '/api/v1/auth/login';
  static const String signupEndpoint = '/api/v1/auth/signup';
  static const String logoutEndpoint = '/api/v1/auth/logout';

  // Arrivals
  static const String arrivalsEndpoint     = '/api/v1/arrivals';
  static const String arrivalStatsEndpoint = '/api/v1/arrivals/stats';

  // Predictions
  static const String predictDelayEndpoint    = '/api/v1/predictions/delay';
  static const String predictCrowdingEndpoint = '/api/v1/predictions/crowding';

  // Bellevue College coordinates (center of map)
  static const double defaultLat  = 47.5801;
  static const double defaultLng  = -122.1486;
  static const double defaultZoom = 14.0;

  static const Duration httpTimeout = Duration(seconds: 10);
}
