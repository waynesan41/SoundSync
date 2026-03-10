// =============================================
// route_detail_screen.dart
// Shows detailed info for a single bus route.
//
// Layout (top to bottom):
//   1. Blue gradient header (route badge, name, path)
//   2. AI Prediction card (confidence, arrival, factors)
//   3. Live Bus Preview (horizontal timeline)
//   4. Upcoming Stops (vertical timeline with times)
//
// Receives a NearbyRoute from Home screen navigation.
// =============================================

import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../widgets/route_badge.dart';

class RouteDetailScreen extends StatelessWidget {
  final NearbyRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // ====== BLUE HEADER ======
          _buildHeader(context),

          // ====== SCROLLABLE CONTENT ======
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Prediction card
                  _buildAIPredictionCard(),
                  const SizedBox(height: 24),

                  // Live Bus Preview
                  _buildLiveBusPreview(),
                  const SizedBox(height: 24),

                  // Upcoming Stops
                  _buildUpcomingStops(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLUE GRADIENT HEADER
  // Back arrow, route badge, name, path
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Route badge + name
          Row(
            children: [
              // White background badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  route.id,
                  style: TextStyle(
                    color: AppTheme.getRouteColor(route.id),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Route name and path
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${route.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Bellevue College → ${route.destination}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // AI PREDICTION CARD
  // Green border, confidence badge, arrival time,
  // expected time, and factor chips
  // ==========================================
  Widget _buildAIPredictionCard() {
    // Pick confidence colors
    Color confBg;
    Color confFg;
    if (route.confidence >= 90) {
      confBg = AppTheme.accent;
      confFg = Colors.white;
    } else if (route.confidence >= 80) {
      confBg = AppTheme.warning;
      confFg = Colors.white;
    } else {
      confBg = AppTheme.error;
      confFg = Colors.white;
    }

    // Status text
    String statusText;
    if (route.status == 'early') {
      statusText = '2 min earlier than scheduled';
    } else if (route.status == 'delayed') {
      statusText = '5 min behind schedule';
    } else {
      statusText = 'Running on schedule';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: "AI Prediction" + confidence badge
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'AI Prediction',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: confBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${route.confidence}% Confident',
                  style: TextStyle(
                    color: confFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // "Arriving in X min" - big text
          Text(
            'Arriving in ${route.arrivalMin} min',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),

          // Expected time and status
          Text(
            'Expected at 3:24 PM — $statusText',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Factor chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFactorChip('🚦', 'Light traffic'),
              _buildFactorChip('🌧️', 'Rain +1m'),
              _buildFactorChip('📊', '97% historical'),
            ],
          ),
        ],
      ),
    );
  }

  // Factor chip helper
  Widget _buildFactorChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIVE BUS PREVIEW
  // Horizontal timeline: Now → 1m → 3m → 4m
  // with a bus icon showing position
  // ==========================================
  Widget _buildLiveBusPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Bus Preview',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              // Timeline row
              Row(
                children: [
                  // "Now" dot (blue, filled)
                  _buildTimelineDot(true),
                  // Bus icon after "Now"
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('🚌', style: TextStyle(fontSize: 18)),
                  ),
                  // Line segment
                  Expanded(child: _buildTimelineLine()),
                  // "1m" dot (gray)
                  _buildTimelineDot(false),
                  Expanded(child: _buildTimelineLine()),
                  // "3m" dot (gray)
                  _buildTimelineDot(false),
                  Expanded(child: _buildTimelineLine()),
                  // "4m" dot (green, destination)
                  _buildTimelineDot(false, isEnd: true),
                ],
              ),
              const SizedBox(height: 6),

              // Labels row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Text(
                    '1m',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const Text(
                    '3m',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    '${route.arrivalMin}m',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status text
              Text(
                'Bus approaching — 0.3 miles away',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Timeline dot
  Widget _buildTimelineDot(bool isActive, {bool isEnd = false}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isEnd
            ? AppTheme.accent
            : isActive
                ? AppTheme.primary
                : AppTheme.textMuted.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  // Timeline connecting line
  Widget _buildTimelineLine() {
    return Container(
      height: 3,
      color: AppTheme.border,
    );
  }

  // ==========================================
  // UPCOMING STOPS
  // Vertical timeline with dots, names, times
  // ==========================================
  Widget _buildUpcomingStops() {
    final stops = MockData.route271Stops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Stops',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Stop list
        ...List.generate(stops.length, (index) {
          final stop = stops[index];
          final isFirst = index == 0;
          final isLast = index == stops.length - 1;
          final tag = stop['tag'] ?? '';

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: dot + line
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      // Dot
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? AppTheme.primary
                              : isLast
                                  ? AppTheme.accent
                                  : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFirst
                                ? AppTheme.primary
                                : isLast
                                    ? AppTheme.accent
                                    : AppTheme.textMuted,
                            width: 2,
                          ),
                        ),
                      ),
                      // Connecting line (not on last item)
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppTheme.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Middle: stop name + tag
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop['name'] ?? '',
                          style: TextStyle(
                            fontWeight:
                                isFirst ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (tag.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : AppTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isFirst
                                      ? AppTheme.primary
                                      : AppTheme.accent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Right: time
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    stop['time'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isFirst ? FontWeight.w700 : FontWeight.w500,
                      color: isFirst
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}