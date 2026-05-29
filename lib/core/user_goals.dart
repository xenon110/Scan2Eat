// Stores all user-defined nutrition & water goals

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class MealPeriodGoal {
  double water; // litres
  double protein; // g
  double carbs; // g
  double fat; // g
  double fiber; // g
  double sugar; // g
  double sodium; // mg
  double calories; // kcal

  MealPeriodGoal({
    this.water = 2,
    this.protein = 15,
    this.carbs = 80,
    this.fat = 20,
    this.fiber = 8,
    this.sugar = 15,
    this.sodium = 700,
    this.calories = 600,
  });

  MealPeriodGoal copyWith({
    double? water, double? protein, double? carbs,
    double? fat, double? fiber, double? sugar,
    double? sodium, double? calories,
  }) => MealPeriodGoal(
    water: water ?? this.water,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
    fiber: fiber ?? this.fiber,
    sugar: sugar ?? this.sugar,
    sodium: sodium ?? this.sodium,
    calories: calories ?? this.calories,
  );

  // Totals for combining morning+afternoon+evening
  static MealPeriodGoal combine(List<MealPeriodGoal> goals) {
    return MealPeriodGoal(
      water: goals.fold(0, (s, g) => s + g.water),
      protein: goals.fold(0, (s, g) => s + g.protein),
      carbs: goals.fold(0, (s, g) => s + g.carbs),
      fat: goals.fold(0, (s, g) => s + g.fat),
      fiber: goals.fold(0, (s, g) => s + g.fiber),
      sugar: goals.fold(0, (s, g) => s + g.sugar),
      sodium: goals.fold(0, (s, g) => s + g.sodium),
      calories: goals.fold(0, (s, g) => s + g.calories),
    );
  }
}

class DailyGoal {
  MealPeriodGoal morning;
  MealPeriodGoal afternoon;
  MealPeriodGoal evening;

  DailyGoal({
    MealPeriodGoal? morning,
    MealPeriodGoal? afternoon,
    MealPeriodGoal? evening,
  })  : morning = morning ?? MealPeriodGoal(water: 2, protein: 15, carbs: 60, fat: 15, fiber: 5, sugar: 10, sodium: 500, calories: 400),
        afternoon = afternoon ?? MealPeriodGoal(water: 3, protein: 20, carbs: 100, fat: 25, fiber: 10, sugar: 15, sodium: 800, calories: 700),
        evening = evening ?? MealPeriodGoal(water: 3, protein: 15, carbs: 80, fat: 20, fiber: 8, sugar: 10, sodium: 600, calories: 500);

  MealPeriodGoal get total => MealPeriodGoal.combine([morning, afternoon, evening]);
}


class UserGoals extends ChangeNotifier {
  UserGoals._();
  static final UserGoals instance = UserGoals._();

  bool _isListening = false;
  DailyGoal daily = DailyGoal();

  // Weekly/monthly multiplied from daily
  MealPeriodGoal get weekly => _multiply(daily.total, 7);
  MealPeriodGoal get monthly => _multiply(daily.total, 30);

  void startListening() {
    if (_isListening) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _isListening = true;

    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        // Initialize default baseline goals for a new user
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'calorieGoal': 2000,
          'proteinGoal': 50,
          'carbGoal': 250,
          'fatGoal': 65,
          'sugarGoal': 50,
          'sodiumGoal': 2300,
          'fiberGoal': 28,
          'waterGoal': 2.0,
        }, SetOptions(merge: true));
        return;
      }
      final data = snapshot.data()!;
      // Overriding the morning/afternoon/evening defaults to just a flat total using morning for now,
      // since the current schema only saves global daily goals.
      daily = DailyGoal(
        morning: MealPeriodGoal(
          calories: (data['calorieGoal'] ?? 2000).toDouble(),
          protein: (data['proteinGoal'] ?? 150).toDouble(),
          carbs: (data['carbGoal'] ?? 250).toDouble(),
          fat: (data['fatGoal'] ?? 65).toDouble(),
          sugar: (data['sugarGoal'] ?? 50).toDouble(),
          sodium: (data['sodiumGoal'] ?? 2300).toDouble(),
          fiber: (data['fiberGoal'] ?? 28).toDouble(),
          water: (data['waterGoal'] ?? 2.0).toDouble(),
        ),
        afternoon: MealPeriodGoal(calories: 0, protein: 0, carbs: 0, fat: 0, water: 0, sugar: 0, sodium: 0, fiber: 0),
        evening: MealPeriodGoal(calories: 0, protein: 0, carbs: 0, fat: 0, water: 0, sugar: 0, sodium: 0, fiber: 0),
      );
      notifyListeners();
    });
  }

  MealPeriodGoal _multiply(MealPeriodGoal g, double factor) => MealPeriodGoal(
    water: g.water * factor,
    protein: g.protein * factor,
    carbs: g.carbs * factor,
    fat: g.fat * factor,
    fiber: g.fiber * factor,
    sugar: g.sugar * factor,
    sodium: g.sodium * factor,
    calories: g.calories * factor,
  );
}
