// =============================================
// route_badge.dart
// Reusable colored badge that shows a route number.
// Used on: Home, Route Detail, Connection Checker,
//          Alt Routes, AI Finder screens.
//
// Example usage:
//   RouteBadge(routeId: '271')         → blue box with "271"
//   RouteBadge(routeId: 'B Line')      → green box with "B Line"
//   RouteBadge(routeId: 'Link', size: 36) → smaller purple box
// =============================================

import 'package:flutter/material.dart';
import '../config/theme.dart';

class RouteBadge extends StatelessWidget {
  final String routeId;
  final double size;

  const RouteBadge({
    super.key,
    required this.routeId,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    // Get this route's branded color from theme
    final color = AppTheme.getRouteColor(routeId);

    return Container(
      // Wider for long names like "B Line"
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        // Light tinted background (15% opacity of the route color)
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          routeId,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}