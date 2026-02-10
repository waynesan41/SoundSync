class Coordinate {
  final double lat;
  final double lng;

  const Coordinate({required this.lat, required this.lng});

  // Turns JSON like {"lat": 47.58, "lng": -122.14} into a Coordinate object
  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  // Turns a Coordinate object back into JSON
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}