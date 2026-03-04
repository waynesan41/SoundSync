import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'mock_data.dart';

class DelayPrediction {
  final String routeId;
  final double predictedDelayMinutes;
  final double percentile90DelayMinutes;
  final double confidence;
  final int sampleSize;
  final String timeBin;
  final String dayType;

  const DelayPrediction({
    required this.routeId,
    required this.predictedDelayMinutes,
    required this.percentile90DelayMinutes,
    required this.confidence,
    required this.sampleSize,
    required this.timeBin,
    required this.dayType,
  });

  factory DelayPrediction.fromJson(Map<String, dynamic> j) => DelayPrediction(
    routeId: j['routeId'] as String? ?? '',
    predictedDelayMinutes: (j['predicted_delay_minutes'] as num?)?.toDouble() ?? 0,
    percentile90DelayMinutes: (j['percentile_90_delay_minutes'] as num?)?.toDouble() ?? 0,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
    sampleSize: j['sample_size'] as int? ?? 0,
    timeBin: j['time_bin'] as String? ?? '',
    dayType: j['day_type'] as String? ?? '',
  );
}

class CrowdingPrediction {
  final String routeId;
  final double predictedLevel;
  final double percentile90Level;
  final double confidence;
  final int sampleSize;

  const CrowdingPrediction({
    required this.routeId,
    required this.predictedLevel,
    required this.percentile90Level,
    required this.confidence,
    required this.sampleSize,
  });

  factory CrowdingPrediction.fromJson(Map<String, dynamic> j) => CrowdingPrediction(
    routeId: j['routeId'] as String? ?? '',
    predictedLevel: (j['predicted_crowding_level'] as num?)?.toDouble() ?? 0,
    percentile90Level: (j['percentile_90_crowding_level'] as num?)?.toDouble() ?? 0,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
    sampleSize: j['sample_size'] as int? ?? 0,
  );
}

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path, [Map<String, String>? params]) {
    final base = Uri.parse(AppConfig.baseURL + path);
    if (params == null || params.isEmpty) return base;
    return base.replace(queryParameters: params);
  }

  /// POST /api/v1/auth/login — returns the bearer token on success.
  static Future<String> login(String emailOrUsername, String password) async {
    final resp = await http.post(
      _uri(AppConfig.loginEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': emailOrUsername, 'password': password}),
    ).timeout(AppConfig.httpTimeout);

    if (resp.statusCode != 200) {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Login failed');
    }

    return (jsonDecode(resp.body) as Map<String, dynamic>)['token'] as String;
  }

  /// GET /api/v1/arrivals — returns routes sorted by soonest arrival.
  /// Deduplicates by route ID, keeping the soonest trip per route.
  static Future<List<NearbyRoute>> fetchArrivals({
    String? routeId,
    String? stopId,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (routeId != null) params['routeId'] = routeId;
    if (stopId != null) params['stopId'] = stopId;

    final resp = await http
        .get(_uri(AppConfig.arrivalsEndpoint, params), headers: await _headers())
        .timeout(AppConfig.httpTimeout);

    if (resp.statusCode != 200) throw Exception('arrivals ${resp.statusCode}');

    final list = (jsonDecode(resp.body) as Map<String, dynamic>)['arrivals'] as List<dynamic>? ?? [];
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Deduplicate by routeId, keeping the soonest arrival per route.
    final seen = <String, NearbyRoute>{};
    for (final item in list) {
      final a = item as Map<String, dynamic>;
      final id = a['route_id'] as String? ?? '';
      final predictedMs = (a['predicted_arrival_ms'] as num?)?.toInt() ?? 0;
      final delaySeconds = (a['delay_seconds'] as num?)?.toInt() ?? 0;
      final arrivalMin = ((predictedMs - nowMs) / 60000).round().clamp(0, 999);

      final String status;
      if (delaySeconds > 120) {
        status = 'delayed';
      } else if (delaySeconds < -60) {
        status = 'early';
      } else {
        status = 'on-time';
      }

      final route = NearbyRoute(
        id: id,
        destination: a['headsign'] as String? ?? id,
        arrivalMin: arrivalMin,
        confidence: _confidenceFromDelay(delaySeconds.abs()),
        status: status,
      );

      if (!seen.containsKey(id) || route.arrivalMin < seen[id]!.arrivalMin) {
        seen[id] = route;
      }
    }

    return seen.values.toList()..sort((a, b) => a.arrivalMin.compareTo(b.arrivalMin));
  }

  /// GET /api/v1/predictions/delay
  static Future<DelayPrediction> fetchDelayPrediction({
    required String routeId,
    String? stopId,
    int? directionId,
  }) async {
    final params = <String, String>{'routeId': routeId};
    if (stopId != null) params['stopId'] = stopId;
    if (directionId != null) params['directionId'] = '$directionId';

    final resp = await http
        .get(_uri(AppConfig.predictDelayEndpoint, params), headers: await _headers())
        .timeout(AppConfig.httpTimeout);

    if (resp.statusCode != 200) throw Exception('delay prediction ${resp.statusCode}');

    return DelayPrediction.fromJson(
      (jsonDecode(resp.body) as Map<String, dynamic>)['prediction'] as Map<String, dynamic>,
    );
  }

  /// GET /api/v1/predictions/crowding
  static Future<CrowdingPrediction> fetchCrowdingPrediction({
    required String routeId,
    String? stopId,
    int? directionId,
  }) async {
    final params = <String, String>{'routeId': routeId};
    if (stopId != null) params['stopId'] = stopId;
    if (directionId != null) params['directionId'] = '$directionId';

    final resp = await http
        .get(_uri(AppConfig.predictCrowdingEndpoint, params), headers: await _headers())
        .timeout(AppConfig.httpTimeout);

    if (resp.statusCode != 200) throw Exception('crowding prediction ${resp.statusCode}');

    return CrowdingPrediction.fromJson(
      (jsonDecode(resp.body) as Map<String, dynamic>)['prediction'] as Map<String, dynamic>,
    );
  }

  // Derives a 0-100 confidence score from how far off a bus is running.
  static int _confidenceFromDelay(int absDelaySeconds) {
    if (absDelaySeconds <= 30)  return 95;
    if (absDelaySeconds <= 60)  return 88;
    if (absDelaySeconds <= 120) return 80;
    if (absDelaySeconds <= 300) return 65;
    return 45;
  }
}
