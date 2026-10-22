import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _nightMapFilter = ColorFilter.matrix(<double>[
  -0.85,
  0,
  0,
  0,
  255,
  0,
  -0.85,
  0,
  0,
  245,
  0,
  0,
  -0.75,
  0,
  235,
  0,
  0,
  0,
  1,
  0,
]);

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.userLocation,
    required this.usingDemoLocation,
    required this.darkMap,
    required this.routeStation,
    this.focusStation,
    required this.routeMode,
    required this.onConsumedRoute,
    required this.onConsumedFocus,
  });

  final LatLng? userLocation;
  final bool usingDemoLocation;
  final bool darkMap;
  final Station? routeStation;
  final Station? focusStation;
  final TravelMode routeMode;
  final VoidCallback onConsumedRoute;
  final VoidCallback onConsumedFocus;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  final routing = RoutingService();
  final phone = PhoneService();
  final searchController = TextEditingController();

  Station? selected;
  TravelMode travelMode = TravelMode.walking;
  RouteResult? route;
  Station? routedStation;
  bool routeLoading = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    selected = _nearest(stations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routeStation != null) {
        showRoute(widget.routeStation!, mode: widget.routeMode);
        widget.onConsumedRoute();
      } else if (widget.focusStation != null) {
        _selectStation(widget.focusStation!);
        widget.onConsumedFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null &&
        oldWidget.userLocation != widget.userLocation &&
        route == null) {
      mapController.move(widget.userLocation!, 14.2);
      selected ??= _nearest(stations);
    }
    if (widget.routeStation != null &&
        widget.routeStation != oldWidget.routeStation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showRoute(widget.routeStation!, mode: widget.routeMode);
        widget.onConsumedRoute();
      });
    } else if (widget.focusStation != null &&
        widget.focusStation != oldWidget.focusStation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectStation(widget.focusStation!);
        widget.onConsumedFocus();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  LatLng get origin => widget.userLocation ?? defaultLocation;

  double distanceTo(Station station) => geo.Geolocator.distanceBetween(
    origin.latitude,
    origin.longitude,
    station.point.latitude,
    station.point.longitude,
  );

  Station _nearest(List<Station> list) {
    final copy = [...list]
      ..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    return copy.first;
  }

  List<Station> get visibleStations {
    final nearby =
        stations.where((station) => distanceTo(station) <= 4000).toList()
          ..sort((a, b) => distanceTo(a).compareTo(distanceTo(b)));
    final result = nearby.isNotEmpty
        ? nearby
        : ([...stations]
                ..sort((a, b) => distanceTo(a).compareTo(distanceTo(b))))
              .take(4)
              .toList();
    if (selected != null && !result.any((s) => s.id == selected!.id)) {
      result.add(selected!);
    }
    if (routedStation != null &&
        !result.any((s) => s.id == routedStation!.id)) {
      result.add(routedStation!);
    }
    return result;
  }

  List<Station> get searchHits {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return stations
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> showRoute(Station station, {required TravelMode mode}) async {
    if (widget.userLocation == null) {
      _toast('Chưa lấy được vị trí GPS hiện tại.');
      return;
    }
    setState(() {
      selected = station;
      travelMode = mode;
      routeLoading = true;
      routedStation = station;
    });
    try {
      final result = await routing.fetchRoute(
        origin: origin,
        destination: station.point,
        mode: mode,
      );
      if (!mounted) return;
      setState(() => route = result);
      if (result.points.length > 1) {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(result.points),
            padding: const EdgeInsets.fromLTRB(48, 140, 48, 240),
          ),
        );
      }
    } catch (_) {
      if (mounted) _toast('Không thể tải tuyến đường lúc này.');
    } finally {
      if (mounted) setState(() => routeLoading = false);
    }
  }

  void exitNavigation() {
    setState(() {
      route = null;
      routedStation = null;
      routeLoading = false;
    });
  }

  Future<void> _call(String number) async {
    final ok = await phone.call(number);
    if (!ok && mounted) _toast('Không mở được ứng dụng gọi điện.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSos() async {
    HapticFeedback.heavyImpact();
    final nearest = _nearest(stations);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SosSheet(
        nearest: nearest,
        origin: origin,
        usingDemo: widget.usingDemoLocation,
        onCall: (number) {
          Navigator.pop(context);
          _call(number);
        },
      ),
    );
  }

  void _selectStation(Station station, {bool routeNow = false}) {
    setState(() {
      selected = station;
      query = '';
      searchController.clear();
    });
    try {
      mapController.move(station.point, 15.2);
    } catch (_) {}
    if (routeNow) showRoute(station, mode: travelMode);
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = widget.userLocation ?? defaultLocation;
    final current = selected ?? _nearest(visibleStations);

    return ColoredBox(
      color: widget.darkMap ? const Color(0xff1b2832) : const Color(0xffd8e4ea),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const sheetHeightFactor = 0.16;
          final sheetClearance = constraints.maxHeight * sheetHeightFactor + 24;
          final fabBottom = sheetClearance.toDouble();
          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 14.2,
                  backgroundColor: widget.darkMap
                      ? const Color(0xff1b2832)
                      : const Color(0xffd8e4ea),
                  onTap: (_, _) {
                    FocusScope.of(context).unfocus();
                    setState(() => query = '');
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _osmTileUrl,
                    userAgentPackageName: 'com.example.mapbox_demo',
                    tileBuilder: widget.darkMap
                        ? (context, tileWidget, tile) => ColorFiltered(
                            colorFilter: _nightMapFilter,
                            child: tileWidget,
                          )
                        : null,
                  ),
                  if (route != null && route!.points.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route!.points,
                          strokeWidth: 6,
                          color: widget.darkMap
                              ? const Color(0xffffc14d)
                              : navy,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: mapCenter,
                        width: 44,
                        height: 44,
                        child: const UserMarker(),
                      ),
                      ...visibleStations.map(
                        (station) => Marker(
                          point: station.point,
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => _selectStation(station),
                            child: StationMarker(
                              selected: station.id == current.id,
                              open: station.open,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SimpleAttributionWidget(
                    source: Text(
                      'OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Column(
                    children: [
                      _SearchHeader(
                        controller: searchController,
                        onChanged: (value) => setState(() => query = value),
                        usingDemo: widget.usingDemoLocation,
                        hasFix: widget.userLocation != null,
                      ),
                      if (searchHits.isNotEmpty)
                        _SearchResults(
                          hits: searchHits,
                          distanceTo: distanceTo,
                          onSelect: _selectStation,
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CountChip(count: visibleStations.length),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: fabBottom + 14,
                child: route == null
                    ? const SizedBox.shrink()
                    : FilledButton.icon(
                        onPressed: exitNavigation,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Thoát dẫn đường'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: navy,
                          elevation: 4,
                        ),
                      ),
              ),
              Positioned(
                right: 16,
                bottom: fabBottom + 16,
                child: Column(
                  children: [
                    _RoundAction(
                      icon: Icons.my_location,
                      onTap: () => mapController.move(mapCenter, 14.4),
                    ),
                    const SizedBox(height: 10),
                    _RoundAction(
                      icon: Icons.sos,
                      color: signal,
                      foreground: Colors.white,
                      onTap: _openSos,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _MapSheet(
                  station: current,
                  distance: distanceTo(current),
                  travelMode: travelMode,
                  routeLoading: routeLoading,
                  route: routedStation?.id == current.id ? route : null,
                  onTravelModeChanged: (mode) {
                    setState(() => travelMode = mode);
                    if (route != null && routedStation != null) {
                      showRoute(routedStation!, mode: mode);
                    }
                  },
                  onDirections: () => showRoute(current, mode: travelMode),
                  onCall: () => _call(current.phone),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.usingDemo,
    required this.hasFix,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool usingDemo;
  final bool hasFix;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'NAVISAFE',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Icon(
                  hasFix ? Icons.gps_fixed : Icons.gps_off,
                  size: 14,
                  color: hasFix ? navyMid : signal,
                ),
                const SizedBox(width: 4),
                Text(
                  usingDemo
                      ? 'Mô phỏng HUTECH E'
                      : (hasFix ? 'GPS thiết bị' : 'Chờ GPS'),
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Tìm trụ sở gần bạn',
                prefixIcon: const Icon(Icons.search, color: muted),
                isDense: true,
                filled: true,
                fillColor: mist,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.hits,
    required this.distanceTo,
    required this.onSelect,
  });

  final List<Station> hits;
  final double Function(Station) distanceTo;
  final ValueChanged<Station> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: hits
            .take(4)
            .map(
              (station) => ListTile(
                onTap: () => onSelect(station),
                leading: StationAvatar(open: station.open, size: 38),
                title: Text(
                  station.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(formatDistance(distanceTo(station))),
                trailing: const Icon(Icons.north_west, size: 16),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count trụ sở gần bạn',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.foreground = navy,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: const CircleBorder(),
    elevation: 4,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, color: foreground),
      ),
    ),
  );
}

class _MapSheet extends StatelessWidget {
  const _MapSheet({
    required this.station,
    required this.distance,
    required this.travelMode,
    required this.routeLoading,
    required this.route,
    required this.onTravelModeChanged,
    required this.onDirections,
    required this.onCall,
  });

  final Station station;
  final double distance;
  final TravelMode travelMode;
  final bool routeLoading;
  final RouteResult? route;
  final ValueChanged<TravelMode> onTravelModeChanged;
  final VoidCallback onDirections;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = route == null
        ? formatDistance(distance)
        : '${formatDistance(route!.distanceMeters)} · ${formatDuration(route!.durationSeconds)}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33071e32),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd5dee4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: Row(
              children: [
                for (var index = 0; index < TravelMode.values.length; index++)
                  Expanded(
                    child: _TravelModeButton(
                      mode: TravelMode.values[index],
                      selected: travelMode == TravelMode.values[index],
                      showLeftBorder: index > 0,
                      onTap: () =>
                          onTravelModeChanged(TravelMode.values[index]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StationAvatar(open: station.open, size: 36),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ĐIỂM ĐANG CHỌN',
                      style: TextStyle(
                        color: navyMid,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    Text(
                      distanceLabel,
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusChip(station: station),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: routeLoading ? null : onDirections,
                    icon: routeLoading
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.near_me_outlined, size: 17),
                    label: Text(routeLoading ? 'Đang tải' : 'Chỉ đường'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone_outlined, size: 17),
                    label: const Text('Gọi trụ sở'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TravelModeButton extends StatelessWidget {
  const _TravelModeButton({
    required this.mode,
    required this.selected,
    required this.showLeftBorder,
    required this.onTap,
  });

  final TravelMode mode;
  final bool selected;
  final bool showLeftBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      TravelMode.walking => 'Bộ',
      TravelMode.cycling => 'Đạp',
      TravelMode.motorbike => 'Máy',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? navy : Colors.white,
        border: Border(
          top: const BorderSide(color: Color(0xffb8c9d4)),
          bottom: const BorderSide(color: Color(0xffb8c9d4)),
          left: showLeftBorder
              ? const BorderSide(color: Color(0xffb8c9d4))
              : const BorderSide(color: Color(0xffb8c9d4)),
          right: const BorderSide(color: Color(0xffb8c9d4)),
        ),
        borderRadius: BorderRadius.horizontal(
          left: mode == TravelMode.walking
              ? const Radius.circular(15)
              : Radius.zero,
          right: mode == TravelMode.motorbike
              ? const Radius.circular(15)
              : Radius.zero,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: mode == TravelMode.walking
              ? const Radius.circular(15)
              : Radius.zero,
          right: mode == TravelMode.motorbike
              ? const Radius.circular(15)
              : Radius.zero,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(mode.icon, size: 14, color: selected ? Colors.white : navy),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosSheet extends StatelessWidget {
  const _SosSheet({
    required this.nearest,
    required this.origin,
    required this.usingDemo,
    required this.onCall,
  });

  final Station nearest;
  final LatLng origin;
  final bool usingDemo;
  final ValueChanged<String> onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffd5dee4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Khẩn cấp',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          Text(
            usingDemo
                ? 'Vị trí mô phỏng: ${origin.latitude.toStringAsFixed(5)}, ${origin.longitude.toStringAsFixed(5)}'
                : 'Tọa độ: ${origin.latitude.toStringAsFixed(5)}, ${origin.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          ...emergencyContacts.map(
            (contact) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => onCall(contact.number),
                tileColor: mist,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: CircleAvatar(
                  backgroundColor: signal,
                  foregroundColor: Colors.white,
                  child: Text(
                    contact.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  contact.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(contact.subtitle),
                trailing: const Icon(Icons.call, color: signal),
              ),
            ),
          ),
          ListTile(
            onTap: () => onCall(nearest.phone),
            tileColor: const Color(0xffe8eef4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const StationAvatar(),
            title: Text(
              nearest.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Gọi trụ sở gần nhất'),
            trailing: const Icon(Icons.call_outlined, color: navy),
          ),
        ],
      ),
    );
  }
}
