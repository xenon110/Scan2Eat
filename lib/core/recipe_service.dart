import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service that fetches real recipes from TheMealDB — a completely free API.
/// No API key is required. Docs: https://www.themealdb.com/api.php
class RecipeService {
  static final RecipeService instance = RecipeService._();
  RecipeService._();

  static const _base = 'https://www.themealdb.com/api/json/v1/1';

  /// Fetches multiple random meals (TheMealDB only returns 1 per call,
  /// so we make parallel requests).
  Future<List<MealRecipe>> fetchRandomRecipes({int count = 6}) async {
    try {
      final futures = List.generate(count, (_) => http.get(Uri.parse('$_base/random.php')));
      final responses = await Future.wait(futures);

      final List<MealRecipe> meals = [];
      for (final res in responses) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = data['meals'] as List?;
          if (list != null && list.isNotEmpty) {
            final meal = MealRecipe.fromJson(list[0] as Map<String, dynamic>);
            // Avoid duplicates
            if (!meals.any((m) => m.id == meal.id)) {
              meals.add(meal);
            }
          }
        }
      }
      return meals;
    } catch (e) {
      debugPrint('Error fetching random recipes: $e');
      return [];
    }
  }

  /// Searches meals by name.
  Future<List<MealRecipe>> searchRecipes(String query) async {
    try {
      final res = await http.get(Uri.parse('$_base/search.php?s=$query'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['meals'] as List?;
        if (list != null) {
          return list.map((e) => MealRecipe.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error searching recipes: $e');
    }
    return [];
  }

  /// Gets full meal details by ID.
  Future<MealRecipe?> getMealById(String id) async {
    try {
      final res = await http.get(Uri.parse('$_base/lookup.php?i=$id'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['meals'] as List?;
        if (list != null && list.isNotEmpty) {
          return MealRecipe.fromJson(list[0] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error fetching meal by ID: $e');
    }
    return null;
  }

  /// Fetches all categories.
  Future<List<MealCategory>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('$_base/categories.php'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['categories'] as List?;
        if (list != null) {
          return list.map((e) => MealCategory.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
    return [];
  }

  /// Fetches meals by category.
  Future<List<MealRecipe>> fetchByCategory(String category) async {
    try {
      final res = await http.get(Uri.parse('$_base/filter.php?c=$category'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['meals'] as List?;
        if (list != null) {
          // filter endpoint returns minimal data, so fetch full details for first 6
          final limitedList = list.take(6).toList();
          final futures = limitedList.map((e) => getMealById(e['idMeal'].toString()));
          final results = await Future.wait(futures);
          return results.whereType<MealRecipe>().toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching by category: $e');
    }
    return [];
  }
}

class MealRecipe {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String imageUrl;
  final String? youtubeUrl;
  final List<RecipeIngredient> ingredients;
  final List<String> tags;

  MealRecipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.imageUrl,
    this.youtubeUrl,
    required this.ingredients,
    required this.tags,
  });

  factory MealRecipe.fromJson(Map<String, dynamic> json) {
    // Parse ingredients (TheMealDB uses strIngredient1..20 and strMeasure1..20)
    final List<RecipeIngredient> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i']?.toString().trim() ?? '';
      final measure = json['strMeasure$i']?.toString().trim() ?? '';
      if (ingredient.isNotEmpty) {
        ingredients.add(RecipeIngredient(
          name: ingredient,
          measure: measure,
          thumbUrl: 'https://www.themealdb.com/images/ingredients/$ingredient-Small.png',
        ));
      }
    }

    // Parse tags
    final tagsStr = json['strTags']?.toString() ?? '';
    final tags = tagsStr.isNotEmpty
        ? tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    return MealRecipe(
      id: json['idMeal']?.toString() ?? '',
      name: json['strMeal']?.toString() ?? 'Unknown',
      category: json['strCategory']?.toString() ?? '',
      area: json['strArea']?.toString() ?? '',
      instructions: json['strInstructions']?.toString() ?? '',
      imageUrl: json['strMealThumb']?.toString() ?? '',
      youtubeUrl: json['strYoutube']?.toString(),
      ingredients: ingredients,
      tags: tags,
    );
  }
}

class RecipeIngredient {
  final String name;
  final String measure;
  final String thumbUrl;

  RecipeIngredient({
    required this.name,
    required this.measure,
    required this.thumbUrl,
  });
}

class MealCategory {
  final String id;
  final String name;
  final String thumbUrl;
  final String description;

  MealCategory({
    required this.id,
    required this.name,
    required this.thumbUrl,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: json['idCategory']?.toString() ?? '',
      name: json['strCategory']?.toString() ?? '',
      thumbUrl: json['strCategoryThumb']?.toString() ?? '',
      description: json['strCategoryDescription']?.toString() ?? '',
    );
  }
}
