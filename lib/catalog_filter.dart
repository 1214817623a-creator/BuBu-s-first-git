import 'models.dart';

const recipeFilterGroups = {
  '菜系': ['家常菜', '川菜', '湘菜', '粤菜', '鲁菜', '江浙菜', '东北菜'],
  '做法': ['炒', '炖', '蒸', '煎', '炸', '煮', '拌', '烤'],
  '食材': ['牛肉', '猪肉', '鸡肉', '鸭肉', '鱼', '虾', '鸡蛋', '蔬菜', '豆制品', '菌菇', '主食'],
  '场景': ['快手菜', '下饭菜', '汤羹', '一人食', '早餐'],
  '难度': ['第一次做饭', '简单', '进阶'],
};

List<Recipe> filterRecipes(
  Iterable<Recipe> recipes,
  Set<String> tags,
  String query,
) {
  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'[\s,，、]+'))
      .where((s) => s.isNotEmpty)
      .toList();
  return recipes.where((r) {
    final text =
        '${r.name} ${r.tags.join(' ')} ${r.ingredients.map((i) => i.name).join(' ')}'
            .toLowerCase();
    return tags.every(r.tags.contains) && words.every(text.contains);
  }).toList();
}
