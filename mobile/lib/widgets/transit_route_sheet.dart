import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/route_planning_service.dart';
import 'reliability_card.dart';

class TransitRouteSheet extends StatelessWidget {
  final String destinationName;
  final List<TransitRoute> routes;
  final void Function(TransitRoute route)? onRouteSelected;

  const TransitRouteSheet({
    super.key,
    required this.destinationName,
    required this.routes,
    this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 1.0,
      expand: false,
      snap: true,
      snapSizes: const [0.3, 0.5, 0.75, 1.0],
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.directions_transit,
                      color: Color(0xFF7FDBFF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Routes to $destinationName',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: routes.isEmpty
                  ? const Center(
                      child: Text('No transit routes found.',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: routes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _RouteCard(
                        route: routes[i],
                        onGetDirections: onRouteSelected != null
                            ? () {
                                Navigator.of(context).pop();
                                onRouteSelected!(routes[i]);
                              }
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Route Card ──────────────────────────────────────────────────────────────

class _RouteCard extends StatefulWidget {
  final TransitRoute route;
  final VoidCallback? onGetDirections;
  const _RouteCard({required this.route, this.onGetDirections});

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    final merged = r.mergedSteps;
    final agencies = merged
        .where((s) => s.travelMode == 'TRANSIT' && s.agencyName != null)
        .map((s) => s.agencyName!)
        .toSet()
        .join(', ');

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF122340),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Text(r.totalDuration,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${r.departureTime}  →  ${r.arrivalTime}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        if (agencies.isNotEmpty)
                          Text(agencies,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pills summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _buildPills(merged)),
              ),
            ),

            // Expanded detail — timeline layout
            if (_expanded) ...[
              const Divider(height: 1, color: Colors.white10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  children: List.generate(merged.length, (i) {
                    final s = merged[i];
                    final isLast = i == merged.length - 1;
                    return s.travelMode == 'TRANSIT'
                        ? _TransitStepRow(step: s, isLast: isLast)
                        : _WalkStepRow(step: s, isLast: isLast);
                  }),
                ),
              ),
            ],

            // Footer: chevron + Get Directions button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white24, size: 20,
                  ),
                  const Spacer(),
                  if (widget.onGetDirections != null)
                    GestureDetector(
                      onTap: widget.onGetDirections,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7FDBFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_transit,
                                color: Color(0xFF0D1B2A), size: 16),
                            SizedBox(width: 6),
                            Text('Get Directions',
                                style: TextStyle(
                                    color: Color(0xFF0D1B2A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPills(List<RouteStep> steps) {
    final widgets = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.arrow_forward, color: Colors.white24, size: 14),
        ));
      }
      final s = steps[i];
      if (s.travelMode == 'TRANSIT') {
        widgets.add(_TransitPill(step: s));
      } else {
        widgets.add(_WalkPill(duration: s.duration));
      }
    }
    return widgets;
  }
}

// ─── Pills ────────────────────────────────────────────────────────────────────

class _TransitPill extends StatelessWidget {
  final RouteStep step;
  const _TransitPill({required this.step});

  @override
  Widget build(BuildContext context) {
    final label = step.lineShortName ?? step.lineName ?? '?';
    final stops = step.numStops != null
        ? '${step.numStops} stop${step.numStops! > 1 ? 's' : ''}'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C81),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_vehicleEmoji(step.vehicleType),
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          if (stops.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(stops,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
          const SizedBox(width: 4),
          Text(step.duration,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _WalkPill extends StatelessWidget {
  final String duration;
  const _WalkPill({required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚶', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(duration,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Timeline connector painters ──────────────────────────────────────────────

/// Draws a vertical dashed line (for walk segments).
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashH = 4.0;
    const gapH = 4.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dashH).clamp(0, size.height)), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Draws a solid vertical line (for transit segments).
class _SolidLinePainter extends CustomPainter {
  const _SolidLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Paint()
        ..color = const Color(0xFF0F4C81)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Step Rows ────────────────────────────────────────────────────────────────

/// Walk step — shows dotted connector line, weather at walk start.
class _WalkStepRow extends StatefulWidget {
  final RouteStep step;
  final bool isLast;
  const _WalkStepRow({required this.step, this.isLast = false});

  @override
  State<_WalkStepRow> createState() => _WalkStepRowState();
}

class _WalkStepRowState extends State<_WalkStepRow> {
  Map<String, dynamic>? _weather;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final lat = widget.step.startLat;
    final lng = widget.step.startLng;
    if (lat == null || lng == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final dio = buildApiClient();
      final resp = await dio.get('/weather',
          queryParameters: {'lat': lat, 'lng': lng});
      if (mounted) {
        setState(() {
          _weather = resp.data as Map<String, dynamic>;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final temp = (_weather?['temp'] as num?)?.round();
    final forecast = _weather?['description'] as String? ?? '';
    final emoji = temp != null ? _weatherEmoji(forecast) : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column: icon + dotted connector
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Text('🚶', style: TextStyle(fontSize: 16)),
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: const _DashedLinePainter(),
                        size: const Size(2, double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Walk details
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 4 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Walk ${step.distance}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      if (!_loaded)
                        const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.white24),
                        )
                      else if (emoji != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('$temp°F',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(step.duration,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                  if (forecast.isNotEmpty)
                    Text(forecast,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weatherEmoji(String forecast) {
    final f = forecast.toLowerCase();
    if (f.contains('thunder')) return '⛈️';
    if (f.contains('snow') || f.contains('blizzard')) return '🌨️';
    if (f.contains('rain') || f.contains('shower') || f.contains('drizzle'))
      return '🌧️';
    if (f.contains('fog') || f.contains('haze') || f.contains('mist'))
      return '🌫️';
    if (f.contains('wind')) return '💨';
    if (f.contains('partly cloudy') || f.contains('partly sunny')) return '⛅';
    if (f.contains('mostly cloudy') || f.contains('overcast')) return '☁️';
    if (f.contains('cloudy')) return '🌥️';
    if (f.contains('sunny') || f.contains('clear')) return '☀️';
    return '🌤️';
  }
}

/// Transit step — solid connector line, tappable departure/arrival stops.
class _TransitStepRow extends ConsumerWidget {
  final RouteStep step;
  final bool isLast;
  const _TransitStepRow({required this.step, this.isLast = false});

  void _showStopDetail(
    BuildContext context,
    WidgetRef ref,
    String stopName, {
    required bool isDeparture,
    String? stopId,
  }) {
    final time = isDeparture ? step.stepDepartureTime : step.stepArrivalTime;
    final line = step.lineShortName ?? step.lineName ?? '?';
    final routeId = step.lineName ?? '';
    final emoji = _vehicleEmoji(step.vehicleType);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Stop icon + name
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDeparture
                            ? const Color(0xFF0F4C81)
                            : const Color(0xFF1E3A5F),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isDeparture ? Icons.directions_walk : Icons.place,
                          color: Colors.white, size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDeparture ? 'Board here' : 'Alight here',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          Text(
                            stopName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Route info
                _DetailRow(
                  icon: Text(emoji, style: const TextStyle(fontSize: 18)),
                  label: 'Route',
                  value: line +
                      (step.headsign != null ? ' toward ${step.headsign}' : ''),
                ),

                if (time != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: const Icon(Icons.access_time,
                        color: Colors.white54, size: 18),
                    label: isDeparture ? 'Departs' : 'Arrives',
                    value: time,
                  ),
                ],

                if (isDeparture && step.numStops != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: const Icon(Icons.stop_circle_outlined,
                        color: Colors.white54, size: 18),
                    label: 'Stops',
                    value:
                        '${step.numStops} stop${step.numStops! > 1 ? 's' : ''} until ${step.arrivalStop ?? 'destination'}',
                  ),
                ],

                if (step.agencyName != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: const Icon(Icons.business,
                        color: Colors.white54, size: 18),
                    label: 'Operated by',
                    value: step.agencyName!,
                  ),
                ],

                // Reliability section — shown when OBA stop ID is available
                if (stopId != null && stopId.isNotEmpty && routeId.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  RouteReliabilityCard(stopId: stopId, routeId: routeId),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column: icon + solid connector
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4C81),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_vehicleEmoji(step.vehicleType),
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: const _SolidLinePainter(),
                        size: const Size(2, double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Transit content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route badge + headsign
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          step.lineShortName ?? step.lineName ?? '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.headsign != null
                              ? 'toward ${step.headsign}'
                              : '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Departure stop (tappable)
                  if (step.departureStop != null)
                    GestureDetector(
                      onTap: () => _showStopDetail(
                          context, ref, step.departureStop!,
                          isDeparture: true),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_checked,
                              color: Color(0xFF7FDBFF), size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              step.departureStop!,
                              style: const TextStyle(
                                color: Color(0xFF7FDBFF),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF7FDBFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (step.stepDepartureTime != null)
                            Text(step.stepDepartureTime!,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),

                  if (step.departureStop != null && step.arrivalStop != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 7, top: 2, bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 1,
                            height: 12,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 12),
                          if (step.numStops != null)
                            Text(
                              '${step.numStops} stop${step.numStops! > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                        ],
                      ),
                    ),

                  // Arrival stop (tappable)
                  if (step.arrivalStop != null)
                    GestureDetector(
                      onTap: () => _showStopDetail(
                          context, ref, step.arrivalStop!,
                          isDeparture: false),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_checked,
                              color: Colors.white38, size: 14),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              step.arrivalStop!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (step.stepArrivalTime != null)
                            Text(step.stepArrivalTime!,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),

                  const SizedBox(height: 2),
                  Text(step.duration,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single detail row in the stop bottom sheet.
class _DetailRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 24, child: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

String _vehicleEmoji(String? type) {
  switch (type) {
    case 'SUBWAY':
    case 'HEAVY_RAIL':
      return '🚇';
    case 'COMMUTER_TRAIN':
    case 'RAIL':
      return '🚆';
    case 'TRAM':
    case 'LIGHT_RAIL':
      return '🚊';
    case 'FERRY':
      return '⛴️';
    default:
      return '🚌';
  }
}
