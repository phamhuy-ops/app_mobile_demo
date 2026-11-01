import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

class RoutingService {
  Future<RouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required TravelMode mode,
  }) async {
    final profile = mode.osrmProfile;
    final url = Uri.parse(
      'https://routing.openstreetmap.de/routed-$profile/route/v1/$profile/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('route failed');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) throw Exception('no route');
    final route = routes.first as Map<String, dynamic>;
    final coordinates = route['geometry']['coordinates'] as List<dynamic>;
    final points = coordinates
        .map(
          (point) => LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          ),
        )
        .toList();
    return RouteResult(
      points: points,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}

class PhoneService {
  Future<bool> call(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}

class AppPrefs {
  static const _demoKey = 'use_demo_location';
  static const _favoritesKey = 'favorite_stations';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> demoLocation({required bool fallback}) async =>
      (await _prefs).getBool(_demoKey) ?? fallback;

  Future<void> setDemoLocation(bool value) async =>
      (await _prefs).setBool(_demoKey, value);

  Future<Set<String>> favorites() async =>
      ((await _prefs).getStringList(_favoritesKey) ?? const []).toSet();

  Future<void> setFavorites(Set<String> ids) async =>
      (await _prefs).setStringList(_favoritesKey, ids.toList());
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

String formatDuration(double seconds) {
  final total = seconds.round();
  if (total < 60) return '< 1 phút';
  final minutes = (total / 60).round();
  if (minutes < 60) return '$minutes phút';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours giờ' : '$hours giờ $rest phút';
}

String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 11 && digits.startsWith('028')) {
    return '(028) ${digits.substring(3, 7)} ${digits.substring(7)}';
  }
  return phone;
}
