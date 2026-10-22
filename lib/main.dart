import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_demo/firebase_options.dart';

import 'data.dart';
import 'models.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stations_screen.dart';
import 'services.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NaviSafeApp());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
}

class NaviSafeApp extends StatelessWidget {
  const NaviSafeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NaviSafe',
    theme: buildNaviTheme(),
    home: const NaviSafeShell(),
  );
}

class NaviSafeShell extends StatefulWidget {
  const NaviSafeShell({super.key});

  @override
  State<NaviSafeShell> createState() => _NaviSafeShellState();
}

class _NaviSafeShellState extends State<NaviSafeShell> {
  final prefs = AppPrefs();
  final phone = PhoneService();
  int tab = 0;
  LatLng? userLocation;
  Station? routeStation;
  Station? focusStation;
  TravelMode routeMode = TravelMode.walking;
  geo.LocationPermission permission = geo.LocationPermission.denied;
  bool serviceEnabled = false;
  bool usingDemoLocation = true;
  bool darkMap = false;
  Set<String> favorites = {};
  StreamSubscription<geo.Position>? positionSubscription;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      usingDemoLocation = await prefs.demoLocation(fallback: true);
      darkMap = await prefs.darkMap();
      favorites = await prefs.favorites();
    } catch (_) {
      usingDemoLocation = true;
    }
    await refreshLocation();
  }

  Future<void> refreshLocation() async {
    if (usingDemoLocation) {
      await positionSubscription?.cancel();
      if (mounted) {
        setState(() {
          userLocation = hutechKhuELocation;
          serviceEnabled = true;
          permission = geo.LocationPermission.whileInUse;
        });
      }
      return;
    }
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      if (mounted) setState(() {});
      return;
    }
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      _setLocation(position);
      await positionSubscription?.cancel();
      positionSubscription = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(_setLocation);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _setLocation(geo.Position position) {
    if (!mounted) return;
    setState(
      () => userLocation = LatLng(position.latitude, position.longitude),
    );
  }

  Future<void> _toggleFavorite(Station station) async {
    setState(() {
      if (favorites.contains(station.id)) {
        favorites.remove(station.id);
      } else {
        favorites.add(station.id);
      }
    });
    await prefs.setFavorites(favorites);
  }

  Future<void> _call(String number) async {
    final ok = await phone.call(number);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng gọi điện.')),
      );
    }
  }

  void _openOnMap(Station station) {
    setState(() {
      focusStation = station;
      tab = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MapScreen(
        userLocation: userLocation,
        usingDemoLocation: usingDemoLocation,
        darkMap: darkMap,
        routeStation: routeStation,
        focusStation: focusStation,
        routeMode: routeMode,
        onConsumedRoute: () => setState(() => routeStation = null),
        onConsumedFocus: () => setState(() => focusStation = null),
      ),
      StationsScreen(
        userLocation: userLocation,
        favorites: favorites,
        onDirections: (station) => setState(() {
          routeStation = station;
          routeMode = TravelMode.walking;
          tab = 0;
        }),
        onCall: (station) => _call(station.phone),
        onToggleFavorite: _toggleFavorite,
        onOpenOnMap: _openOnMap,
      ),
      SettingsScreen(
        serviceEnabled: serviceEnabled,
        permission: permission,
        usingDemoLocation: usingDemoLocation,
        darkMap: darkMap,
        onRefresh: refreshLocation,
        onToggleDemo: (value) async {
          setState(() => usingDemoLocation = value);
          await prefs.setDemoLocation(value);
          await refreshLocation();
        },
        onToggleDarkMap: (value) async {
          setState(() => darkMap = value);
          await prefs.setDarkMap(value);
        },
        onCallEmergency: _call,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: navy,
          boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.map_outlined,
                  selectedIcon: Icons.map,
                  label: 'Bản đồ',
                  selected: tab == 0,
                  onTap: () => setState(() => tab = 0),
                ),
                _NavItem(
                  icon: Icons.apartment_outlined,
                  selectedIcon: Icons.apartment,
                  label: 'Trụ sở',
                  selected: tab == 1,
                  onTap: () => setState(() => tab = 1),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Cài đặt',
                  selected: tab == 2,
                  onTap: () => setState(() => tab = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0x1FFFFFFF) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : const Color(0xff8aa3b5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xff8aa3b5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
