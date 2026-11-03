import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

/// Gọi máy chủ OSRM để lấy tuyến đường theo mạng lưới đường giao thông.
/// Bản đồ nền và định tuyến là hai dịch vụ riêng biệt.
class RoutingService {
  Future<RouteResult> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    required TravelMode mode,
  }) async {
    final profile = mode.osrmProfile;
    // URL OSRM dùng thứ tự kinh độ,vĩ độ, ngược với hàm tạo LatLng.
    // overview=full lấy toàn bộ đường; geometries=geojson trả về mảng tọa độ.
    final url = Uri.parse(
      'https://routing.openstreetmap.de/routed-$profile/route/v1/$profile/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );
    // Yêu cầu mạng bất đồng bộ; lỗi được chuyển lên màn hình gọi dịch vụ.
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('route failed');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List<dynamic>;
    if (routes.isEmpty) throw Exception('no route');
    // Bản mẫu chỉ sử dụng tuyến đầu tiên do máy chủ trả về.
    final route = routes.first as Map<String, dynamic>;
    final coordinates = route['geometry']['coordinates'] as List<dynamic>;
    // GeoJSON lưu [kinh độ, vĩ độ]; đổi lại thành LatLng(vĩ độ, kinh độ).
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

/// Mở liên kết tel: bằng ứng dụng điện thoại do hệ điều hành cung cấp.
class PhoneService {
  Future<bool> call(String number) async {
    // Bỏ dấu cách và dấu phân nhóm, giữ chữ số và dấu cộng trong số gọi.
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}

/// Lưu thiết lập đơn giản trên thiết bị bằng SharedPreferences.
/// Đây là lưu trữ cục bộ, không đồng bộ lên Firebase hoặc sang thiết bị khác.
class AppPrefs {
  static const _demoKey = 'use_demo_location';
  static const _favoritesKey = 'favorite_stations';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> demoLocation({required bool fallback}) async =>
      (await _prefs).getBool(_demoKey) ?? fallback;

  Future<void> setDemoLocation(bool value) async =>
      (await _prefs).setBool(_demoKey, value);

  // Lưu dạng danh sách chuỗi, đọc thành Set để tra cứu và tránh trùng mã.
  Future<Set<String>> favorites() async =>
      ((await _prefs).getStringList(_favoritesKey) ?? const []).toSet();

  Future<void> setFavorites(Set<String> ids) async =>
      (await _prefs).setStringList(_favoritesKey, ids.toList());
}

/// Đổi mét thành chuỗi dễ đọc: dưới 1 km dùng m, còn lại dùng km.
String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

/// Đổi thời gian từ giây sang phút hoặc giờ để hiển thị kết quả định tuyến.
String formatDuration(double seconds) {
  final total = seconds.round();
  if (total < 60) return '< 1 phút';
  final minutes = (total / 60).round();
  if (minutes < 60) return '$minutes phút';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours giờ' : '$hours giờ $rest phút';
}

/// Nhóm chữ số điện thoại đầu 028 để dễ đọc; không sửa số dùng để gọi.
String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 11 && digits.startsWith('028')) {
    return '(028) ${digits.substring(3, 7)} ${digits.substring(7)}';
  }
  return phone;
}
