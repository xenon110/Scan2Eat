import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FoodEntry {
  final String? id;
  final String name;
  final String imageUrl;
  final DateTime consumedAt;
  final int healthScore;

  // Macros
  final double calories;
  final double protein;
  final double carbs;
  final double sugar;
  final double fat;
  final double fiber;
  final double sodium;

  // Micros
  final double vitaminD;
  final double iron;
  final double calcium;

  const FoodEntry({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.consumedAt,
    required this.healthScore,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.sugar,
    required this.fat,
    required this.fiber,
    required this.sodium,
    this.vitaminD = 0,
    this.iron = 0,
    this.calcium = 0,
  });
}

class NutritionLog extends ChangeNotifier {
  NutritionLog._();
  static final NutritionLog instance = NutritionLog._();

  final List<FoodEntry> _entries = [];
  bool _isListening = false;

  List<FoodEntry> get all => List.unmodifiable(_entries);

  List<FoodEntry> get todayEntries => forDay(DateTime.now());
  NutrientTotals get todayTotals => totalsFor(todayEntries);

  void startListening() {
    if (_isListening) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _isListening = true;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journal')
        .snapshots()
        .listen((snapshot) {
      _entries.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _entries.add(FoodEntry(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          imageUrl: data['imageUrl'] ?? '',
          consumedAt: (data['consumedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          healthScore: data['healthScore'] ?? 0,
          calories: (data['calories'] ?? 0).toDouble(),
          protein: (data['protein'] ?? 0).toDouble(),
          carbs: (data['carbs'] ?? 0).toDouble(),
          sugar: (data['sugar'] ?? 0).toDouble(),
          fat: (data['fat'] ?? 0).toDouble(),
          fiber: (data['fiber'] ?? 0).toDouble(),
          sodium: (data['sodium'] ?? 0).toDouble(),
        ));
      }
      notifyListeners();
    });
  }

  Future<void> add(FoodEntry entry) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('journal').add({
        'name': entry.name,
        'imageUrl': entry.imageUrl,
        'consumedAt': Timestamp.fromDate(entry.consumedAt),
        'healthScore': entry.healthScore,
        'calories': entry.calories,
        'protein': entry.protein,
        'carbs': entry.carbs,
        'sugar': entry.sugar,
        'fat': entry.fat,
        'fiber': entry.fiber,
        'sodium': entry.sodium,
      });
    } else {
      _entries.add(entry);
      notifyListeners();
    }
  }

  Future<void> clearTodayLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journal')
        .where('consumedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('consumedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Local cache will auto-update via the snapshot listener
  }

  Future<void> clearAllLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('journal')
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
      if (count == 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }
    if (count > 0) {
      await batch.commit();
    }
  }

  Future<void> exportDataAsCSV() async {
    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Name', 'Calories (kcal)', 'Protein (g)', 'Carbs (g)', 'Fat (g)', 'Sodium (mg)', 'Fiber (g)', 'Sugar (g)', 'Health Score']);
    
    // Sort by date descending
    final sortedEntries = List<FoodEntry>.from(_entries)..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
    
    for (final entry in sortedEntries) {
      rows.add([
        entry.consumedAt.toIso8601String(),
        entry.name,
        entry.calories.round(),
        entry.protein.round(),
        entry.carbs.round(),
        entry.fat.round(),
        entry.sodium.round(),
        entry.fiber.round(),
        entry.sugar.round(),
        entry.healthScore,
      ]);
    }
    
    final csvData = Csv().encode(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/nutrition_log.csv';
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: 'Here is my exported Nutrition Log from Scan2Eat!');
  }

  List<FoodEntry> forDay(DateTime day) {
    return _entries.where((e) =>
      e.consumedAt.year == day.year &&
      e.consumedAt.month == day.month &&
      e.consumedAt.day == day.day,
    ).toList();
  }

  List<FoodEntry> forWeek(DateTime ref) {
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7));
    return _entries.where((e) =>
      e.consumedAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
      e.consumedAt.isBefore(end),
    ).toList();
  }

  List<FoodEntry> forMonth(DateTime ref) {
    return _entries.where((e) =>
      e.consumedAt.year == ref.year &&
      e.consumedAt.month == ref.month,
    ).toList();
  }

  // Aggregate helpers
  _Totals totalsFor(List<FoodEntry> entries) {
    if (entries.isEmpty) return _Totals.zero();
    return entries.fold(_Totals.zero(), (acc, e) => acc.add(e));
  }
}

class _Totals {
  final double calories;
  final double protein;
  final double carbs;
  final double sugar;
  final double fat;
  final double fiber;
  final double sodium;
  final double vitaminD;
  final double iron;
  final double calcium;

  const _Totals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.sugar,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.vitaminD,
    required this.iron,
    required this.calcium,
  });

  factory _Totals.zero() => const _Totals(
    calories: 0, protein: 0, carbs: 0, sugar: 0,
    fat: 0, fiber: 0, sodium: 0, vitaminD: 0, iron: 0, calcium: 0,
  );

  _Totals add(FoodEntry e) => _Totals(
    calories:  calories  + e.calories,
    protein:   protein   + e.protein,
    carbs:     carbs     + e.carbs,
    sugar:     sugar     + e.sugar,
    fat:       fat       + e.fat,
    fiber:     fiber     + e.fiber,
    sodium:    sodium    + e.sodium,
    vitaminD:  vitaminD  + e.vitaminD,
    iron:      iron      + e.iron,
    calcium:   calcium   + e.calcium,
  );
}

// Public alias used by the report screen
typedef NutrientTotals = _Totals;
