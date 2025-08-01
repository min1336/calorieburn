// lib/services/firestore_service.dart

import 'package:calorie_burn/calorie_activity.dart';
import 'package:calorie_burn/favorite_food.dart';
import 'package:calorie_burn/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile ---
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserProfile.fromMap(uid, doc.data()!) : null;
  }

  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _db.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUserProfileField(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // --- Daily Data ---
  Future<Map<String, double>> getDailyData(String uid, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final doc = await _db.collection('users').doc(uid).collection('dailyData').doc(dateString).get();

    if (doc.exists) {
      final data = doc.data()!;
      return {
        'currentCalories': (data['currentCalories'] as num?)?.toDouble() ?? 0,
        'todayOverconsumedCaloriesBurned': (data['todayOverconsumedCaloriesBurned'] as num?)?.toDouble() ?? 0,
        'syncedCaloriesToday': (data['syncedCaloriesToday'] as num?)?.toDouble() ?? 0,
      };
    }
    return {};
  }

  Future<void> saveDailyData(String uid, DateTime date, Map<String, dynamic> data) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final userDocRef = _db.collection('users').doc(uid);
    final dailyDocRef = userDocRef.collection('dailyData').doc(dateString);

    WriteBatch batch = _db.batch();
    batch.set(dailyDocRef, data, SetOptions(merge: true));

    if (data.containsKey('todayOverconsumedCaloriesBurned')) {
      batch.set(userDocRef, {
        'todayOverconsumedCaloriesBurned': data['todayOverconsumedCaloriesBurned']
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ✅ 추가: 지난 7일간의 칼로리 기록을 가져오는 함수
  Future<List<Map<String, dynamic>>> getCalorieHistory(String uid) async {
    List<Map<String, dynamic>> history = [];
    final today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _db.collection('users').doc(uid).collection('dailyData').doc(dateString).get();

      if (doc.exists) {
        history.add({
          'date': date,
          'calories': (doc.data()!['currentCalories'] as num?)?.toDouble() ?? 0,
        });
      } else {
        history.add({
          'date': date,
          'calories': 0.0,
        });
      }
    }
    return history;
  }


  // --- Activities ---
  Future<List<CalorieActivity>> getActivities(String uid, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .doc(dateString)
        .collection('records')
        .orderBy('timestamp')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CalorieActivity(
        name: data['name'],
        amount: (data['amount'] as num).toDouble(),
        type: ActivityType.values[data['type']],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<void> saveActivities(String uid, DateTime date, List<CalorieActivity> activities) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final activitiesCollection = _db
        .collection('users')
        .doc(uid)
        .collection('activities')
        .doc(dateString)
        .collection('records');

    WriteBatch batch = _db.batch();
    for (var activity in activities) {
      var docRef = activitiesCollection.doc(activity.timestamp.toIso8601String());
      batch.set(docRef, {
        'name': activity.name,
        'amount': activity.amount,
        'type': activity.type.index,
        'timestamp': activity.timestamp,
      });
    }
    await batch.commit();
  }


  // --- Favorites ---
  Future<List<FavoriteFood>> getFavoriteFoods(String uid) async {
    final doc = await _db.collection('users').doc(uid).collection('user_data').doc('favorites').get();
    if (doc.exists && doc.data()!['foods'] != null) {
      return (doc.data()!['foods'] as List).map((item) => FavoriteFood.fromMap(item)).toList();
    }
    return [];
  }

  Future<void> saveFavoriteFoods(String uid, List<FavoriteFood> foods) async {
    final docRef = _db.collection('users').doc(uid).collection('user_data').doc('favorites');
    await docRef.set({'foods': foods.map((food) => food.toJson()).toList()});
  }


  // --- Rankings ---
  Future<List<Map<String, dynamic>>> fetchRankings() async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .orderBy('todayOverconsumedCaloriesBurned', descending: true)
          .limit(50)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("랭킹을 불러오는 중 오류 발생: $e");
      }
      return [];
    }
  }
}