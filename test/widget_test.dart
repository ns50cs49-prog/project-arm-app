import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('confirm booking opens appointment page', (tester) async {
    await tester.pumpWidget(const QueueApp());

    expect(find.text('ยืนยันการจองคิว'), findsOneWidget);

    await tester.tap(find.text('ยืนยันการจองคิว'));
    await tester.pumpAndSettle();

    expect(find.text('จองคิวสำเร็จ'), findsOneWidget);
  });
}
