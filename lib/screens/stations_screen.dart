import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class StationsScreen extends StatefulWidget {
  const StationsScreen({
    super.key,
    required this.userLocation,
    required this.favorites,
    required this.onDirections,
    required this.onCall,
    required this.onToggleFavorite,
    required this.onOpenOnMap,
  });

  final LatLng? userLocation;
  final Set<String> favorites;
  final ValueChanged<Station> onDirections;
  final ValueChanged<Station> onCall;
  final ValueChanged<Station> onToggleFavorite;
  final ValueChanged<Station> onOpenOnMap;

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  String query = '';
  bool onlyOpen = false;
  bool onlyFavorites = false;

  double distanceTo(Station station) => geo.Geolocator.distanceBetween(
    (widget.userLocation ?? defaultLocation).latitude,
    (widget.userLocation ?? defaultLocation).longitude,
    station.point.latitude,
    station.point.longitude,
  );

  @override
  Widget build(BuildContext context) {
    final filtered =
        stations.where((station) {
            final q = query.trim().toLowerCase();
            final matchesQuery =
                q.isEmpty ||
                station.name.toLowerCase().contains(q) ||
                station.address.toLowerCase().contains(q);
            final matchesOpen = !onlyOpen || station.open;
            final matchesFav =
                !onlyFavorites || widget.favorites.contains(station.id);
            return matchesQuery && matchesOpen && matchesFav;
          }).toList()
          ..sort((a, b) {
            final favA = widget.favorites.contains(a.id) ? 0 : 1;
            final favB = widget.favorites.contains(b.id) ? 0 : 1;
            if (favA != favB) return favA.compareTo(favB);
            return distanceTo(a).compareTo(distanceTo(b));
          });

    return ColoredBox(
      color: paper,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text(
              'Trụ sở',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${filtered.length}/${stations.length} địa điểm · gần đến xa',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc địa chỉ',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Đang trực'),
                  selected: onlyOpen,
                  onSelected: (value) => setState(() => onlyOpen = value),
                ),
                FilterChip(
                  label: const Text('Đã lưu'),
                  selected: onlyFavorites,
                  onSelected: (value) => setState(() => onlyFavorites = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'Không có trụ sở khớp bộ lọc.',
                    style: TextStyle(color: muted),
                  ),
                ),
              )
            else
              ...filtered.map(
                (station) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StationCard(
                    station: station,
                    distance: distanceTo(station),
                    favorite: widget.favorites.contains(station.id),
                    onDirections: () => widget.onDirections(station),
                    onCall: () => widget.onCall(station),
                    onToggleFavorite: () => widget.onToggleFavorite(station),
                    onOpen: () => widget.onOpenOnMap(station),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
