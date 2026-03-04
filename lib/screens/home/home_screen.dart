import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../widgets/route_badge.dart';
import '../route_detail/route_detail_screen.dart';
import '../trip_assistant/trip_assistant_screen.dart';
import '../map_view/map_view_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<NearbyRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  // TODO: swap with Wayne's API
  Future<void> _loadRoutes() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() { _routes = MockData.nearbyRoutes; _isLoading = false; });
    } catch (e) {
      setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Color _statusColor(String status) {
    if (status == 'delayed') return AppTheme.error;
    return AppTheme.accent;
  }

  String _statusLabel(String status) {
    if (status == 'delayed') return 'Delayed';
    return 'On Time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // map bg
          Container(
            width: double.infinity, height: double.infinity,
            color: const Color(0xFFE8F0E8),
            child: CustomPaint(painter: _MapBgPainter()),
          ),
          // bus marker
          Positioned(
            top: MediaQuery.of(context).size.height * 0.38,
            left: MediaQuery.of(context).size.width * 0.35,
            child: _busMarker('271'),
          ),
          // bellevue college label
          Positioned(
            top: MediaQuery.of(context).size.height * 0.48,
            left: MediaQuery.of(context).size.width * 0.35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              child: const Text('Bellevue College',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
          ),
          // blue dot
          Positioned(
            top: MediaQuery.of(context).size.height * 0.52,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, spreadRadius: 3)],
              ),
            ),
          ),
          // bottom sheet goes BEFORE top buttons so it doesnt block taps
          _bottomSheet(context),
          // search + action buttons on top of everything
          SafeArea(
            child: Column(
              children: [
                _searchBar(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _weatherChip(),
                      const Spacer(),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => TripAssistantScreen())),
                            child: _actionBtn(Icons.chat_bubble_outline_rounded, 'Ask'),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => MapViewScreen())),
                            child: _actionBtn(Icons.location_on, 'Nearby', color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => SearchScreen())),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTheme.textMuted, size: 22),
              const SizedBox(width: 12),
              Text('Where to?', style: TextStyle(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.mic_none_rounded, color: AppTheme.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherChip() {
    final w = MockData.weather;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${w.tempF}°F', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
              Text(w.condition, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, {Color? color}) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? AppTheme.textSecondary, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _busMarker(String id) {
    final c = AppTheme.getRouteColor(id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c, borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚌 ', style: TextStyle(fontSize: 14)),
          Text(id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _bottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.25,
      maxChildSize: 0.70,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading routes...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  ]),
                ),
              )
            : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
                      const SizedBox(height: 12),
                      const Text('Something went wrong',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('Could not load routes',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _loadRoutes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                )
              : ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Center(child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                    )),
                    _leaveNowAlert(),
                    const SizedBox(height: 16),
                    ..._routes.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _routeCard(r, context),
                    )),
                  ],
                ),
        );
      },
    );
  }

  Widget _leaveNowAlert() {
    final a = MockData.leaveNowAlert;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave NOW for Route ${a.routeId}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('Arrives in ${a.arrivalMin} min · ${a.message}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border)),
            child: const Text('GO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(NearbyRoute route, BuildContext context) {
    Color confBg, confFg;
    if (route.confidence >= 90) {
      confBg = AppTheme.accentLight; confFg = AppTheme.accent;
    } else if (route.confidence >= 80) {
      confBg = AppTheme.warningLight; confFg = AppTheme.warning;
    } else {
      confBg = AppTheme.errorLight; confFg = AppTheme.error;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => RouteDetailScreen(route: route))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(width: 5, height: 80, color: _statusColor(route.status)),
            const SizedBox(width: 10),
            RouteBadge(routeId: route.id, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.destination,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(_statusLabel(route.status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(route.status))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${route.arrivalMin} min',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: confBg, borderRadius: BorderRadius.circular(20)),
                  child: Text('${route.confidence}%', style: TextStyle(color: confFg, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _MapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xFFD0D8D0)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (double y = 100; y < size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    }
    for (double x = 60; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    }
    final blue = Paint()..color = AppTheme.primary..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final p1 = Path()..moveTo(size.width * 0.5, 0)..quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.3, size.height * 0.7);
    canvas.drawPath(p1, blue);
    final green = Paint()..color = AppTheme.accent..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final p2 = Path()..moveTo(size.width * 0.8, size.height * 0.3)..quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.3, size.height * 0.7);
    canvas.drawPath(p2, green);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}