import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class TripAssistantScreen extends StatefulWidget {
  const TripAssistantScreen({super.key});

  @override
  State<TripAssistantScreen> createState() => _TripAssistantScreenState();
}

class _TripAssistantScreenState extends State<TripAssistantScreen> {
  String _selected = '550';
  bool _loading = true;
  String? _error;
  DelayPrediction? _delay;
  CrowdingPrediction? _crowding;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.fetchDelayPrediction(routeId: _selected),
        ApiService.fetchCrowdingPrediction(routeId: _selected),
      ]);
      setState(() {
        _delay = results[0] as DelayPrediction;
        _crowding = results[1] as CrowdingPrediction;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Builds a _MockRoute from real prediction data so the card widgets don't change.
  _MockRoute get _routeData {
    final d = _delay;
    if (d == null) return _getMockData(_selected);

    final c = _crowding;
    final score = (d.confidence * 100).round();
    final delayMin = d.predictedDelayMinutes;
    final p90 = d.percentile90DelayMinutes;
    final name = _displayName(_selected);

    final String label;
    if (score >= 70) label = 'Reliable';
    else if (score >= 40) label = 'Moderate';
    else label = 'Unreliable';

    final String consistency;
    if (d.sampleSize < 3) consistency = 'Insufficient data';
    else if (p90 <= delayMin * 1.5 + 1) consistency = 'Very consistent';
    else if (p90 <= delayMin * 2.5 + 2) consistency = 'Somewhat consistent';
    else consistency = 'Highly unpredictable';

    final String anomaly;
    final String anomalyMsg;
    final String anomalyDetail;
    if (d.sampleSize == 0) {
      anomaly = 'normal';
      anomalyMsg = 'No report data yet for $name. Anomaly detection will activate once data is collected.';
      anomalyDetail = '';
    } else if (delayMin > p90) {
      anomaly = 'critical';
      anomalyMsg = '$name is performing worse than its 90th-percentile baseline.';
      anomalyDetail = 'Predicted delay ${delayMin.toStringAsFixed(1)} min exceeds the 90th percentile ${p90.toStringAsFixed(1)} min.';
    } else if (p90 > 2 && delayMin > p90 * 0.7) {
      anomaly = 'warning';
      anomalyMsg = '$name is approaching its worst-case delay range.';
      anomalyDetail = 'Predicted ${delayMin.toStringAsFixed(1)} min delay · typical worst case ${p90.toStringAsFixed(1)} min.';
    } else {
      anomaly = 'normal';
      anomalyMsg = '$name is performing within normal range. No anomalies detected.';
      anomalyDetail = '';
    }

    final String predMsg;
    if (d.sampleSize == 0) {
      predMsg = 'No historical data yet for $name. Predictions will improve as riders submit reports.';
    } else {
      predMsg = 'Based on ${d.sampleSize} observations during ${d.timeBin} on ${d.dayType}s, '
          '$name is typically ${delayMin.toStringAsFixed(1)} min ${delayMin >= 0 ? 'late' : 'early'}.';
    }

    final crowdLevel = c?.predictedLevel ?? 3.0;
    final ridersEst = (crowdLevel / 5.0 * 80 + 20).round();
    final lostPerRider = delayMin.round().clamp(0, 60);

    return _MockRoute(
      score: score,
      label: label,
      onTime: score,
      delay: delayMin,
      consistency: consistency,
      prediction: score,
      predictionMsg: predMsg,
      obs: d.sampleSize,
      anomaly: anomaly,
      anomalyMsg: anomalyMsg,
      anomalyDetail: anomalyDetail,
      lostMonth: (ridersEst * lostPerRider * 30).clamp(0, 99999),
      lostWeek: (ridersEst * lostPerRider * 7).clamp(0, 99999),
      riders: ridersEst,
      impactMsg: 'Estimated from crowding level ${crowdLevel.toStringAsFixed(1)}/5 '
          'and ${delayMin.toStringAsFixed(1)} min predicted delay for $name.',
    );
  }

  String _displayName(String id) {
    switch (id) {
      case '550': return 'Route 550';
      case '271': return 'Route 271';
      case 'bline': return 'B Line';
      default: return 'Route $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _routeData;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Trip Assistant', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 40),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _routePicker(),
                const SizedBox(height: 20),
                _reliabilityCard(data),
                const SizedBox(height: 16),
                _predictionCard(data),
                const SizedBox(height: 16),
                _anomalyCard(data),
                const SizedBox(height: 16),
                _impactCard(data),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  // route picker at top
  Widget _routePicker() {
    final routes = [
      {'id': '550', 'name': '550', 'sub': 'Bellevue–Seattle'},
      {'id': '271', 'name': '271', 'sub': 'Bellevue–Eastgate'},
      {'id': 'bline', 'name': 'B Line', 'sub': 'Rapid Ride'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: routes.map((r) {
          final picked = r['id'] == _selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selected = r['id']!);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: picked ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(r['name']!, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: picked ? Colors.white : AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(r['sub']!, style: TextStyle(
                    fontSize: 10,
                    color: picked ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary)),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // reliability score 0-100
  Widget _reliabilityCard(_MockRoute data) {
    final col = data.score >= 70 ? AppTheme.accent
        : data.score >= 40 ? AppTheme.warning : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.speed_rounded, color: col, size: 20),
            const SizedBox(width: 8),
            const Text('Reliability Score',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data.score}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: col, height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('/ 100', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: col.withOpacity(0.5))),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(data.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: col)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _scoreRow('On-time rate', '${data.onTime}%'),
          const SizedBox(height: 8),
          _scoreRow('Avg delay', '${data.delay} min'),
          const SizedBox(height: 8),
          _scoreRow('Consistency', data.consistency),
          const SizedBox(height: 12),
          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.score / 100, backgroundColor: AppTheme.border,
              color: col, minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  // trip prediction - % chance
  Widget _predictionCard(_MockRoute data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.route_rounded, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text('Trip Prediction',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${data.prediction}%', style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.primary, height: 1)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('chance of making\nyour connection',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3))),
                ]),
                const SizedBox(height: 12),
                Text(data.predictionMsg, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.data_usage_rounded, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text('Based on ${data.obs} observations',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ],
      ),
    );
  }

  // anomaly alerts
  Widget _anomalyCard(_MockRoute data) {
    final bad = data.anomaly != 'normal';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bad ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bad ? const Color(0xFFFCA5A5) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(bad ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: bad ? AppTheme.error : AppTheme.accent, size: 20),
            const SizedBox(width: 8),
            const Text('Anomaly Detection',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Text(data.anomalyMsg, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: bad ? const Color(0xFFDC2626) : AppTheme.textPrimary, height: 1.4)),
          if (bad && data.anomalyDetail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(data.anomalyDetail,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
          ],
        ],
      ),
    );
  }

  // rider impact stats
  Widget _impactCard(_MockRoute data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.people_outline_rounded, color: Color(0xFF8B5CF6), size: 20),
            SizedBox(width: 8),
            Text('Rider Impact',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _stat('${data.lostMonth}', 'min lost\nlast month', const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            _stat('${data.lostWeek}', 'min lost\nthis week', AppTheme.warning),
            const SizedBox(width: 12),
            _stat('${data.riders}', 'riders\naffected', AppTheme.primary),
          ]),
          const SizedBox(height: 12),
          Text(data.impactMsg,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _stat(String val, String label, Color c) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3)),
      ]),
    ));
  }
}


// mock data - will replace with Nolan's API
// TODO: GET /ai/reliability/:routeId
// TODO: GET /ai/predict/:routeId
// TODO: GET /ai/anomalies
// TODO: GET /ai/impact/:routeId

class _MockRoute {
  final int score;
  final String label;
  final int onTime;
  final double delay;
  final String consistency;
  final int prediction;
  final String predictionMsg;
  final int obs;
  final String anomaly;
  final String anomalyMsg;
  final String anomalyDetail;
  final int lostMonth;
  final int lostWeek;
  final int riders;
  final String impactMsg;

  const _MockRoute({
    required this.score, required this.label, required this.onTime,
    required this.delay, required this.consistency, required this.prediction,
    required this.predictionMsg, required this.obs, required this.anomaly,
    required this.anomalyMsg, required this.anomalyDetail,
    required this.lostMonth, required this.lostWeek, required this.riders,
    required this.impactMsg,
  });
}

_MockRoute _getMockData(String id) {
  switch (id) {
    case '550':
      return const _MockRoute(
        score: 73, label: 'Moderate', onTime: 68, delay: 2.3,
        consistency: 'Somewhat consistent', prediction: 78,
        predictionMsg: 'Based on 47 observations, your 8:12am 550 is typically 2.3 min late on Wednesdays. You have a 78% chance of making your connection at Bellevue TC.',
        obs: 47, anomaly: 'warning',
        anomalyMsg: 'Route 550 is performing 23% worse than its 30-day baseline.',
        anomalyDetail: 'Likely cause: I-90 construction zone near Mercer Island. Delays concentrated between 7:30–9:00am.',
        lostMonth: 4200, lostWeek: 980, riders: 1250,
        impactMsg: 'Route 550 riders collectively lost 4,200 minutes last month — averaging 3.4 min per rider per trip.',
      );
    case '271':
      return const _MockRoute(
        score: 85, label: 'Reliable', onTime: 82, delay: 1.1,
        consistency: 'Very consistent', prediction: 91,
        predictionMsg: 'Based on 63 observations, your 9:05am 271 is typically 1.1 min late. You have a 91% chance of arriving on time to Bellevue College.',
        obs: 63, anomaly: 'normal',
        anomalyMsg: 'Route 271 is performing within normal range. No anomalies detected.',
        anomalyDetail: '',
        lostMonth: 890, lostWeek: 210, riders: 430,
        impactMsg: 'Route 271 riders collectively lost 890 minutes last month — one of the more reliable routes in the network.',
      );
    case 'bline':
    default:
      return const _MockRoute(
        score: 42, label: 'Unreliable', onTime: 51, delay: 4.7,
        consistency: 'Highly unpredictable', prediction: 54,
        predictionMsg: 'Based on 38 observations, the B Line varies between 0–10 min late with no clear pattern. Unpredictability makes connection planning difficult.',
        obs: 38, anomaly: 'critical',
        anomalyMsg: 'B Line is performing 41% worse than baseline — flagged for review.',
        anomalyDetail: 'Delays worsened significantly after Feb schedule change. Peak hours most affected.',
        lostMonth: 7800, lostWeek: 1950, riders: 2100,
        impactMsg: 'B Line riders lost 7,800 minutes last month — the worst performer in the Bellevue corridor. City planners: this route needs attention.',
      );
  }
}