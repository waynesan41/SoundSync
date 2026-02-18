// =============================================
// mock_data.dart
// Fake data that powers all screens.
// When Wayne's backend is ready, we swap this
// for real API calls — the screens don't change.
// =============================================

class NearbyRoute {
  final String id;          // "271", "B Line", etc.
  final String destination;  // "Seattle", "Redmond"
  final int arrivalMin;      // minutes until bus arrives
  final int confidence;      // AI confidence 0-100
  final String status;       // "on-time", "early", "delayed"

  const NearbyRoute({
    required this.id,
    required this.destination,
    required this.arrivalMin,
    required this.confidence,
    this.status = 'on-time',
  });
}

class WeatherData {
  final int tempF;
  final String condition;    // "Rain likely", "Sunny", etc.
  final String icon;         // emoji for now

  const WeatherData({
    required this.tempF,
    required this.condition,
    required this.icon,
  });
}

class DepartureAlert {
  final String routeId;
  final int arrivalMin;
  final String message;      // "Usually on time"

  const DepartureAlert({
    required this.routeId,
    required this.arrivalMin,
    required this.message,
  });
}

class MockData {
  // ---- HOME SCREEN DATA ----

  static const List<NearbyRoute> nearbyRoutes = [
    NearbyRoute(
      id: '271',
      destination: 'Seattle',
      arrivalMin: 4,
      confidence: 94,
      status: 'early',
    ),
    NearbyRoute(
      id: 'B Line',
      destination: 'Redmond',
      arrivalMin: 8,
      confidence: 87,
      status: 'on-time',
    ),
    NearbyRoute(
      id: '245',
      destination: 'Kirkland',
      arrivalMin: 12,
      confidence: 91,
      status: 'on-time',
    ),
    NearbyRoute(
      id: '550',
      destination: 'Downtown Seattle',
      arrivalMin: 15,
      confidence: 82,
      status: 'delayed',
    ),
    NearbyRoute(
      id: '241',
      destination: 'Eastgate',
      arrivalMin: 22,
      confidence: 88,
      status: 'on-time',
    ),
  ];

  static const WeatherData weather = WeatherData(
    tempF: 48,
    condition: 'Rain likely',
    icon: '🌧️',
  );

  static const DepartureAlert leaveNowAlert = DepartureAlert(
    routeId: '271',
    arrivalMin: 4,
    message: 'Usually on time',
  );

  // ---- ROUTE DETAIL SCREEN DATA ----

  static const List<Map<String, String>> route271Stops = [
    {'name': 'Bellevue College', 'time': '3:24 PM', 'tag': 'Next stop'},
    {'name': 'Eastgate P&R', 'time': '3:31 PM', 'tag': ''},
    {'name': 'Mercer Island', 'time': '3:38 PM', 'tag': ''},
    {'name': 'Rainier Ave S', 'time': '3:45 PM', 'tag': ''},
    {'name': 'U District', 'time': '3:52 PM', 'tag': 'Destination'},
  ];

  // ---- CONNECTION CHECKER DATA ----

  static const int transferSuccessRate = 94;
  static const int tripsAnalyzed = 347;
  static const String averageBuffer = '4 min 30 sec';

  // ---- TRIP ASSISTANT SAMPLE QUESTIONS ----

  static const List<String> sampleQuestions = [
    '"Will I make my 2pm class?"',
    '"What\'s the fastest way to UW?"',
    '"Is the B Line on time?"',
  ];
}