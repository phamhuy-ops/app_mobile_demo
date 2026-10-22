import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TravelMode { walking, cycling, motorbike }

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

  String get osrmProfile => switch (this) {
    TravelMode.walking => 'foot',
    TravelMode.cycling => 'bike',
    TravelMode.motorbike => 'car',
  };
}

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
