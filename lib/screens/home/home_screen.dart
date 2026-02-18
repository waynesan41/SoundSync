// =============================================
// home_screen.dart
// The main screen users see when they open the app.
//
// Layout (top to bottom):
//   1. Search bar ("Where to?")
//   2. Map area with overlays (weather, Ask, Nearby)
//   3. Bottom sheet:
//      - "Leave NOW" departure alert (yellow banner)
//      - Route cards with arrival times + confidence %
//
// Data comes from MockData — swap for API later.
// =============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../widgets/route_badge.dart';
import '../route_detail/route_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ====== LAYER 1: MAP BACKGROUND ======
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE8F0E8),
            child: CustomPaint(
              painter: _MapPlaceholderPainter(),
            ),
          ),

          // ====== LAYER 2: TOP OVERLAYS ======
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWeatherChip(),
                      const Spacer(),
                      Column(
                        children: [
                          _buildActionButton(
                            Icons.chat_bubble_outline_rounded,
                            'Ask',
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            Icons.location_on,
                            'Nearby',
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ====== LAYER 3: BUS MARKER ON MAP ======
          Positioned(
            top: MediaQuery.of(context).size.height * 0.38,
            left: MediaQuery.of(context).size.width * 0.35,
            child: _buildBusMarker('271'),
          ),

          // ====== LAYER 4: LOCATION LABEL ======
          Positioned(
            top: MediaQuery.of(context).size.height * 0.48,
            left: MediaQuery.of(context).size.width * 0.35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Bellevue College',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // ====== LAYER 5: CURRENT LOCATION DOT ======
          Positioned(
            top: MediaQuery.of(context).size.height * 0.52,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),

          // ====== LAYER 6: BOTTOM SHEET ======
          _buildBottomSheet(context),
        ],
      ),
    );
  }

  // ==========================================
  // SEARCH BAR
  // ==========================================
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppTheme.textMuted, size: 22),
            const SizedBox(width: 12),
            Text(
              'Where to?',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.mic_none_rounded, color: AppTheme.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WEATHER CHIP
  // ==========================================
  Widget _buildWeatherChip() {
    final w = MockData.weather;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${w.tempF}°F',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                w.condition,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION BUTTONS - Ask / Nearby
  // ==========================================
  Widget _buildActionButton(IconData icon, String label, {Color? color}) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? AppTheme.textSecondary, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BUS MARKER
  // ==========================================
  Widget _buildBusMarker(String routeId) {
    final color = AppTheme.getRouteColor(routeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚌 ', style: TextStyle(fontSize: 14)),
          Text(
            routeId,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEET
  // ==========================================
  Widget _buildBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.70,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // "Leave NOW" alert
              _buildLeaveNowAlert(),
              const SizedBox(height: 16),

              // Route cards (NOW TAPPABLE → opens Route Detail)
              ...MockData.nearbyRoutes.map(
                (route) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRouteCard(route, context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // LEAVE NOW ALERT
  // ==========================================
  Widget _buildLeaveNowAlert() {
    final alert = MockData.leaveNowAlert;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave NOW for Route ${alert.routeId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Arrives in ${alert.arrivalMin} min · ${alert.message}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Text(
              'GO',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROUTE CARD (tappable → opens Route Detail)
  // CHANGED: added GestureDetector + context param
  // ==========================================
  Widget _buildRouteCard(NearbyRoute route, BuildContext context) {
    Color confBg;
    Color confFg;
    if (route.confidence >= 90) {
      confBg = AppTheme.accentLight;
      confFg = AppTheme.accent;
    } else if (route.confidence >= 80) {
      confBg = AppTheme.warningLight;
      confFg = AppTheme.warning;
    } else {
      confBg = AppTheme.errorLight;
      confFg = AppTheme.error;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RouteDetailScreen(route: route),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            RouteBadge(routeId: route.id, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                route.destination,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${route.arrivalMin} min',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: confBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${route.confidence}% confident',
                    style: TextStyle(
                      color: confFg,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MAP PLACEHOLDER PAINTER
// ==========================================
class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD0D8D0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (double y = 100; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (double x = 60; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    final routePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.3,
      size.width * 0.3, size.height * 0.7,
    );
    canvas.drawPath(path, routePaint);

    final greenPaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final greenPath = Path();
    greenPath.moveTo(size.width * 0.8, size.height * 0.3);
    greenPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.5,
      size.width * 0.3, size.height * 0.7,
    );
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}