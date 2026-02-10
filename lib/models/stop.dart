import 'coordinate.dart';

class Stop {
  final String id;
  final String name;
  final Coordinate location;
  final int? sequence;

  const Stop({
    required this.id,
    required this.name,
    required this.location,
    this.sequence,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as String,
      name: json['name'] as String,
      location: Coordinate.fromJson(json['location']),
      sequence: json['sequence'] as int?,
    );
  }
}
