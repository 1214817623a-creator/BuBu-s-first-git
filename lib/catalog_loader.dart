import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

/// Load bundled, offline content once. Publish only after both files validate.
Future<({List<Recipe> recipes, List<Knowledge> knowledge})>
readCatalog() async {
  final raw = await Future.wait([
    rootBundle.loadString('assets/content/recipes_v1_1.json'),
    rootBundle.loadString('assets/content/knowledge_v1_1.json'),
  ]);
  final recipes = (jsonDecode(raw[0]) as List)
      .map((j) => Recipe.fromJson(Map<String, dynamic>.from(j as Map)))
      .toList();
  final knowledge = (jsonDecode(raw[1]) as List)
      .map((j) => Knowledge.fromJson(Map<String, dynamic>.from(j as Map)))
      .toList();
  if (recipes.length != 100 || knowledge.length != 300) {
    throw const FormatException('V1.1.0 content count mismatch');
  }
  if (recipes.map((r) => r.id).toSet().length != recipes.length ||
      knowledge.map((k) => k.id).toSet().length != knowledge.length) {
    throw const FormatException('Duplicate content ID');
  }
  return (recipes: recipes, knowledge: knowledge);
}
