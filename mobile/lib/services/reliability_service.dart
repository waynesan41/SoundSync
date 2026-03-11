import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class TimeBinMetrics {
  final String bin;
  final int sampleCount;
  final double onTimeRate;
  final double avgDelaySeconds;
  final double score;

  const TimeBinMetrics({
    required this.bin,
    required this.sampleCount,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.score,
  });

  factory TimeBinMetrics.fromJson(Map<String, dynamic> j) => TimeBinMetrics(
        bin: j['bin'] as String,
        sampleCount: (j['sample_count'] as num).toInt(),
        onTimeRate: (j['on_time_rate'] as num).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num).toDouble(),
        score: (j['score'] as num).toDouble(),
      );
}

class RouteMetrics {
  final String stopId;
  final String routeId;
  final int sampleCount;
  final double onTimeRate;
  final double avgDelaySeconds;
  final double avgDelayMinutes;
  final double delayVariance;
  final double score;
  final List<TimeBinMetrics> timeOfDay;

  const RouteMetrics({
    required this.stopId,
    required this.routeId,
    required this.sampleCount,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.avgDelayMinutes,
    required this.delayVariance,
    required this.score,
    required this.timeOfDay,
  });

  factory RouteMetrics.fromJson(Map<String, dynamic> j) => RouteMetrics(
        stopId: j['stop_id'] as String? ?? '',
        routeId: j['route_id'] as String? ?? '',
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num? ?? 0).toDouble(),
        avgDelayMinutes: (j['avg_delay_minutes'] as num? ?? 0).toDouble(),
        delayVariance: (j['delay_variance'] as num? ?? 0).toDouble(),
        score: (j['score'] as num? ?? 0).toDouble(),
        timeOfDay: (j['time_of_day'] as List<dynamic>? ?? [])
            .map((e) => TimeBinMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StopReliability {
  final String stopId;
  final List<RouteMetrics> routes;

  const StopReliability({required this.stopId, required this.routes});

  factory StopReliability.fromJson(Map<String, dynamic> j) => StopReliability(
        stopId: j['stop_id'] as String? ?? '',
        routes: (j['routes'] as List<dynamic>? ?? [])
            .map((e) => RouteMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PredictionResult {
  final String stopId;
  final String routeId;
  final String timeBin;
  final double predictedDelaySec;
  final double predictedDelayMin;
  final double onTimeRate;
  final int sampleCount;

  const PredictionResult({
    required this.stopId,
    required this.routeId,
    required this.timeBin,
    required this.predictedDelaySec,
    required this.predictedDelayMin,
    required this.onTimeRate,
    required this.sampleCount,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) => PredictionResult(
        stopId: j['stop_id'] as String? ?? '',
        routeId: j['route_id'] as String? ?? '',
        timeBin: j['time_bin'] as String? ?? '',
        predictedDelaySec: (j['predicted_delay_seconds'] as num? ?? 0).toDouble(),
        predictedDelayMin: (j['predicted_delay_minutes'] as num? ?? 0).toDouble(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
      );
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Fetch reliability data for all routes at a stop.
final stopReliabilityProvider =
    FutureProvider.family.autoDispose<StopReliability, String>((ref, stopId) async {
  final dio = buildApiClient();
  final resp = await dio.get('/reliability/$stopId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch reliability');
  }
  return StopReliability.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetch detailed metrics for a specific route at a stop.
/// Key is "$stopId|$routeId".
final routeReliabilityProvider =
    FutureProvider.family.autoDispose<RouteMetrics, String>((ref, key) async {
  final parts = key.split('|');
  final stopId = parts[0];
  final routeId = parts[1];
  final dio = buildApiClient();
  final resp = await dio.get('/reliability/$stopId/$routeId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch route reliability');
  }
  return RouteMetrics.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetch predicted delay for the current time-of-day.
/// Key is "$stopId|$routeId".
final predictionProvider =
    FutureProvider.family.autoDispose<PredictionResult, String>((ref, key) async {
  final parts = key.split('|');
  final stopId = parts[0];
  final routeId = parts[1];
  final dio = buildApiClient();
  final resp = await dio.get('/prediction/$stopId/$routeId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch prediction');
  }
  return PredictionResult.fromJson(data['data'] as Map<String, dynamic>);
});
