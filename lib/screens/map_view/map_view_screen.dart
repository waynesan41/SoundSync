import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/mock_data.dart';
import '../../widgets/route_badge.dart';
import '../route_detail/route_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  bool _loading = true;
  bool _error = false;
  List<NearbyRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() { _loading = true; _error = false; });
    try {
      final routes = await ApiService.fetchArrivals();
      setState(() { _routes = routes; _loading = false; });
    } catch (e) {
      setState(() { _error = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Nearby Stops', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // map placeholder
          // TODO: replace with actual google maps + polylines
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: const Color(0xFFE8F0E8),
              child: Stack(
                children: [
                  CustomPaint(size: Size.infinite, painter: _GridPainter()),
                  // fake stop markers on the map
                  _mapMarker(0.3, 0.25, '271', AppTheme.getRouteColor('271')),
                  _mapMarker(0.6, 0.4, 'B Line', AppTheme.getRouteColor('B Line')),
                  _mapMarker(0.45, 0.6, '550', AppTheme.getRouteColor('550')),
                  _mapMarker(0.2, 0.7, '245', AppTheme.getRouteColor('245')),
                  _mapMarker(0.7, 0.75, '241', AppTheme.getRouteColor('241')),
                  // current location dot
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: MediaQuery.of(context).size.width * 0.45,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.primary, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)],
                      ),
                    ),
                  ),
                  // "you are here" label
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15 + 22,
                    left: MediaQuery.of(context).size.width * 0.35,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(6),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                      ),
                      child: const Text('You are here',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // bottom list of nearby routes
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -3))],
              ),
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 36),
                        const SizedBox(height: 8),
                        const Text('Could not load stops', style: TextStyle(color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _loadNearby,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        const Text('Nearby Routes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        ..._routes.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => RouteDetailScreen(route: r))),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(children: [
                                RouteBadge(routeId: r.id, size: 40),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.destination,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('${r.arrivalMin} min away',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                )),
                                // confidence color
                                Text('${r.confidence}%', style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: r.confidence >= 90 ? AppTheme.accent
                                    : r.confidence >= 80 ? AppTheme.warning : AppTheme.error)),
                              ]),
                            ),
                          ),
                        )),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // puts a colored marker on the map at relative position
  Widget _mapMarker(double xPct, double yPct, String label, Color color) {
    return Positioned(
      left: MediaQuery.of(context).size.width * xPct,
      top: MediaQuery.of(context).size.height * 0.35 * yPct,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          // little triangle pointer
          CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(color)),
        ],
      ),
    );
  }
}

// draws grid lines to fake a map background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFD0D8D0)..strokeWidth = 1..style = PaintingStyle.stroke;
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    for (double x = 0; x < size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// tiny triangle under map markers
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}