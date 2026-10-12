import 'package:flutter_test/flutter_test.dart';

import 'package:ung_dung_ghi_chu_ca_nhan/main.dart';

void main() {
  testWidgets('Home hiển thị danh sách ghi chú', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ghi chú cá nhân'), findsOneWidget);
    expect(find.text('Thêm ghi chú'), findsOneWidget);
  });
}