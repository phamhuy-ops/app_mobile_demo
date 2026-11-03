import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_demo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kiểm thử giao diện hiện có: dựng ứng dụng và kiểm tra nhãn ba tab chính.
// Kiểm thử này không gọi main(), nên không khởi tạo Firebase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Dùng bộ nhớ giả để kiểm thử không phụ thuộc dữ liệu đã lưu trên máy thật.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the three main NaviSafe sections', (tester) async {
    await tester.pumpWidget(const NaviSafeApp());
    await tester.pump();
    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Trụ sở'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });
}
