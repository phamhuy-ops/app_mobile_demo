import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../theme.dart';
import '../widgets.dart';

/// Hiển thị trạng thái định vị và các tùy chọn do màn hình cha quản lý.
/// StatelessWidget dựng lại theo dữ liệu truyền vào, không tự lưu thiết lập.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.serviceEnabled,
    required this.permission,
    required this.usingDemoLocation,
    required this.onRefresh,
    required this.onToggleDemo,
    required this.onCallEmergency,
  });

  final bool serviceEnabled;
  final geo.LocationPermission permission;
  final bool usingDemoLocation;
  final VoidCallback onRefresh;
  final ValueChanged<bool> onToggleDemo;
  final ValueChanged<String> onCallEmergency;

  // Chuyển trạng thái quyền thành nội dung tiếng Việt cho giao diện.
  String get permissionLabel =>
      permission == geo.LocationPermission.deniedForever
      ? 'Bị từ chối vĩnh viễn'
      : permission == geo.LocationPermission.denied
      ? 'Chưa cấp quyền'
      : 'Đã cấp quyền';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: paper,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quyền vị trí, bản đồ và số khẩn cấp.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 22),
            const _Section('Vị trí'),
            SettingTile(
              icon: Icons.location_on_outlined,
              title: 'Quyền truy cập vị trí',
              value: permissionLabel,
              onTap: () async {
                // Mở cài đặt quyền của ứng dụng rồi yêu cầu kiểm tra lại trạng thái.
                await geo.Geolocator.openAppSettings();
                onRefresh();
              },
            ),
            SettingTile(
              icon: Icons.gps_fixed,
              title: 'Dịch vụ định vị',
              value: serviceEnabled ? 'Đang bật' : 'Đang tắt',
              onTap: () async {
                // Mở cài đặt dịch vụ định vị của hệ điều hành.
                await geo.Geolocator.openLocationSettings();
                onRefresh();
              },
            ),
            SettingTile(
              icon: Icons.science_outlined,
              title: 'Vị trí mô phỏng HUTECH E',
              value: usingDemoLocation
                  ? 'Bật · dùng khi máy ảo chưa có GPS'
                  : 'Tắt · dùng GPS thiết bị',
              // Callback ở main.dart sẽ lưu lựa chọn và chuyển nguồn vị trí.
              trailing: Switch(
                value: usingDemoLocation,
                onChanged: onToggleDemo,
              ),
            ),
            const SizedBox(height: 12),
            const _Section('Bản đồ'),
            const SettingTile(
              icon: Icons.map_outlined,
              title: 'Nguồn bản đồ & GPS',
              value: 'OSM + OSRM công cộng · Geolocator dùng GPS máy, không cần key',
            ),
            const SizedBox(height: 12),
            const _Section('Khẩn cấp'),
            SettingTile(
              icon: Icons.sos,
              title: 'Gọi 113',
              value: 'Công an',
              onTap: () => onCallEmergency('113'),
            ),
            SettingTile(
              icon: Icons.local_fire_department_outlined,
              title: 'Gọi 114',
              value: 'Cứu hỏa',
              onTap: () => onCallEmergency('114'),
            ),
            SettingTile(
              icon: Icons.medical_services_outlined,
              title: 'Gọi 115',
              value: 'Cấp cứu',
              onTap: () => onCallEmergency('115'),
            ),
            const SizedBox(height: 12),
            const _Section('Về ứng dụng'),
            const SettingTile(
              icon: Icons.info_outline,
              title: 'NaviSafe',
              value: '1.0.0 · prototype hỗ trợ tìm trụ sở gần bạn',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Cập nhật trạng thái vị trí'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề nhóm cài đặt, dùng lại để thống nhất cách trình bày.
class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w800,
        color: navyMid,
      ),
    ),
  );
}
