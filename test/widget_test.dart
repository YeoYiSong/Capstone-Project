import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart'; // 修改這裡指向正確的檔案

void main() {
  testWidgets('smaily app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(Smaily2App()); // 使用正確的 Widget 名稱
    expect(find.byType(Smaily2App), findsOneWidget);
  });
}
