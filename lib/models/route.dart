import 'package:flutter/material.dart';
import 'coordinate.dart';
import 'stop.dart';

class TransitRoute {
  final String id;
  final String shortName;
  final String longName;
  final String? description;
  final String color;
  final String agencyName;
  final List<Stop>? stops;
  final List<Coordinate>? polyline;

  const TransitRoute({
    required this.id,
    required this.shortName,
    required this.longName,
    this.description,
    required this.color,
    required this.agencyName,
    this.stops,
    this.polyline,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) {
    return TransitRoute(
      id: json['id'] as String,
      shortName: json['shortName'] as String,
      longName: json['longName'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '3B82F6',
      agencyName: json['agencyName'] as String? ?? 'Unknown',
      stops: json['stops'] != null
          ? (json['stops'] as List).map((s) => Stop.fromJson(s)).toList()
          : null,
      polyline: json['polyline'] != null
          ? (json['polyline'] as List).map((c) => Coordinate.fromJson(c)).toList()
          : null,
    );
  }

  // Converts hex string like "3B82F6" into a Flutter Color
  Color get routeColor {
    final hex = color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}