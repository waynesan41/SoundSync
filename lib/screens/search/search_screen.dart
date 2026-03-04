import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/mock_data.dart';
import '../../models/route.dart';
import '../route_detail/route_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  List<TransitRoute> _results = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // TODO: replace with Wayne's GET /routes?query=
  Future<void> _loadRoutes() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() { _results = MockData.routes; _loading = false; });
  }

  void _onSearch(String query) {
    setState(() { _results = MockData.searchRoutes(query); });
  }

  // need to convert to NearbyRoute for route detail screen
  NearbyRoute _toNearby(TransitRoute r) {
    final arrivals = {'271': 4, 'B Line': 8, '245': 12, '550': 15, '241': 22, '556': 18};
    final conf = {'271': 94, 'B Line': 87, '245': 91, '550': 82, '241': 88, '556': 79};
    return NearbyRoute(
      id: r.shortName,
      destination: r.longName.split(' to ').length > 1 ? r.longName.split(' to ').last : r.longName,
      arrivalMin: arrivals[r.shortName] ?? 10,
      confidence: conf[r.shortName] ?? 85,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search routes (e.g. 271, B Line)...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              onPressed: () { _controller.clear(); _onSearch(''); },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            )
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48,
                          color: AppTheme.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No routes found',
                          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ))
                  : ListView.builder(
                      itemCount: _results.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, i) {
                        final route = _results[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              RouteDetailScreen(route: _toNearby(route)))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: route.routeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: Text(route.shortName,
                                    style: TextStyle(
                                      fontSize: route.shortName.length > 3 ? 13 : 18,
                                      fontWeight: FontWeight.w700, color: route.routeColor)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(route.longName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(route.agencyName,
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                )),
                                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}