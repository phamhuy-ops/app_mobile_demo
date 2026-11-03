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

// Điểm bắt đầu ứng dụng: chuẩn bị Flutter, dựng giao diện rồi khởi tạo Firebase.
// Lưu ý thứ tự hiện tại: runApp chạy trước khi Firebase khởi tạo xong;
// các màn hình hiện dùng dữ liệu cục bộ nên không chờ đọc dữ liệu Firebase.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NaviSafeApp());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
}

/// Cấu hình toàn ứng dụng: tên, giao diện chung và màn hình gốc.
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

/// Quản lý trạng thái dùng chung giữa ba tab: bản đồ, trụ sở và cài đặt.
class NaviSafeShell extends StatefulWidget {
  const NaviSafeShell({super.key});

  @override
  State<NaviSafeShell> createState() => _NaviSafeShellState();
}

class _NaviSafeShellState extends State<NaviSafeShell> {
  // Tách lưu trữ và mở ứng dụng điện thoại thành dịch vụ để giao diện dễ đọc.
  final prefs = AppPrefs();
  final phone = PhoneService();
  int tab = 0;
  LatLng? userLocation;
  // Hai biến đóng vai trò yêu cầu gửi sang tab bản đồ:
  // routeStation để tìm đường, focusStation để di chuyển đến một trụ sở.
  Station? routeStation;
  Station? focusStation;
  TravelMode routeMode = TravelMode.walking;
  geo.LocationPermission permission = geo.LocationPermission.denied;
  bool serviceEnabled = false;
  bool usingDemoLocation = true;
  Set<String> favorites = {};
  StreamSubscription<geo.Position>? positionSubscription;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    // Hủy luồng GPS khi màn hình bị gỡ để tránh giữ tài nguyên nền.
    positionSubscription?.cancel();
    super.dispose();
  }

  /// Đọc lựa chọn đã lưu trên máy, sau đó lấy vị trí theo chế độ tương ứng.
  Future<void> _bootstrap() async {
    try {
      usingDemoLocation = await prefs.demoLocation(fallback: true);
      favorites = await prefs.favorites();
    } catch (_) {
      usingDemoLocation = true;
    }
    await refreshLocation();
  }

  /// Chế độ mô phỏng dùng tọa độ cố định; chế độ thật kiểm tra và xin quyền GPS.
  Future<void> refreshLocation() async {
    // Mô phỏng giúp trình diễn trên máy ảo mà không cần tín hiệu GPS thật.
    // Trạng thái quyền và dịch vụ ở nhánh này cũng là trạng thái mô phỏng.
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
    // Ghi nhận dịch vụ định vị có bật hay không và kiểm tra quyền hệ điều hành.
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
      // Lấy vị trí ban đầu, rồi nghe cập nhật khi thiết bị di chuyển.
      _setLocation(position);
      await positionSubscription?.cancel();
      positionSubscription = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          // Ngưỡng dịch chuyển 10 mét để giảm số lần cập nhật vị trí.
          distanceFilter: 10,
        ),
      ).listen(_setLocation);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  // Sau tác vụ bất đồng bộ, kiểm tra mounted trước khi gọi setState.
  void _setLocation(geo.Position position) {
    if (!mounted) return;
    setState(
      () => userLocation = LatLng(position.latitude, position.longitude),
    );
  }

  /// Đổi trạng thái trên giao diện rồi lưu tập mã trụ sở vào bộ nhớ máy.
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

  /// Nhờ hệ điều hành mở ứng dụng điện thoại; báo lỗi nếu không mở được.
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
    // Màn hình con nhận dữ liệu và callback từ màn hình cha.
    // Callback giúp thao tác ở tab danh sách có thể chuyển sang tab bản đồ.
    final pages = [
      MapScreen(
        userLocation: userLocation,
        usingDemoLocation: usingDemoLocation,
        routeStation: routeStation,
        focusStation: focusStation,
        routeMode: routeMode,
        // Xóa yêu cầu sau khi bản đồ đã nhận để tránh xử lý lặp.
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
        onRefresh: refreshLocation,
        onToggleDemo: (value) async {
          setState(() => usingDemoLocation = value);
          await prefs.setDemoLocation(value);
          await refreshLocation();
        },
        onCallEmergency: _call,
      ),
    ];

    return Scaffold(
      // IndexedStack giữ trạng thái các tab khi đổi tab, gồm cả bản đồ.
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

/// Một nút điều hướng phía dưới; dấu gạch dưới giới hạn lớp trong thư viện Dart này.
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
