import 'package:latlong2/latlong.dart';

import 'models.dart';

const hutechKhuELocation = LatLng(10.855111458774154, 106.785421837618);
const defaultLocation = hutechKhuELocation;

const stations = <Station>[
  Station(
    id: 'cong-an-p-long-truong',
    name: 'Công an P. Long Trường',
    address: '893/1 đường Nguyễn Duy Trinh, phường Long Trường, TP. Thủ Đức, TP. HCM',
    phone: '028 3731 6010',
    point: LatLng(10.792036092821867, 106.7988290665225),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 07:30–17:00; Thứ 7, 07:30–11:30; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-thu-duc',
    name: 'Công an P. Thủ Đức',
    address: '371 Đoàn Kết, P, Thủ Đức, Hồ Chí Minh 70000, Việt Nam',
    phone: '028 3897 2025',
    point: LatLng(10.849200704899811, 106.768724795359),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 07:30–17:00; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-hiep-binh',
    name: 'Công an P. Hiệp Bình',
    address: '46 Đ. Lý Tế Xuyên, Hiệp Bình, Hồ Chí Minh 700000, Việt Nam',
    phone: '028 3897 9003',
    point: LatLng(10.858377497933805, 106.74786769700155),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6 và sáng Thứ 7; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-long-phuoc',
    name: 'Công an P. Long Phước',
    address: '239 Long Phước, Hồ Chí Minh, Việt Nam',
    phone: '028 3887 3190',
    point: LatLng(10.81049688078899, 106.85942028925164),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 07:30–11:30 và 13:30–17:00; sáng Thứ 7; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-binh-trung',
    name: 'Công an P. Bình Trưng',
    address: '197 Nguyễn Duy Trinh, Bình Trưng, Hồ Chí Minh 700000, Việt Nam',
    phone: '028 3743 0165',
    point: LatLng(10.788151845135943, 106.76151241515514),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 08:00–11:30 và 13:30–17:00; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-long',
    name: 'Công an P. Phước Long A',
    address: 'Liền kề 6G, 94 Đ. Nam Hoà, Phước Long, Hồ Chí Minh 80000, Việt Nam',
    phone: '028 3897 8421',
    point: LatLng(10.828753958239925, 106.76254122078501),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 08:00–12:00 và 13:30–17:00; trực ban an ninh: 24/24.',
  ),
  Station(
    id: 'cong-an-p-cat-lai',
    name: 'Công an P. Cát Lái',
    address: '705/3 Nguyễn Thị Định, Cát Lái, Hồ Chí Minh 700000, Việt Nam',
    phone: '028 3742 0256',
    point: LatLng(10.774867781476622, 106.76994621070034),
    status: 'TRỰC BAN 24/7',
    hours: 'Tiếp dân hành chính: Thứ 2–Thứ 6, 07:30–11:30 và 13:00–17:00; trực ban an ninh: 24/24.',
  ),
];
