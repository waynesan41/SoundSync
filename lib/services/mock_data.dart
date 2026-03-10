import '../models/route.dart';

class NearbyRoute {
  final String id;
  final String destination;
  final int arrivalMin;
  final int confidence;
  final String status;

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
  final String condition;
  final String icon;

  const WeatherData({
    required this.tempF,
    required this.condition,
    required this.icon,
  });
}

class DepartureAlert {
  final String routeId;
  final int arrivalMin;
  final String message;

  const DepartureAlert({
    required this.routeId,
    required this.arrivalMin,
    required this.message,
  });
}

class MockData {
  static const List<NearbyRoute> nearbyRoutes = [
    NearbyRoute(id: '271', destination: 'Seattle', arrivalMin: 4, confidence: 94, status: 'early'),
    NearbyRoute(id: 'B Line', destination: 'Redmond', arrivalMin: 8, confidence: 87, status: 'on-time'),
    NearbyRoute(id: '245', destination: 'Kirkland', arrivalMin: 12, confidence: 91, status: 'on-time'),
    NearbyRoute(id: '550', destination: 'Downtown Seattle', arrivalMin: 15, confidence: 82, status: 'delayed'),
    NearbyRoute(id: '241', destination: 'Eastgate', arrivalMin: 22, confidence: 88, status: 'on-time'),
  ];

  static const WeatherData weather = WeatherData(
    tempF: 48, condition: 'Rain likely', icon: '🌧️',
  );

  static const DepartureAlert leaveNowAlert = DepartureAlert(
    routeId: '271', arrivalMin: 4, message: 'Usually on time',
  );

  static const List<Map<String, String>> route271Stops = [
    {'name': 'Bellevue College', 'time': '3:24 PM', 'tag': 'Next stop'},
    {'name': 'Eastgate P&R', 'time': '3:31 PM', 'tag': ''},
    {'name': 'Mercer Island', 'time': '3:38 PM', 'tag': ''},
    {'name': 'Rainier Ave S', 'time': '3:45 PM', 'tag': ''},
    {'name': 'U District', 'time': '3:52 PM', 'tag': 'Destination'},
  ];

  static final List<TransitRoute> routes = [
    TransitRoute(id: '271', shortName: '271', longName: 'Bellevue College to U District', color: '3B82F6', agencyName: 'King County Metro'),
    TransitRoute(id: 'B Line', shortName: 'B Line', longName: 'RapidRide B Line', color: '10B981', agencyName: 'King County Metro'),
    TransitRoute(id: '245', shortName: '245', longName: 'Kirkland to Bellevue', color: 'F97316', agencyName: 'King County Metro'),
    TransitRoute(id: '550', shortName: '550', longName: 'Bellevue to Downtown Seattle', color: '8B5CF6', agencyName: 'Sound Transit'),
    TransitRoute(id: '241', shortName: '241', longName: 'Eastgate to Bellevue TC', color: 'F59E0B', agencyName: 'King County Metro'),
    TransitRoute(id: '556', shortName: '556', longName: 'Issaquah to U District', color: 'EC4899', agencyName: 'Sound Transit'),
  ];

  static List<TransitRoute> searchRoutes(String query) {
    if (query.isEmpty) return routes;
    final q = query.toLowerCase();
    return routes.where((r) =>
      r.shortName.toLowerCase().contains(q) ||
      r.longName.toLowerCase().contains(q) ||
      r.agencyName.toLowerCase().contains(q)
    ).toList();
  }
}