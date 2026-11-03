import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Các kiểu dữ liệu dùng chung, giúp màn hình và dịch vụ trao đổi có cấu trúc.

/// Ba phương thức di chuyển mà giao diện cho phép chọn.
enum TravelMode { walking, cycling, motorbike }

/// Bổ sung nhãn, biểu tượng và hồ sơ định tuyến cho mỗi phương thức.
extension TravelModeX on TravelMode {
  String get label => switch (this) {
    TravelMode.walking => 'Đi bộ',
    TravelMode.cycling => 'Xe đạp',
    TravelMode.motorbike => 'Xe máy',
  };

  IconData get icon => switch (this) {
    TravelMode.walking => Icons.directions_walk,
    TravelMode.cycling => Icons.directions_bike,
    TravelMode.motorbike => Icons.two_wheeler,
  };

  // Xe máy đang dùng hồ sơ ô tô (car), chưa có hồ sơ xe máy chuyên biệt.
  String get osrmProfile => switch (this) {
    TravelMode.walking => 'foot',
    TravelMode.cycling => 'bike',
    TravelMode.motorbike => 'car',
  };
}

/// Một trụ sở: mã định danh, thông tin liên hệ, tọa độ và trạng thái hiển thị.
/// open là dữ liệu có sẵn, không được tự tính theo giờ hiện tại.
class Station {
  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.point,
    required this.status,
    required this.hours,
    this.open = true,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final LatLng point;
  final String status;
  final String hours;
  final bool open;
}

/// Kết quả định tuyến: các điểm vẽ đường, tổng chiều dài (m) và thời gian (giây).
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

/// Thông tin hiển thị và số điện thoại của một lựa chọn khẩn cấp.
class EmergencyContact {
  const EmergencyContact({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.number,
  });

  final String code;
  final String title;
  final String subtitle;
  final String number;
}

// Danh mục dùng cho bảng SOS trên bản đồ.
const emergencyContacts = [
  EmergencyContact(
    code: '113',
    title: 'Công an',
    subtitle: 'Khẩn cấp an ninh, trật tự',
    number: '113',
  ),
  EmergencyContact(
    code: '114',
    title: 'Cứu hỏa',
    subtitle: 'Cháy nổ, cứu hộ',
    number: '114',
  ),
  EmergencyContact(
    code: '115',
    title: 'Cấp cứu',
    subtitle: 'Y tế khẩn cấp',
    number: '115',
  ),
];
