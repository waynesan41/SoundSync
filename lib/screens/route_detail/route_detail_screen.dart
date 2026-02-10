import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../models/route.dart';
import '../../models/stop.dart';

class RouteDetailScreen extends StatelessWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteById(routeId);

    if (route == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Route not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // Colored header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: route.routeColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                route.shortName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      route.routeColor,
                      route.routeColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          route.longName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route.agencyName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Description card
          if (route.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    route.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

          // Stops header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Stops (${route.stops?.length ?? 0})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Stops timeline
          if (route.stops != null && route.stops!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final stop = route.stops![index];
                  final isFirst = index == 0;
                  final isLast = index == route.stops!.length - 1;

                  return _StopTile(
                    stop: stop,
                    color: route.routeColor,
                    isFirst: isFirst,
                    isLast: isLast,
                  );
                },
                childCount: route.stops!.length,
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Stop details coming soon.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

// Timeline stop tile
class _StopTile extends StatelessWidget {
  final Stop stop;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _StopTile({
    required this.stop,
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Timeline line + dot
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isFirst
                          ? Colors.transparent
                          : color.withOpacity(0.3),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: (isFirst || isLast) ? color : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 3,
                      color: isLast
                          ? Colors.transparent
                          : color.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Stop info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isFirst || isLast)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isFirst || isLast)
                      Text(
                        isFirst ? 'First stop' : 'Last stop',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}