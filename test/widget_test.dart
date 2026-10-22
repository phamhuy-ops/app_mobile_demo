import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_demo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
