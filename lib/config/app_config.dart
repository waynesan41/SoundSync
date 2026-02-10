class AppConfig {
  // Waynes backend URL - will change once he deploys 
  static const String baseURL = 'http://10.0.2.2:8080';

  // API endpoints 
  static const String routesEndPoint = '/routes';
  static const String routeByEndPoint = 'route';
  static const String llmExplainEndPoint = '/llm/explain';

  // Bellevue college coordinates (will be the center of our map)
  static const double defaultLat = 47.5801;
  static const double defaultLng = -122.1486;
  static const double defaultZoom = 14.0;

  // How long yo wait before giving up on our API call
  static const Duration httpTimeout = Duration(seconds: 10);
}