class Ingredient {
  final String name, unit;
  final double amount;
  const Ingredient(this.name, this.amount, this.unit);
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
}

class Recipe {
  final String id, name, subtitle, description, art;
  final int activeMinutes, waitMinutes, servings, color;
  final List<String> tags, tools;
  final List<int> months;
  final List<Ingredient> ingredients;
  final List<CookStep> steps;
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
  });
  int get totalMinutes => activeMinutes + waitMinutes;
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
  const Knowledge(
    this.id,
    this.title,
    this.category,
    this.summary,
    this.explanation,
    this.alternative, {
    this.sourceName = '布布厨房 · 家常烹饪实践',
    this.sourceUrl = '',
  });
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
