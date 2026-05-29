import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'multiplayer_service.dart';
import 'package:intl/intl.dart';

class UserStats extends ChangeNotifier {
  UserStats._();
  static final UserStats instance = UserStats._();

  bool _isListening = false;
  
  int streak = 0;
  double waterLitres = 0.0;
  
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void startListening() {
    if (_isListening) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _isListening = true;

    // Listen to main user doc for streaks
    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        streak = data['streak'] ?? 0;
        
        // Handle streak logic: update if it's a new day
        _checkAndRecordStreak(uid, data);
        notifyListeners();
      } else {
        // Initialize user doc if it doesn't exist
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'streak': 1,
          'lastLogDate': _todayKey,
        }, SetOptions(merge: true));
      }
    });

    // Listen to today's daily_stats for water
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(_todayKey)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        waterLitres = (snapshot.data()!['waterLitres'] ?? 0).toDouble();
      } else {
        waterLitres = 0.0;
      }
      notifyListeners();
    });
  }

  Future<void> _checkAndRecordStreak(String uid, Map<String, dynamic> data) async {
    final lastLogDate = data['lastLogDate'] as String?;
    final today = _todayKey;
    final yesterdayDate = DateTime.now().subtract(const Duration(days: 1));
    final yesterday = DateFormat('yyyy-MM-dd').format(yesterdayDate);

    if (lastLogDate == yesterday) {
      // Need to verify if they met at least 3 goals yesterday.
      final startOfYesterday = Timestamp.fromDate(DateTime(yesterdayDate.year, yesterdayDate.month, yesterdayDate.day));
      final startOfToday = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
      
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('nutrition_logs')
          .where('consumedAt', isGreaterThanOrEqualTo: startOfYesterday)
          .where('consumedAt', isLessThan: startOfToday)
          .get();
      
      double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0, sodium = 0;
      for (var doc in logsSnapshot.docs) {
        final d = doc.data();
        calories += (d['calories'] ?? 0).toDouble();
        protein += (d['protein'] ?? 0).toDouble();
        carbs += (d['carbs'] ?? 0).toDouble();
        fat += (d['fat'] ?? 0).toDouble();
        fiber += (d['fiber'] ?? 0).toDouble();
        sugar += (d['sugar'] ?? 0).toDouble();
        sodium += (d['sodium'] ?? 0).toDouble();
      }

      final waterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_stats')
          .doc(yesterday)
          .get();
      double water = 0;
      if (waterDoc.exists) {
        water = (waterDoc.data()!['waterLitres'] ?? 0).toDouble();
      }

      final gCal = (data['calorieGoal'] ?? 2000).toDouble();
      final gPro = (data['proteinGoal'] ?? 150).toDouble();
      final gCar = (data['carbGoal'] ?? 250).toDouble();
      final gFat = (data['fatGoal'] ?? 65).toDouble();
      final gSug = (data['sugarGoal'] ?? 50).toDouble();
      final gSod = (data['sodiumGoal'] ?? 2300).toDouble();
      final gFib = (data['fiberGoal'] ?? 28).toDouble();
      final gWat = (data['waterGoal'] ?? 2.0).toDouble();

      int goalsMet = 0;
      if (gCal > 0 && calories >= gCal) goalsMet++;
      if (gPro > 0 && protein >= gPro) goalsMet++;
      if (gCar > 0 && carbs >= gCar) goalsMet++;
      if (gFat > 0 && fat >= gFat) goalsMet++;
      if (gSug > 0 && sugar >= gSug) goalsMet++; 
      if (gSod > 0 && sodium >= gSod) goalsMet++;
      if (gFib > 0 && fiber >= gFib) goalsMet++;
      if (gWat > 0 && water >= gWat) goalsMet++;

      if (goalsMet >= 3) {
        // Met 3 goals, increment streak
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'streak': FieldValue.increment(1),
          'lastLogDate': today,
        });
      } else {
        // Missed goals, reset to 1
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'streak': 1,
          'lastLogDate': today,
        });
      }
    } else if (lastLogDate != today) {
      // Missed a day entirely (or first time), reset streak to 1
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'streak': 1,
        'lastLogDate': today,
      });
    }
  }

  Future<void> setWater(double litres) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Determine points (5 points for every 0.25L added)
    final diff = litres - waterLitres;
    if (diff > 0) {
      final points = (diff / 0.25).round() * 5;
      if (points > 0) MultiplayerService.instance.updateScore(points);
    }

    // Local optimistic update
    waterLitres = litres;
    notifyListeners();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_stats')
        .doc(_todayKey)
        .set({'waterLitres': litres}, SetOptions(merge: true));
  }
}
