// Export the cover art contact sheet with --update-goldens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubu_kitchen/content.dart';
import 'package:bubu_kitchen/dish_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCatalog);
  testWidgets('all dish illustrations render without errors', (tester) async {
    tester.view.physicalSize = const Size(1440, 2160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final r in recipes)
                SizedBox(
                  width: 240,
                  height: 120,
                  child: Column(
                    children: [
                      SizedBox(height: 98, width: 215, child: DishArt(r)),
                      Text(r.name, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/v1.1.0/菜品插画总览.png'),
    );
  });
}
