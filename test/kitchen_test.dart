import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubu_kitchen/main.dart';
import 'package:bubu_kitchen/kitchen_state.dart';
import 'package:bubu_kitchen/content.dart';
import 'package:bubu_kitchen/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<KitchenState> fresh() async {
    SharedPreferences.setMockInitialValues({});
    return KitchenState(await SharedPreferences.getInstance());
  }

  test('seasonal recipe selection changes with month', () {
    expect(seasonalRecipes(10).map((r) => r.id), contains('chestnut-chicken'));
    expect(
      seasonalRecipes(4).map((r) => r.id),
      isNot(contains('chestnut-chicken')),
    );
    expect(
      List.generate(12, (i) => seasonalRecipes(i + 1).isNotEmpty),
      everyElement(isTrue),
    );
  });
  test('all steps have valid knowledge and measurable quantities', () {
    final ids = knowledgeCards.map((k) => k.id).toSet();
    for (final r in recipes) {
      expect(r.steps, isNotEmpty);
      for (final step in r.steps) {
        expect(ids.containsAll(step.knowledge), isTrue);
      }
      for (final i in r.ingredients) {
        expect(i.amount, greaterThan(0));
      }
    }
    expect(recipes.first.ingredients.first.quantity(4, 2), '1000克');
  });
  test(
    'save and restore favorites, serving count, checks, font and cooking step',
    () async {
      final s = await fresh();
      s.favorite('tomato-beef');
      s.favorite('wash-meat', knowledge: true);
      s.prepare(recipes.first, 4);
      s.check('牛腩');
      s.move(3);
      s.setFont(34);
      await s.save();
      final restored = KitchenState(await SharedPreferences.getInstance());
      expect(restored.favorites, contains('tomato-beef'));
      expect(restored.savedKnowledge, contains('wash-meat'));
      expect(restored.servings, 4);
      expect(restored.checked, contains('牛腩'));
      expect(restored.step, 3);
      expect(restored.fontSize, 34);
    },
  );
  test(
    'timer deadline survives restore, pause freezes remaining and finish clears reminders',
    () async {
      final s = await fresh();
      s.prepare(recipes.first, 2);
      await s.startTimer(recipes.first, 4, seconds: 120);
      await s.startTimer(recipes.first, 4, seconds: 120);
      expect(s.timers.length, 1);
      final restored = KitchenState(await SharedPreferences.getInstance());
      final t = restored.timers.single;
      expect(
        t.remaining(DateTime.now().add(const Duration(seconds: 30))),
        inInclusiveRange(89, 90),
      );
      await restored.pause(t);
      final left = t.remaining(DateTime.now());
      expect(t.remaining(DateTime.now().add(const Duration(minutes: 3))), left);
      await restored.resume(t, recipes.first);
      expect(t.paused, isFalse);
      await restored.finish();
      expect(restored.timers, isEmpty);
      expect(restored.currentRecipe, isNull);
      expect(restored.completed, 1);
    },
  );
  test('expired and paused timers are distinct', () {
    final t = KitchenTimer(
      id: 1,
      recipeId: 'tomato-beef',
      step: 1,
      label: 'test',
      totalSeconds: 180,
      deadline: DateTime(2020),
    );
    expect(t.remaining(DateTime.now()), 0);
    expect(t.paused, isFalse);
  });
  for (final width in [360.0, 412.0, 1100.0]) {
    testWidgets('home and recipe detail fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = await fresh();
      await tester.pumpWidget(KitchenApp(s));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('看看这道菜'));
      await tester.pumpAndSettle();
      expect(find.text('开始准备食材'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('开始准备食材'));
      await tester.pumpAndSettle();
      expect(find.text('把食材备齐吧'), findsOneWidget);
      for (final i in recipes.first.ingredients) {
        s.check(i.name);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('食材齐了，开始做（8/8）'));
      await tester.pump(const Duration(milliseconds: 500));
      s.setFont(34);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('切牛腩，准备配菜'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -650));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('下一步 →'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.getTopLeft(find.text('牛腩冷水下锅焯水')).dy,
        inInclusiveRange(80, 220),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
