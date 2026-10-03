import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'content.dart';
import 'food_art.dart';
import 'kitchen_state.dart';
import 'models.dart';
import 'ingredient_line.dart';
import 'dish_art.dart';
import 'catalog_filter.dart';

const ink = Color(0xFF293A2D),
    muted = Color(0xFF737D70),
    orange = Color(0xFFCF552D);
const paper = Color(0xFFFAF9F4), sage = Color(0xFFEBEFE3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadCatalog();
  if (kIsWeb) WidgetsBinding.instance.ensureSemantics();
  final state = KitchenState(await SharedPreferences.getInstance());
  unawaited(state.restoreAlarms(recipes));
  runApp(KitchenApp(state));
}

class KitchenApp extends StatelessWidget {
  final KitchenState state;
  const KitchenApp(this.state, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '布布大王的菜谱',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: paper,
      fontFamily: 'KitchenSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        primary: orange,
        surface: paper,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 15, height: 1.7, color: ink),
        bodyLarge: TextStyle(fontSize: 17, height: 1.65, color: ink),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'KitchenSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE0E5DA)),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: paper,
        indicatorColor: Color(0xFFF8DDCA),
      ),
    ),
    home: HomeScreen(state),
  );
}

void snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<bool> confirm(
  BuildContext context,
  String title,
  String body,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(22),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: ink.withValues(alpha: 0.05)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = sage});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class HomeScreen extends StatefulWidget {
  final KitchenState state;
  const HomeScreen(this.state, {super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final Set<String> selectedTags = {};
  String query = '', knowledgeQuery = '';
  int recipeLimit = 24, knowledgeLimit = 30;
  final search = TextEditingController();
  KitchenState get s => widget.state;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void detail(Recipe r) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => RecipeScreen(s, r)),
  );
  void resume() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          CookScreen(s, recipes.firstWhere((r) => r.id == s.currentRecipe)),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.soup_kitchen_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '布布大王的菜谱',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'BUBU’S KITCHEN',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '厨房设置',
                          onPressed: () => settings(context, s),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.persistenceError != null)
                          notice(s.persistenceError!),
                        if (s.currentRecipe != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Panel(
                              color: const Color(0xFFFFEFDF),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant_rounded,
                                    color: orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '你的厨房进度已保存',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${recipes.firstWhere((r) => r.id == s.currentRecipe).name} · ${s.step < 0 ? '准备食材' : '第 ${s.step + 1} 步'}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: resume,
                                    child: const Text('继续做 →'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (tab == 0) ...home(),
                        if (tab == 1) ...findRecipes(),
                        if (tab == 2) ...library(),
                        if (tab == 3) ...favorites(),
                        const SizedBox(height: 30),
                        const Center(
                          child: Text(
                            '慢慢做，好好吃。',
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '今日厨房',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: '找道菜',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: '厨房知识',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: '我的收藏',
          ),
        ],
      ),
    ),
  );

  List<Widget> home() {
    final month = DateTime.now().month,
        season = seasonName(DateTime.now().month);
    final featured = seasonalRecipes(month).first;
    return [
      const SizedBox(height: 22),
      Row(
        children: [
          const Tag('每一道菜，都有一个为什么'),
          const Spacer(),
          Text(
            '$month 月 · $season日厨房',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        '吃好每一顿，\n也懂每一步。',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.35,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '从一份食材，到一桌好菜。布布陪你慢慢学。',
        style: TextStyle(color: muted, fontSize: 14),
      ),
      const SizedBox(height: 24),
      LayoutBuilder(
        builder: (context, c) {
          final small = c.maxWidth < 600;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag(
                '$season日厨房 · 本月推荐',
                color: Colors.white.withValues(alpha: .6),
              ),
              const SizedBox(height: 16),
              Text(
                '当季的家常味\n从${featured.name}开始',
                style: const TextStyle(
                  fontSize: smallFont,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${featured.subtitle}。\n学会一道菜，也学会一点厨房的道理。',
                style: const TextStyle(fontSize: 14, color: Color(0xFF53634D)),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => detail(featured),
                label: const Text('看看这道菜'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              ),
            ],
          );
          return Panel(
            color: const Color(0xFFDFE7D2),
            padding: EdgeInsets.all(small ? 22 : 32),
            child: small
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      text,
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 165,
                        width: double.infinity,
                        child: DishArt(featured),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 5, child: text),
                      Expanded(
                        flex: 6,
                        child: SizedBox(height: 240, child: DishArt(featured)),
                      ),
                    ],
                  ),
          );
        },
      ),
      SectionTitle('$month 月的时令小篮子', '按月份推荐 · 各地上市时间略有差异'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: (monthlyIngredients[month] ?? [])
            .map(
              (name) => ActionChip(
                label: Text(name),
                avatar: Icon(
                  name == '栗子' ? Icons.spa_outlined : Icons.eco_outlined,
                  size: 18,
                  color: const Color(0xFF6C835A),
                ),
                backgroundColor: Colors.white,
                side: BorderSide.none,
                onPressed: () => setState(() {
                  tab = 1;
                  query = name;
                  search.text = name;
                  selectedTags.clear();
                }),
              ),
            )
            .toList(),
      ),
      SectionTitle(
        '今天，想做点什么？',
        '给好好生活的你，几道家常灵感',
        trailing: TextButton(
          onPressed: () => setState(() => tab = 1),
          child: const Text('全部菜谱 →'),
        ),
      ),
      recipeGrid(seasonalRecipes(month).take(4).toList()),
      const SectionTitle('小知识，大不同', '懂一个为什么，下次就多一分把握'),
      knowledgeTile(knowledgeCards.firstWhere((k) => k.id == 'tomato-two')),
    ];
  }

  static const double smallFont = 29;
  List<Widget> findRecipes() {
    final list = filterRecipes(recipes, selectedTags, query);
    return [
      const SectionTitle('找一道想吃的菜', '从熟悉的家常味开始'),
      TextField(
        controller: search,
        decoration: InputDecoration(
          hintText: '搜菜名、食材，多词用空格分开',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  tooltip: '清空搜索',
                  onPressed: () {
                    search.clear();
                    setState(() => query = '');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
        ),
        onChanged: (v) => setState(() {
          query = v;
          recipeLimit = 24;
        }),
      ),
      const SizedBox(height: 20),
      const Text(
        '标签可多选，菜谱需同时符合所选标签',
        style: TextStyle(color: muted, fontSize: 13),
      ),
      const SizedBox(height: 12),
      ...recipeFilterGroups.entries.map((group) {
        final items = [group.key, ...group.value];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  items.first,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ),
              ...items
                  .skip(1)
                  .map(
                    (t) => FilterChip(
                      label: Text(t),
                      selected: selectedTags.contains(t),
                      onSelected: (selected) => setState(() {
                        recipeLimit = 24;
                        if (selected) {
                          selectedTags.add(t);
                        } else {
                          selectedTags.remove(t);
                        }
                      }),
                      side: BorderSide.none,
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFFFDEC9),
                    ),
                  ),
            ],
          ),
        );
      }),
      Row(
        children: [
          Text('${list.length} 道菜谱', style: const TextStyle(color: muted)),
          const Spacer(),
          if (selectedTags.isNotEmpty)
            TextButton(
              onPressed: () => setState(selectedTags.clear),
              child: Text('清除筛选（${selectedTags.length}）'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (list.isEmpty)
        Panel(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: muted),
              const SizedBox(height: 12),
              const Text('暂时没有这道菜'),
              const Text(
                '试试减少所选标签、换个关键词，或者清除筛选。',
                style: TextStyle(color: muted),
              ),
              TextButton(
                onPressed: () => setState(() {
                  selectedTags.clear();
                  query = '';
                  search.clear();
                }),
                child: const Text('查看全部菜谱'),
              ),
            ],
          ),
        )
      else
        recipeGrid(list.take(recipeLimit).toList()),
      if (list.length > recipeLimit)
        TextButton(
          onPressed: () => setState(() => recipeLimit += 24),
          child: Text(
            '加载更多菜谱（已显示 ${recipeLimit.clamp(0, list.length)} / ${list.length}）',
          ),
        ),
    ];
  }

  List<Widget> library() {
    final words = knowledgeQuery
        .trim()
        .split(RegExp(r'[\s,，、]+'))
        .where((w) => w.isNotEmpty);
    final list = knowledgeCards
        .where(
          (k) => words.every(
            (w) =>
                '${k.title} ${k.category} ${k.summary} ${k.explanation} ${k.sourceName}'
                    .contains(w),
          ),
        )
        .toList();
    return [
      const SectionTitle('厨房里的「为什么」', '食材、方法与安全，逐条查看内容依据'),
      TextField(
        decoration: const InputDecoration(
          hintText: '搜索主题或机构，比如「冷藏」「FDA」',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() {
          knowledgeQuery = v;
          knowledgeLimit = 30;
        }),
      ),
      const SizedBox(height: 20),
      Text('${list.length} 条知识', style: const TextStyle(color: muted)),
      const SizedBox(height: 12),
      ...list.take(knowledgeLimit).map(knowledgeTile),
      if (list.isEmpty) const Panel(child: Text('暂未找到，请调整关键词。')),
      if (list.length > knowledgeLimit)
        TextButton(
          onPressed: () => setState(() => knowledgeLimit += 30),
          child: Text(
            '加载更多知识（已显示 ${knowledgeLimit.clamp(0, list.length)} / ${list.length}）',
          ),
        ),
    ];
  }

  List<Widget> favorites() => [
    SectionTitle(
      '我的厨房收藏',
      '收藏 ${s.favorites.length} 道菜 · 学会做菜 ${s.completed} 次',
    ),
    if (s.favorites.isEmpty)
      Panel(
        color: sage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite_border, size: 32),
            const SizedBox(height: 12),
            const Text(
              '把想做的菜，先放在这里',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const Text('点菜谱上的爱心，下次更快找到。'),
            TextButton(
              onPressed: () => setState(() => tab = 1),
              child: const Text('去找一道菜 →'),
            ),
          ],
        ),
      )
    else
      recipeGrid(recipes.where((r) => s.favorites.contains(r.id)).toList()),
    const SectionTitle('收藏的知识', '你的随身厨房笔记'),
    if (s.savedKnowledge.isEmpty)
      const Text('打开知识卡，点「收藏知识」即可保存。', style: TextStyle(color: muted)),
    ...knowledgeCards
        .where((k) => s.savedKnowledge.contains(k.id))
        .map(knowledgeTile),
  ];
  Widget recipeGrid(List<Recipe> list) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth > 850
          ? 4
          : c.maxWidth > 560
          ? 3
          : 2;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: list
            .map(
              (r) => SizedBox(
                width: (c.maxWidth - (columns - 1) * 16) / columns,
                child: RecipeCard(s, r, onTap: () => detail(r)),
              ),
            )
            .toList(),
      );
    },
  );
  Widget knowledgeTile(Knowledge k) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showKnowledge(context, s, k),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sage,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF758B54),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      k.summary,
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class RecipeCard extends StatelessWidget {
  final KitchenState state;
  final Recipe recipe;
  final VoidCallback onTap;
  const RecipeCard(this.state, this.recipe, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 145,
            color: Color(recipe.color),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: DishArt(recipe),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    tooltip: state.favorites.contains(recipe.id)
                        ? '取消收藏'
                        : '收藏菜谱',
                    onPressed: () => state.favorite(recipe.id),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .8),
                    ),
                    icon: Icon(
                      state.favorites.contains(recipe.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: orange,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.subtitle,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    Text(
                      '约 ${recipe.totalMinutes} 分钟',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    Text(
                      '· ${recipe.tags.last}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget notice(String body, {bool danger = false, double fontSize = 14}) =>
    Panel(
      color: danger ? const Color(0xFFFFEADF) : const Color(0xFFF1F0E7),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            danger ? Icons.shield_outlined : Icons.info_outline,
            size: 21,
            color: danger ? orange : muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.65,
                color: danger ? const Color(0xFF8B482F) : ink,
              ),
            ),
          ),
        ],
      ),
    );

void showKnowledge(BuildContext context, KitchenState state, Knowledge k) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: paper,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .4,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => AnimatedBuilder(
        animation: state,
        builder: (context, _) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Row(
              children: [
                Tag(k.category),
                const Spacer(),
                IconButton(
                  tooltip: '关闭知识卡',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              k.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              k.summary,
              style: const TextStyle(
                fontSize: 19,
                color: orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              k.explanation,
              style: const TextStyle(fontSize: 17, height: 1.9),
            ),
            const SizedBox(height: 24),
            Panel(
              color: sage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.actionTitle,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    k.alternative,
                    style: const TextStyle(fontSize: 16, height: 1.9),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '内容依据 · ${k.sourceName}',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            if (k.sourceUrl.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final ok = await launchUrl(
                      Uri.parse(k.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && context.mounted) {
                      snack(context, '暂时无法打开来源，请联网后重试。');
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('查看原始来源（需联网）'),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => state.favorite(k.id, knowledge: true),
              icon: Icon(
                state.savedKnowledge.contains(k.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
              label: Text(
                state.savedKnowledge.contains(k.id) ? '已收藏知识' : '收藏知识',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void settings(BuildContext context, KitchenState s) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: paper,
  builder: (c) => AnimatedBuilder(
    animation: s,
    builder: (c, _) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '让厨房更顺手',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          const Text('做菜字号'),
          fontControls(s),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('做菜时屏幕常亮'),
            subtitle: Text(s.android ? '仅在做菜页面生效' : '安卓版支持；浏览器请自行保持屏幕开启'),
            value: s.keepAwake,
            onChanged: (v) {
              s.keepAwake = v;
              unawaited(s.awake(s.cookingVisible));
              unawaited(s.save());
            },
          ),
          const SizedBox(height: 12),
          notice('计时按实际时间运行。暂停计时不会停止炉火，需你自己关火。后台通知受手机权限、省电和静音设置影响。'),
          if (s.android) ...[
            const SizedBox(height: 12),
            Text(s.notifications ? '通知权限已开启' : '通知权限未开启'),
            TextButton(
              onPressed: () => s.requestNotifications(),
              child: const Text('开启计时通知'),
            ),
            Text(
              s.exactAlarms ? '精确计时权限已开启' : '后台提醒可能延迟，建议保持做菜页面开启。',
              style: const TextStyle(color: muted, fontSize: 13),
            ),
            TextButton(
              onPressed: () => s.native('requestExact'),
              child: const Text('设置精确计时权限'),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            '布布大王的菜谱 · 1.1.0',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const Text(
            '6 道离线菜谱 · 18 张厨房知识卡\n收藏和进度保存在本机，无需登录。',
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    ),
  ),
);

Widget fontControls(KitchenState s) => Wrap(
  spacing: 8,
  children: [22.0, 26.0, 30.0, 34.0]
      .asMap()
      .entries
      .map(
        (e) => ChoiceChip(
          label: Text(['标准', '大', '更大', '超大'][e.key]),
          selected: s.fontSize == e.value,
          onSelected: (_) => s.setFont(e.value),
        ),
      )
      .toList(),
);

class RecipeScreen extends StatefulWidget {
  final KitchenState state;
  final Recipe recipe;
  const RecipeScreen(this.state, this.recipe, {super.key});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int count = 2;
  @override
  void initState() {
    super.initState();
    count = widget.recipe.servings;
  }

  KitchenState get s => widget.state;
  Recipe get r => widget.recipe;
  Future<void> start() async {
    if (s.currentRecipe != null && s.currentRecipe != r.id) {
      if (!await confirm(
        context,
        '厨房里还有一道菜',
        '开始新菜会清除上一道菜的备料进度和计时。先确认上一道菜的炉火已经关闭。',
        '已关火，开始新菜',
      )) {
        return;
      }
      await s.abandon();
    }
    if (s.currentRecipe != r.id) s.prepare(r, count);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CookScreen(s, r)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(r.name),
        actions: [
          IconButton(
            tooltip: s.favorites.contains(r.id) ? '取消收藏' : '收藏菜谱',
            onPressed: () => s.favorite(r.id),
            icon: Icon(
              s.favorites.contains(r.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: orange,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Panel(
                color: Color(r.color),
                padding: const EdgeInsets.all(16),
                child: SizedBox(height: 220, child: DishArt(r)),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.tags.map((t) => Tag(t)).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                r.subtitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                r.description,
                style: const TextStyle(color: muted, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Panel(
                color: sage,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    metric('约 ${r.totalMinutes} 分钟', '总用时'),
                    metric('${r.activeMinutes} 分钟', '动手准备与烹饪'),
                    metric('${r.waitMinutes} 分钟', '等待时间'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '时间是家庭烹饪估计，会随锅具、份量和食材变化。',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              SectionTitle(
                '备好这些食材',
                '份量调整会换算材料，烹饪时间仍需看实际状态',
                trailing: Row(
                  children: [
                    IconButton(
                      tooltip: '减少份量',
                      onPressed: count > 1
                          ? () => setState(() => count--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$count 人份'),
                    IconButton(
                      tooltip: '增加份量',
                      onPressed: count < 8
                          ? () => setState(() => count++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              Panel(
                child: Column(
                  children: r.ingredients
                      .map((i) => IngredientLine(i, count, r.servings))
                      .toList(),
                ),
              ),
              if (r.sourceUrl.isNotEmpty) ...[
                Text(
                  '选品参考 · ${r.sourceName}',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await launchUrl(
                        Uri.parse(r.sourceUrl),
                        mode: LaunchMode.externalApplication,
                      );
                      if (!ok && context.mounted) {
                        snack(context, '暂时无法打开来源，请联网后重试。');
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('查看选品参考（需联网）'),
                  ),
                ),
              ],
              const SectionTitle('准备好工具', '厨房顺手，做菜就更从容'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.tools
                    .map((t) => Tag(t, color: Colors.white))
                    .toList(),
              ),
              SectionTitle('这道菜怎么做', '${r.steps.length} 步，从准备到出锅'),
              ...r.steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: sage,
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(color: ink, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value.title)),
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              notice('开火前清理灶边易燃物；炒制与收汁时守在灶边。慢炖时留在家中，定期检查锅内水量。', danger: true),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: FilledButton.icon(
            onPressed: start,
            icon: const Icon(Icons.restaurant_rounded),
            label: Text(s.currentRecipe == r.id ? '继续做这道菜' : '开始准备食材'),
          ),
        ),
      ),
    ),
  );
  Widget metric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      Text(label, style: const TextStyle(fontSize: 12, color: muted)),
    ],
  );
}

class CookScreen extends StatefulWidget {
  final KitchenState state;
  final Recipe recipe;
  const CookScreen(this.state, this.recipe, {super.key});
  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> with WidgetsBindingObserver {
  Timer? ticker;
  final Set<String> surfaced = {};
  DateTime now = DateTime.now();
  KitchenState get s => widget.state;
  Recipe get r => widget.recipe;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(s.awake(true));
    unawaited(s.refreshPermissions());
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(s.awake(false));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(s.refreshPermissions());
      tick();
    }
  }

  void tick() {
    if (!mounted) return;
    setState(() => now = DateTime.now());
    for (final t in s.timers) {
      if (!t.paused &&
          !t.acknowledged &&
          t.remaining(now) == 0 &&
          surfaced.add('${t.id}:end')) {
        unawaited(SystemSound.play(SystemSoundType.alert));
        snack(context, '${t.label}计时结束，请检查食材和锅内状态。');
      }
      if (!t.paused && r.steps[t.step].watchPot && t.deadline != null) {
        final elapsed = t.totalSeconds - t.remaining(now);
        final bucket = elapsed ~/ 600;
        if (bucket > 0 &&
            t.remaining(now) > 0 &&
            surfaced.add('${t.id}:watch:$bucket')) {
          unawaited(SystemSound.play(SystemSoundType.alert));
          snack(context, '回灶边看一眼：检查水量和火力，避免干锅。');
        }
      }
    }
  }

  Future<void> complete() async {
    if (!await confirm(
      context,
      '做好了，最后检查一次',
      '请确认食物已充分熟透、炉火已关闭，锅具放置稳妥。完成后会停止本次所有计时和看锅提醒。',
      '已熟透、已关火',
    )) {
      return;
    }
    await s.finish();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 150, child: DishArt(r)),
            const Text(
              '这一餐，你做到了！',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text('${r.name}，开饭啦。\n又学会了一点厨房的道理。', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('收下这份成就'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: s,
    builder: (context, _) {
      final prep = s.step < 0;
      final index = s.step.clamp(0, r.steps.length - 1);
      final step = r.steps[index];
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name, style: const TextStyle(fontSize: 18)),
              Text(
                prep
                    ? '准备食材 · ${s.servings} 人份'
                    : '做菜模式 · 第 ${index + 1} / ${r.steps.length} 步',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '字号和屏幕设置',
              onPressed: () => settings(context, s),
              icon: const Icon(Icons.text_fields_rounded),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              key: ValueKey(s.step),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                LinearProgressIndicator(
                  value: prep ? 0 : (index + 1) / r.steps.length,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: sage,
                ),
                const SizedBox(height: 24),
                if (prep) ...[
                  const Tag('先准备好，再从容开火'),
                  const SizedBox(height: 16),
                  const Text(
                    '把食材备齐吧',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    '准备一种，勾掉一种。调味料和工具也别忘了。',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 18),
                  Panel(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Column(
                      children: r.ingredients
                          .map(
                            (i) => CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                i.name,
                                style: TextStyle(fontSize: s.fontSize - 4),
                              ),
                              subtitle: Text(
                                [
                                  i.quantity(s.servings, r.servings),
                                  if (i.note.isNotEmpty) i.note,
                                ].join('\n'),
                              ),
                              value: s.checked.contains(i.name),
                              onChanged: (_) => s.check(i.name),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: r.tools.map((t) => Tag(t)).toList(),
                  ),
                  const SizedBox(height: 20),
                  notice('食材和工具准备好后再开火。处理生肉前后洗手，避免生熟交叉污染。', danger: true),
                ] else ...[
                  Row(
                    children: [
                      Tag('STEP ${(index + 1).toString().padLeft(2, '0')}'),
                      const Spacer(),
                      Text(
                        '一次一步，慢慢来',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: s.fontSize + 4,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Panel(
                    color: Color(r.color),
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      height: 160,
                      child: FoodArt(step.art, animate: true),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    step.instruction,
                    style: TextStyle(
                      fontSize: s.fontSize,
                      height: 1.75,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Panel(
                    color: sage,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '看状态，比看时间更重要',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF627A4D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.cue,
                          style: TextStyle(
                            fontSize: s.fontSize - 6,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (step.minutes > 0) ...[
                    const SizedBox(height: 18),
                    timerControl(index, step),
                  ],
                  if (step.safety.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    notice(step.safety, danger: true, fontSize: s.fontSize - 6),
                  ],
                  const SectionTitle('为什么这样做？', '点开看看原理，还有另一种做法'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: step.knowledge.map((id) {
                      final k = knowledgeCards.firstWhere((k) => k.id == id);
                      return ActionChip(
                        avatar: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: orange,
                        ),
                        label: Text(k.title),
                        backgroundColor: Colors.white,
                        onPressed: () => showKnowledge(context, s, k),
                      );
                    }).toList(),
                  ),
                ],
                if (s.timers.isNotEmpty) ...[
                  const SectionTitle('正在进行的计时', '切换步骤不会停止计时'),
                  ...s.timers.toList().map(timerTile),
                ],
                const SizedBox(height: 22),
                TextButton.icon(
                  onPressed: () async {
                    if (await confirm(
                      context,
                      '结束本次做菜？',
                      '先关闭炉火。结束会清除备料、步骤和所有计时；返回首页则会保留进度。',
                      '已关火，结束',
                    )) {
                      await s.abandon();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text('结束本次做菜'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
            child: Row(
              children: [
                if (!prep) ...[
                  OutlinedButton(
                    onPressed: () => s.move(index - 1),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: prep
                        ? (s.checked.length >= r.ingredients.length
                              ? () => s.move(0)
                              : null)
                        : index == r.steps.length - 1
                        ? complete
                        : () => s.move(index + 1),
                    child: Text(
                      prep
                          ? '食材齐了，开始做（${s.checked.length}/${r.ingredients.length}）'
                          : index == r.steps.length - 1
                          ? '完成，确认关火'
                          : '下一步 →',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget timerControl(int index, CookStep step) {
    final exists = s.timers.any((t) => t.step == index && !t.acknowledged);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: exists
              ? null
              : () async {
                  await s.startTimer(r, index);
                  if (s.android && !s.notifications) {
                    await s.requestNotifications();
                  }
                  if (mounted) {
                    snack(
                      context,
                      step.watchPot ? '计时已开始，每 10 分钟提醒看锅。' : '计时已开始，结束后请检查状态。',
                    );
                  }
                },
          icon: const Icon(Icons.timer_outlined),
          label: Text(exists ? '本步骤计时正在下方运行' : '开始 ${step.minutes} 分钟计时'),
        ),
        const SizedBox(height: 8),
        Text(
          s.android
              ? (s.notifications
                    ? (s.exactAlarms
                          ? '后台通知已开启，仍需照看炉火。'
                          : '后台通知已开启，可能延迟；建议保持页面开启。')
                    : '通知未开启，保持页面开启以接收提醒。')
              : '浏览器体验：保持本页面开启；后台通知请使用安卓版。',
          style: const TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget timerTile(KitchenTimer t) {
    final left = t.remaining(now), ended = !t.paused && left == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        color: ended ? const Color(0xFFFFE1CD) : Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  ended
                      ? '请检查状态'
                      : '${(left ~/ 60).toString().padLeft(2, '0')}:${(left % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: ended ? 18 : 26,
                    fontWeight: FontWeight.w700,
                    color: orange,
                  ),
                ),
              ],
            ),
            if (t.paused)
              const Text(
                '计时暂停中 · 炉火不会自动停止',
                style: TextStyle(fontSize: 12, color: orange),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ended
                  ? [
                      TextButton(
                        onPressed: () => s.cancel(t),
                        child: const Text('已检查，结束计时'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await s.cancel(t);
                          await s.startTimer(r, t.step, seconds: 600);
                        },
                        child: const Text('再加 10 分钟'),
                      ),
                    ]
                  : [
                      TextButton.icon(
                        onPressed: () async {
                          if (t.paused) {
                            await s.resume(t, r);
                          } else {
                            await s.pause(t);
                            if (mounted) snack(context, '计时已暂停，炉火需手动关闭。');
                          }
                        },
                        icon: Icon(
                          t.paused ? Icons.play_arrow : Icons.pause,
                          size: 18,
                        ),
                        label: Text(t.paused ? '继续计时' : '暂停'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await confirm(
                            context,
                            '停止这个计时？',
                            '停止提醒不会停止炉火，请继续照看锅内状态。',
                            '停止计时',
                          )) {
                            await s.cancel(t);
                          }
                        },
                        child: const Text('停止'),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}
