// Export real Flutter renders for review. Run with --update-goldens.
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubu_kitchen/main.dart';
import 'package:bubu_kitchen/kitchen_state.dart';
import 'package:bubu_kitchen/content.dart';

void main() {
  testWidgets('export phone screens', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final font = FontLoader('KitchenSans')
      ..addFont(rootBundle.load('assets/fonts/NotoSansSC.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final s = KitchenState(await SharedPreferences.getInstance());
    await tester.pumpWidget(KitchenApp(s));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/首页.png'),
    );
    s.prepare(recipes.first, 2);
    s.move(4);
    final context = tester.element(find.byType(HomeScreen));
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CookScreen(s, recipes.first)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/做菜模式.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
