import '../models/coordinate.dart';
import '../models/stop.dart';
import '../models/route.dart';

class MockData {
  static final List<TransitRoute> routes = [
    TransitRoute(
      id: 'route_271',
      shortName: '271',
      longName: 'Bellevue – Issaquah via Eastgate',
      description: 'Frequent service connecting Bellevue College to Downtown Bellevue and Issaquah.',
      color: '3B82F6',
      agencyName: 'King County Metro',
    ),
    TransitRoute(
      id: 'route_b_line',
      shortName: 'B Line',
      longName: 'Bellevue – Redmond Rapid Ride',
      description: 'Rapid Ride service between Bellevue TC and Redmond TC.',
      color: 'EF4444',
      agencyName: 'King County Metro',
    ),
    TransitRoute(
      id: 'route_245',
      shortName: '245',
      longName: 'Kirkland – Bellevue – Factoria',
      description: 'Crosstown service linking Kirkland and Factoria.',
      color: '10B981',
      agencyName: 'King County Metro',
    ),
    TransitRoute(
      id: 'route_550',
      shortName: '550',
      longName: 'Bellevue – Seattle via I-90',
      description: 'Express service to Downtown Seattle.',
      color: '8B5CF6',
      agencyName: 'Sound Transit',
    ),
    TransitRoute(
      id: 'route_241',
      shortName: '241',
      longName: 'Bellevue – Eastgate – Factoria',
      description: 'Local service around Bellevue College area.',
      color: 'F59E0B',
      agencyName: 'King County Metro',
    ),
  ];

  // Full detail for route 271 with stops
  static final TransitRoute route271Detail = TransitRoute(
    id: 'route_271',
    shortName: '271',
    longName: 'Bellevue – Issaquah via Eastgate',
    description: 'Frequent service connecting Bellevue College to Downtown Bellevue and Issaquah.',
    color: '3B82F6',
    agencyName: 'King County Metro',
    stops: [
      Stop(
        id: 'stop_1',
        name: 'Bellevue Transit Center',
        location: Coordinate(lat: 47.6153, lng: -122.1970),
        sequence: 1,
      ),
      Stop(
        id: 'stop_2',
        name: 'SE 8th St & 112th Ave SE',
        location: Coordinate(lat: 47.6080, lng: -122.1880),
        sequence: 2,
      ),
      Stop(
        id: 'stop_3',
        name: 'Bellevue College',
        location: Coordinate(lat: 47.5801, lng: -122.1486),
        sequence: 3,
      ),
      Stop(
        id: 'stop_4',
        name: 'Eastgate Park & Ride',
        location: Coordinate(lat: 47.5731, lng: -122.1395),
        sequence: 4,
      ),
      Stop(
        id: 'stop_5',
        name: 'Issaquah Transit Center',
        location: Coordinate(lat: 47.5301, lng: -122.0326),
        sequence: 5,
      ),
    ],
  );

  // Filter routes by search query
  static List<TransitRoute> searchRoutes(String query) {
    if (query.isEmpty) return routes;
    final q = query.toLowerCase();
    return routes.where((r) {
      return r.shortName.toLowerCase().contains(q) ||
          r.longName.toLowerCase().contains(q);
    }).toList();
  }

  // Get route detail by ID
  static TransitRoute? getRouteById(String id) {
    if (id == 'route_271') return route271Detail;
    try {
      return routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}