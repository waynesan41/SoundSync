import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/reliability_service.dart';
import 'reliability_card.dart';

final arrivalsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, stopId) async {
  final dio = buildApiClient();
  final resp = await dio.get('/transit/arrivals', queryParameters: {'stopId': stopId});
  return resp.data['arrivals'] as List<dynamic>;
});

class ArrivalBoard extends ConsumerWidget {
  final String stopId;
  const ArrivalBoard({super.key, required this.stopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivalsAsync = ref.watch(arrivalsProvider(stopId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reliability card sits above the arrivals list
        StopReliabilityCard(stopId: stopId),

        // Arrivals
        arrivalsAsync.when(
          data: (arrivals) => arrivals.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No upcoming arrivals',
                      style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: arrivals.length,
                  itemBuilder: (_, i) {
                    final a = arrivals[i] as Map<String, dynamic>;
                    final routeId = a['routeId'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        a['routeShortName'] as String? ?? routeId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      title: Text(
                        a['headsign'] as String? ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            a['scheduledArrival'] as String? ?? '',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          if (routeId.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _ReliabilityBadge(
                                stopId: stopId, routeId: routeId),
                          ],
                        ],
                      ),
                    );
                  },
                ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF7FDBFF))),
          ),
          error: (e, _) => Text('Error: $e',
              style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

/// Small score badge shown next to each arrival row.
class _ReliabilityBadge extends ConsumerWidget {
  final String stopId;
  final String routeId;
  const _ReliabilityBadge({required this.stopId, required this.routeId});

  Color _color(double score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(routeReliabilityProvider('$stopId|$routeId'));
    return async.maybeWhen(
      data: (m) => m.sampleCount == 0
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _color(m.score).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _color(m.score).withOpacity(0.5)),
              ),
              child: Text(
                m.score.toStringAsFixed(0),
                style: TextStyle(
                    color: _color(m.score),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
