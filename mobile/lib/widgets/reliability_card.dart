import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reliability_service.dart';

// ─── Score colour helper ───────────────────────────────────────────────────

Color _scoreColor(double score) {
  if (score >= 80) return const Color(0xFF22C55E); // green
  if (score >= 50) return const Color(0xFFF59E0B); // amber
  return const Color(0xFFEF4444);                  // red
}

String _scoreLabel(double score) {
  if (score >= 80) return 'Reliable';
  if (score >= 50) return 'Fair';
  return 'Unreliable';
}

const _binOrder = ['morning', 'midday', 'afternoon', 'evening'];
const _binLabels = {
  'morning': 'Morning\n6–9 am',
  'midday': 'Midday\n9 am–3 pm',
  'afternoon': 'Afternoon\n3–7 pm',
  'evening': 'Evening\n7 pm+',
};

// ─── Stop-level reliability card ──────────────────────────────────────────

/// Shows all routes at [stopId] with their scores and a time-of-day breakdown
/// for the selected route.
class StopReliabilityCard extends ConsumerStatefulWidget {
  final String stopId;
  const StopReliabilityCard({super.key, required this.stopId});

  @override
  ConsumerState<StopReliabilityCard> createState() => _StopReliabilityCardState();
}

class _StopReliabilityCardState extends ConsumerState<StopReliabilityCard> {
  String? _selectedRouteId;

  @override
  Widget build(BuildContext context) {
    final reliabilityAsync = ref.watch(stopReliabilityProvider(widget.stopId));

    return reliabilityAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7FDBFF)),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(), // silent — poller may not be running
      data: (reliability) {
        if (reliability.routes.isEmpty) return const SizedBox.shrink();

        final selected = _selectedRouteId != null
            ? reliability.routes.where((r) => r.routeId == _selectedRouteId).firstOrNull
            : null;
        final displayRoute = selected ?? reliability.routes.first;
        if (_selectedRouteId == null) {
          _selectedRouteId = displayRoute.routeId;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2137),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.insights, color: Color(0xFF7FDBFF), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'Reliability',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${reliability.routes.length} route${reliability.routes.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Route selector pills (if more than one route)
              if (reliability.routes.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: reliability.routes.map((r) {
                        final isSelected = r.routeId == _selectedRouteId;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRouteId = r.routeId),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _scoreColor(r.score).withOpacity(0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _scoreColor(r.score)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              r.routeId,
                              style: TextStyle(
                                color: isSelected
                                    ? _scoreColor(r.score)
                                    : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // Score row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Score gauge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _scoreColor(displayRoute.score).withOpacity(0.15),
                        border: Border.all(
                            color: _scoreColor(displayRoute.score), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          displayRoute.score.toStringAsFixed(0),
                          style: TextStyle(
                            color: _scoreColor(displayRoute.score),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Label + stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scoreLabel(displayRoute.score),
                            style: TextStyle(
                                color: _scoreColor(displayRoute.score),
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _StatChip(
                                label: 'On-time',
                                value:
                                    '${displayRoute.onTimeRate.toStringAsFixed(0)}%',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                label: 'Avg delay',
                                value: _formatDelay(displayRoute.avgDelayMinutes),
                                highlight: displayRoute.avgDelayMinutes > 2,
                              ),
                              if (displayRoute.sampleCount > 0) ...[
                                const SizedBox(width: 8),
                                _StatChip(
                                  label: 'Samples',
                                  value: '${displayRoute.sampleCount}',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Time-of-day breakdown
              if (displayRoute.timeOfDay.isNotEmpty) ...[
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Best time to travel',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _binOrder.map((bin) {
                          final metrics = displayRoute.timeOfDay
                              .where((t) => t.bin == bin)
                              .firstOrNull;
                          return Expanded(
                            child: _TimeBinCell(
                              label: _binLabels[bin] ?? bin,
                              metrics: metrics,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Route-level reliability card (used in stop detail sheets) ────────────

/// Compact card for a single route+stop pair.
class RouteReliabilityCard extends ConsumerWidget {
  final String stopId;
  final String routeId;
  const RouteReliabilityCard({
    super.key,
    required this.stopId,
    required this.routeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = '$stopId|$routeId';
    final metricsAsync = ref.watch(routeReliabilityProvider(key));
    final predAsync = ref.watch(predictionProvider(key));

    return metricsAsync.when(
      loading: () => const SizedBox(height: 40, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7FDBFF))))),
      error: (_, __) => const SizedBox.shrink(),
      data: (metrics) {
        if (metrics.sampleCount == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2137),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _scoreColor(metrics.score).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _scoreColor(metrics.score)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          metrics.score.toStringAsFixed(0),
                          style: TextStyle(
                              color: _scoreColor(metrics.score),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _scoreLabel(metrics.score),
                          style: TextStyle(
                              color: _scoreColor(metrics.score), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${metrics.onTimeRate.toStringAsFixed(0)}% on-time',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white38, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Avg delay: ${_formatDelay(metrics.avgDelayMinutes)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              // Predicted delay for current time bin
              predAsync.whenOrNull(
                data: (pred) => pred.sampleCount > 0
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: Color(0xFF7FDBFF), size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Now (${pred.timeBin}): ${_formatDelay(pred.predictedDelayMin)} expected',
                              style: const TextStyle(
                                  color: Color(0xFF7FDBFF), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : null,
              ) ?? const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatChip({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFF59E0B) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }
}

class _TimeBinCell extends StatelessWidget {
  final String label;
  final TimeBinMetrics? metrics;
  const _TimeBinCell({required this.label, this.metrics});

  @override
  Widget build(BuildContext context) {
    final score = metrics?.score ?? 0;
    final color = metrics != null ? _scoreColor(score) : Colors.white24;

    return Column(
      children: [
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: metrics != null ? (score / 100).clamp(0.0, 1.0) : 0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metrics != null ? score.toStringAsFixed(0) : '—',
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

String _formatDelay(double minutes) {
  if (minutes.abs() < 0.5) return 'On time';
  final sign = minutes > 0 ? '+' : '';
  if (minutes.abs() < 1) {
    return '${sign}${(minutes * 60).round()} sec';
  }
  return '$sign${minutes.toStringAsFixed(1)} min';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
