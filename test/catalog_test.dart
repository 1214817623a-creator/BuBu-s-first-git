import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubu_kitchen/content.dart';
import 'package:bubu_kitchen/catalog_filter.dart';
import 'package:bubu_kitchen/ingredient_line.dart';
import 'package:bubu_kitchen/models.dart';
import 'package:bubu_kitchen/main.dart';
import 'package:bubu_kitchen/kitchen_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCatalog);
  test('release content counts, IDs, sources and step references', () async {
    await loadCatalog(); // Idempotent initialization must not double the catalog.
    expect(recipes.length, originalRecipes.length + 100);
    expect(knowledgeCards.length, originalKnowledge.length + 300);
    expect(recipes.map((r) => r.id).toSet().length, recipes.length);
    expect(recipes.map((r) => r.name).toSet().length, recipes.length);
    expect(
      knowledgeCards.map((k) => k.id).toSet().length,
      knowledgeCards.length,
    );
    final knowledgeIds = knowledgeCards.map((k) => k.id).toSet();
    for (final r in recipes) {
      expect(r.steps.length, greaterThanOrEqualTo(3), reason: r.name);
      expect(r.months, isNotEmpty);
      expect(
        r.tags.every(recipeFilterGroups.values.expand((g) => g).contains),
        isTrue,
        reason: r.name,
      );
      for (final i in r.ingredients) {
        expect(i.amount, greaterThan(0));
        expect(i.unit, isNot(contains('（')), reason: r.name);
      }
      for (final step in r.steps) {
        expect(step.instruction, isNotEmpty);
        expect(step.cue, isNotEmpty);
        expect(
          knowledgeIds.containsAll(step.knowledge),
          isTrue,
          reason: '${r.name}: ${step.knowledge}',
        );
      }
    }
    final hosts = {
      'www.fsis.usda.gov',
      'www.foodsafety.gov',
      'www.govinfo.gov',
      'www.fda.gov',
      'www.usfa.fema.gov',
      'www.cfs.gov.hk',
      'www.who.int',
      'iastate.pressbooks.pub',
    };
    for (final k in knowledgeCards.skip(originalKnowledge.length)) {
      expect(hosts.contains(Uri.parse(k.sourceUrl).host), isTrue, reason: k.id);
      expect(k.sourceName, isNotEmpty);
      expect(k.alternative, isNotEmpty);
      expect(k.actionTitle, '操作要点');
    }
    for (final r in recipes.skip(originalRecipes.length)) {
      expect(Uri.parse(r.sourceUrl).scheme, 'https');
      expect(r.art, r.id);
    }
  });
  test('multiword queries AND tags, separators and whitespace', () {
    for (final query in ['番茄 牛肉', ' 番茄，牛肉 ', '番茄、牛肉']) {
      final found = filterRecipes(recipes, {'牛肉'}, query);
      expect(found.map((r) => r.id), contains('tomato-beef'));
      expect(
        found.every((r) => r.ingredients.any((i) => i.name.contains('番茄'))),
        isTrue,
      );
    }
    expect(filterRecipes(recipes, {'猪肉', '牛肉'}, ''), isEmpty);
    expect(filterRecipes(recipes, {}, '完全不存在的菜'), isEmpty);
  });
  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('quantity stays compact and note gets own line at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: const [
                    IngredientLine(
                      Ingredient('盐', 2, '克', note: '最后尝味调整'),
                      4,
                      2,
                    ),
                    IngredientLine(
                      Ingredient('热水', 800, '毫升', note: '以接近没过食材为准，炖煮中按蒸发量补充'),
                      4,
                      2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('最后尝味调整')).dy,
        greaterThan(tester.getBottomLeft(find.text('盐')).dy),
      );
      expect(find.text('1600毫升'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('expanded knowledge search and incremental loading', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = KitchenState(await SharedPreferences.getInstance());
    await tester.pumpWidget(KitchenApp(state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('厨房知识'));
    await tester.pumpAndSettle();
    expect(find.text('318 条知识'), findsOneWidget);
    await tester.ensureVisible(find.text('加载更多知识（已显示 30 / 318）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加载更多知识（已显示 30 / 318）'));
    await tester.pumpAndSettle();
    expect(find.text('加载更多知识（已显示 60 / 318）'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'FDA 芝麻');
    await tester.pumpAndSettle();
    expect(find.text('1 条知识'), findsOneWidget);
    expect(find.text('芝麻属于主要过敏原'), findsOneWidget);
    await tester.ensureVisible(find.text('芝麻属于主要过敏原'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('芝麻属于主要过敏原'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('香油和芝麻酱均需关注。'),
      ),
      findsOneWidget,
    );
    expect(find.text('内容依据 · FDA · Food Allergies'), findsOneWidget);
    expect(find.text('操作要点'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
