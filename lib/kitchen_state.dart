import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class KitchenState extends ChangeNotifier {
  static const channel = MethodChannel('com.bubu.kitchen/assistant');
  final SharedPreferences prefs;
  KitchenState(this.prefs) {
    _restore();
  }
  Set<String> favorites = {}, savedKnowledge = {}, checked = {};
  String? currentRecipe;
  int step = -1, servings = 2, completed = 0;
  double fontSize = 26;
  bool keepAwake = true;
  bool cookingVisible = false;
  int _nextTimerId = (DateTime.now().millisecondsSinceEpoch % 900000000) * 2;
  bool notifications = false, exactAlarms = false;
  String? persistenceError;
  final List<KitchenTimer> timers = [];
  Future<void> _saveQueue = Future.value();
  bool get android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  void _restore() {
    try {
      final j =
          jsonDecode(prefs.getString('kitchen.v1') ?? '{}')
              as Map<String, dynamic>;
      favorites = Set<String>.from(j['favorites'] ?? []);
      savedKnowledge = Set<String>.from(j['knowledge'] ?? []);
      checked = Set<String>.from(j['checked'] ?? []);
      currentRecipe = j['recipe'];
      step = j['step'] ?? -1;
      servings = (j['servings'] as int? ?? 2).clamp(1, 8);
      fontSize = (j['font'] as num? ?? 26).toDouble().clamp(22, 34);
      completed = j['completed'] ?? 0;
      keepAwake = j['awake'] ?? true;
      for (final item in j['timers'] ?? []) {
        timers.add(KitchenTimer.fromJson(Map<String, dynamic>.from(item)));
      }
    } catch (_) {
      persistenceError = '上次记录未能读取。你可以重新开始，收藏不会上传到网络。';
    }
  }

  Future<void> save() {
    final payload = jsonEncode({
      'favorites': favorites.toList(),
      'knowledge': savedKnowledge.toList(),
      'checked': checked.toList(),
      'recipe': currentRecipe,
      'step': step,
      'servings': servings,
      'font': fontSize,
      'completed': completed,
      'awake': keepAwake,
      'timers': timers.map((t) => t.toJson()).toList(),
    });
    _saveQueue = _saveQueue.then((_) async {
      try {
        if (!await prefs.setString('kitchen.v1', payload)) {
          throw StateError('save failed');
        }
      } catch (_) {
        persistenceError = '本地保存失败，请保持应用开启并稍后重试。';
        notifyListeners();
      }
    });
    notifyListeners();
    return _saveQueue;
  }

  Future<T?> native<T>(String method, [Map<String, dynamic>? args]) async {
    if (!android) return null;
    try {
      return await channel.invokeMethod<T>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> refreshPermissions() async {
    final p = await native<Map>('status');
    notifications = p?['notifications'] == true;
    exactAlarms = p?['exact'] == true;
    notifyListeners();
  }

  Future<void> requestNotifications() async {
    await native('requestNotifications');
    await refreshPermissions();
  }

  Future<void> awake(bool value) async {
    cookingVisible = value;
    await native('keepAwake', {'enabled': value && keepAwake});
  }

  void favorite(String id, {bool knowledge = false}) {
    final items = knowledge ? savedKnowledge : favorites;
    if (!items.add(id)) items.remove(id);
    unawaited(save());
  }

  void prepare(Recipe r, int count) {
    currentRecipe = r.id;
    servings = count;
    checked.clear();
    step = -1;
    unawaited(save());
  }

  void check(String name) {
    if (!checked.add(name)) checked.remove(name);
    unawaited(save());
  }

  void move(int index) {
    step = index;
    unawaited(save());
  }

  void setFont(double value) {
    fontSize = value;
    unawaited(save());
  }

  Future<void> startTimer(Recipe r, int index, {int? seconds}) async {
    final existing = timers.where(
      (t) => t.recipeId == r.id && t.step == index && !t.acknowledged,
    );
    if (existing.isNotEmpty) return;
    final s = r.steps[index];
    final duration = seconds ?? s.minutes * 60;
    while (timers.any(
      (t) => t.id == _nextTimerId || t.id == _nextTimerId + 1,
    )) {
      _nextTimerId += 2;
    }
    final t = KitchenTimer(
      id: _nextTimerId,
      recipeId: r.id,
      step: index,
      label: s.title,
      totalSeconds: duration,
      deadline: DateTime.now().add(Duration(seconds: duration)),
    );
    _nextTimerId += 2;
    timers.add(t);
    await save();
    await _schedule(t, r);
  }

  Future<void> _schedule(KitchenTimer t, Recipe r) async {
    await native('schedule', {
      'id': t.id,
      'at': t.deadline!.millisecondsSinceEpoch,
      'title': '${r.name} · 计时结束',
      'body': '${t.label}：请检查状态，时间不能代替熟度判断。',
    });
    if (r.steps[t.step].watchPot && t.remaining(DateTime.now()) > 600) {
      await native('schedule', {
        'id': t.id + 1,
        'at': DateTime.now()
            .add(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
        'until': t.deadline!.millisecondsSinceEpoch,
        'interval': 600000,
        'title': '记得回灶边看锅',
        'body': '检查水量、火力和锅底，汤少时适量补热水。',
      });
    }
  }

  Future<void> restoreAlarms(List<Recipe> recipes) async {
    if (!android) return;
    for (final t in timers) {
      final matches = recipes.where((r) => r.id == t.recipeId);
      if (matches.isEmpty || t.paused || t.remaining(DateTime.now()) == 0) {
        continue;
      }
      final r = matches.first;
      if (t.step >= 0 && t.step < r.steps.length) await _schedule(t, r);
    }
  }

  Future<void> pause(KitchenTimer t) async {
    t.remainingWhenPaused = t.remaining(DateTime.now());
    t.deadline = null;
    await native('cancel', {'id': t.id});
    await native('cancel', {'id': t.id + 1});
    await save();
  }

  Future<void> resume(KitchenTimer t, Recipe r) async {
    t.deadline = DateTime.now().add(Duration(seconds: t.remainingWhenPaused));
    await save();
    await _schedule(t, r);
  }

  Future<void> cancel(KitchenTimer t) async {
    await native('cancel', {'id': t.id});
    await native('cancel', {'id': t.id + 1});
    timers.remove(t);
    await save();
  }

  Future<void> finish() async {
    for (final t in timers.toList()) {
      await cancel(t);
    }
    currentRecipe = null;
    step = -1;
    checked.clear();
    completed++;
    await awake(false);
    await save();
  }

  Future<void> abandon() async {
    for (final t in timers.toList()) {
      await cancel(t);
    }
    currentRecipe = null;
    step = -1;
    checked.clear();
    await awake(false);
    await save();
  }
}
