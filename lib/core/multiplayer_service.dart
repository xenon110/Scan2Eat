import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MultiplayerService {
  MultiplayerService._();
  static final MultiplayerService instance = MultiplayerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? currentRoomCode;
  String? currentDisplayName;

  // Initialize and ensure user is signed in anonymously
  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
    }
  }

  // Create a new room and return the 6-digit code
  Future<String?> createRoom(String displayName) async {
    await signInAnonymously();
    if (currentUserId == null) return null;

    try {
      // Generate a random 6 character code
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      final code = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

      // Create the room
      await _firestore.collection('challenges').doc(code).set({
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      });

      // Add the creator as the first participant
      await _firestore
          .collection('challenges')
          .doc(code)
          .collection('participants')
          .doc(currentUserId)
          .set({
        'uid': currentUserId,
        'displayName': displayName,
        'score': 0,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      currentRoomCode = code;
      currentDisplayName = displayName;
      return code;
    } catch (e) {
      debugPrint("Error creating room: $e");
      return null;
    }
  }

  // Join an existing room
  Future<bool> joinRoom(String code, String displayName) async {
    await signInAnonymously();
    if (currentUserId == null) return false;

    try {
      final codeUpper = code.toUpperCase();
      final doc = await _firestore.collection('challenges').doc(codeUpper).get();
      if (!doc.exists) {
        return false; // Room doesn't exist
      }

      final participantRef = _firestore
          .collection('challenges')
          .doc(codeUpper)
          .collection('participants')
          .doc(currentUserId);
          
      final pDoc = await participantRef.get();
      if (!pDoc.exists) {
        await participantRef.set({
          'uid': currentUserId,
          'displayName': displayName,
          'score': 0,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await participantRef.update({'displayName': displayName});
      }

      currentRoomCode = codeUpper;
      currentDisplayName = displayName;
      return true;
    } catch (e) {
      debugPrint("Error joining room: $e");
      return false;
    }
  }

  // Stream leaderboard data for the room
  Stream<List<Map<String, dynamic>>> getLeaderboardStream(String code) {
    return _firestore
        .collection('challenges')
        .doc(code)
        .collection('participants')
        .orderBy('score', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Leave current room
  Future<void> leaveRoom() async {
    if (currentUserId == null || currentRoomCode == null) return;

    try {
      // Remove user from the participants subcollection
      await _firestore
          .collection('challenges')
          .doc(currentRoomCode)
          .collection('participants')
          .doc(currentUserId)
          .delete();
      
      currentRoomCode = null;
      currentDisplayName = null;
    } catch (e) {
      debugPrint("Error leaving room: $e");
    }
  }

  // Update score (e.g. +1 for water)
  Future<void> updateScore(int additionalScore) async {
    if (currentUserId == null || currentRoomCode == null) return;

    try {
      final participantRef = _firestore
          .collection('challenges')
          .doc(currentRoomCode)
          .collection('participants')
          .doc(currentUserId);

      await participantRef.update({
        'score': FieldValue.increment(additionalScore),
      });
    } catch (e) {
      debugPrint("Error updating score: $e");
    }
  }
}
