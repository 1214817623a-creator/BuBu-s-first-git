class Ingredient {
  final String name, unit, note;
  final double amount;
  const Ingredient(this.name, this.amount, this.unit, {this.note = ''});
  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    json['name'] as String,
    (json['amount'] as num).toDouble(),
    json['unit'] as String,
    note: json['note'] as String? ?? '',
  );
  String quantity(int servings, int base) {
    final n = amount * servings / base;
    return '${n == n.roundToDouble() ? n.toInt() : n.toStringAsFixed(1)}$unit';
  }
}

class CookStep {
  final String title, instruction, cue, safety, art;
  final int minutes;
  final bool watchPot;
  final List<String> knowledge;
  const CookStep(
    this.title,
    this.instruction,
    this.cue,
    this.art, {
    this.minutes = 0,
    this.safety = '',
    this.watchPot = false,
    this.knowledge = const [],
  });
  factory CookStep.fromJson(Map<String, dynamic> json) => CookStep(
    json['title'] as String,
    json['instruction'] as String,
    json['cue'] as String,
    json['art'] as String? ?? 'cut',
    minutes: json['minutes'] as int? ?? 0,
    safety: json['safety'] as String? ?? '',
    watchPot: json['watchPot'] as bool? ?? false,
    knowledge: List<String>.from(json['knowledge'] as List? ?? []),
  );
}

class Recipe {
  final String id, name, subtitle, description, art;
  final int activeMinutes, waitMinutes, servings, color;
  final List<String> tags, tools;
  final List<int> months;
  final List<Ingredient> ingredients;
  final List<CookStep> steps;
  final String sourceName, sourceUrl;
  final String dishStyle;
  const Recipe({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.art,
    required this.color,
    required this.activeMinutes,
    required this.waitMinutes,
    this.servings = 2,
    required this.tags,
    required this.months,
    required this.tools,
    required this.ingredients,
    required this.steps,
    this.sourceName = '',
    this.sourceUrl = '',
    this.dishStyle = 'plate',
  });
  int get totalMinutes => activeMinutes + waitMinutes;
  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    subtitle: json['subtitle'] as String,
    description: json['description'] as String,
    art: json['art'] as String,
    color: json['color'] as int,
    activeMinutes: json['activeMinutes'] as int,
    waitMinutes: json['waitMinutes'] as int,
    servings: json['servings'] as int? ?? 2,
    tags: List<String>.from(json['tags'] as List),
    months: List<int>.from(json['months'] as List),
    tools: List<String>.from(json['tools'] as List),
    ingredients: (json['ingredients'] as List)
        .map((i) => Ingredient.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList(),
    steps: (json['steps'] as List)
        .map((s) => CookStep.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList(),
    sourceName: json['sourceName'] as String,
    sourceUrl: json['sourceUrl'] as String,
    dishStyle: json['dishStyle'] as String,
  );
}

class Knowledge {
  final String id,
      title,
      category,
      summary,
      explanation,
      alternative,
      sourceName,
      sourceUrl;
  final String actionTitle;
  const Knowledge(
    this.id,
    this.title,
    this.category,
    this.summary,
    this.explanation,
    this.alternative, {
    this.sourceName = '布布厨房 · 家常烹饪实践',
    this.sourceUrl = '',
    this.actionTitle = '换一种做法，会怎样？',
  });
  factory Knowledge.fromJson(Map<String, dynamic> json) => Knowledge(
    json['id'] as String,
    json['title'] as String,
    json['category'] as String,
    json['summary'] as String,
    json['explanation'] as String,
    json['alternative'] as String,
    sourceName: json['sourceName'] as String,
    sourceUrl: json['sourceUrl'] as String,
    actionTitle: json['actionTitle'] as String? ?? '操作要点',
  );
}

class KitchenTimer {
  final int id, step, totalSeconds;
  final String recipeId, label;
  DateTime? deadline;
  int remainingWhenPaused;
  bool acknowledged;
  KitchenTimer({
    required this.id,
    required this.recipeId,
    required this.step,
    required this.label,
    required this.totalSeconds,
    this.deadline,
    this.remainingWhenPaused = 0,
    this.acknowledged = false,
  });
  int remaining(DateTime now) => deadline == null
      ? remainingWhenPaused
      : ((deadline!.millisecondsSinceEpoch - now.millisecondsSinceEpoch) / 1000)
            .ceil()
            .clamp(0, totalSeconds);
  bool get paused => deadline == null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'recipe': recipeId,
    'step': step,
    'label': label,
    'total': totalSeconds,
    'deadline': deadline?.millisecondsSinceEpoch,
    'remaining': remainingWhenPaused,
    'ack': acknowledged,
  };
  factory KitchenTimer.fromJson(Map<String, dynamic> j) => KitchenTimer(
    id: j['id'],
    recipeId: j['recipe'],
    step: j['step'],
    label: j['label'],
    totalSeconds: j['total'],
    remainingWhenPaused: j['remaining'] ?? 0,
    deadline: j['deadline'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['deadline']),
    acknowledged: j['ack'] ?? false,
  );
}
