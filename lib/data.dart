import 'package:latlong2/latlong.dart';

import 'models.dart';

const hutechKhuELocation = LatLng(10.870095, 106.803393);
const defaultLocation = hutechKhuELocation;

const stations = <Station>[
  Station(
    id: 'linh-trung',
    name: 'Công an P. Linh Trung',
    address: '12 Đường Hoàng Diệu 2, P. Linh Trung',
    phone: '02800001122',
    point: LatLng(10.8708, 106.7934),
    status: 'TRỰC 24/7',
    hours: 'Trực liên tục, tiếp nhận tố giác 24/24',
  ),
  Station(
    id: 'dong-hoa',
    name: 'Công an P. Đông Hòa',
    address: '48 Đường Tân Lập, P. Đông Hòa',
    phone: '02800002233',
    point: LatLng(10.8765, 106.7787),
    status: 'TRỰC 24/7',
    hours: 'Trực liên tục, tiếp nhận tố giác 24/24',
  ),
  Station(
    id: 'lang-dh',
    name: 'Điểm tiếp nhận Làng Đại học',
    address: '05 Đường Mạc Đĩnh Chi, P. Đông Hòa',
    phone: '02800003344',
    point: LatLng(10.8568, 106.8062),
    status: 'GIỜ TIẾP NHẬN',
    hours: '07:30 – 17:00 (T2–T6), nghỉ cuối tuần',
    open: false,
  ),
  Station(
    id: 'linh-xuan',
    name: 'Công an P. Linh Xuân',
    address: '27 Quốc lộ 1K, P. Linh Xuân',
    phone: '02800004455',
    point: LatLng(10.8809, 106.7761),
    status: 'TRỰC 24/7',
    hours: 'Trực liên tục, có điểm tuần tra đêm',
  ),
  Station(
    id: 'thu-duc',
    name: 'Công an TP. Thủ Đức',
    address: '168 Võ Văn Ngân, P. Bình Thọ',
    phone: '02800005566',
    point: LatLng(10.8506, 106.7719),
    status: 'TRỰC 24/7',
    hours: 'Trực chỉ huy 24/24',
  ),
];
