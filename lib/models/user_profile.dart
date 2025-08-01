// lib/models/user_profile.dart

import 'package:calorie_burn/models/enums.dart'; // ✅ 수정: enums 임포트

class UserProfile {
  final String uid;
  final String nickname;
  final String email;
  final int userAge;
  final double userHeightCm;
  final double userWeightKg;
  final Gender gender;
  final ActivityLevel activityLevel;
  String? primaryDataSource;

  UserProfile({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.userAge,
    required this.userHeightCm,
    required this.userWeightKg,
    required this.gender,
    required this.activityLevel,
    this.primaryDataSource,
  });

  factory UserProfile.initial() {
    return UserProfile(
      uid: '',
      nickname: '사용자',
      email: '',
      userAge: 30,
      userHeightCm: 175.0,
      userWeightKg: 75.0,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderate,
      primaryDataSource: null,
    );
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      nickname: data['nickname'] ?? '',
      email: data['email'] ?? '',
      userAge: data['userAge'] ?? 30,
      userHeightCm: (data['userHeightCm'] as num?)?.toDouble() ?? 175.0,
      userWeightKg: (data['userWeightKg'] as num?)?.toDouble() ?? 75.0,
      gender: Gender.values[data['gender'] ?? Gender.male.index],
      activityLevel: ActivityLevel.values[data['activityLevel'] ?? ActivityLevel.moderate.index],
      primaryDataSource: data['primaryDataSource'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'email': email,
      'userAge': userAge,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'gender': gender.index,
      'activityLevel': activityLevel.index,
      'primaryDataSource': primaryDataSource,
    };
  }

  UserProfile copyWith({
    String? nickname,
    int? userAge,
    double? userHeightCm,
    double? userWeightKg,
    Gender? gender,
    ActivityLevel? activityLevel,
    String? primaryDataSource,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      nickname: nickname ?? this.nickname,
      userAge: userAge ?? this.userAge,
      userHeightCm: userHeightCm ?? this.userHeightCm,
      userWeightKg: userWeightKg ?? this.userWeightKg,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      primaryDataSource: primaryDataSource ?? this.primaryDataSource,
    );
  }

  double get recommendedCalories {
    double bmr;
    if (gender == Gender.male) {
      bmr = 88.362 + (13.397 * userWeightKg) + (4.799 * userHeightCm) - (5.677 * userAge);
    } else {
      bmr = 447.593 + (9.247 * userWeightKg) + (3.098 * userHeightCm) - (4.330 * userAge);
    }

    // ✅ 수정: activityMultiplier가 모든 경우에 할당되도록 수정
    final double activityMultiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.light:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderate:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.active:
        activityMultiplier = 1.725;
        break;
      case ActivityLevel.veryActive:
        activityMultiplier = 1.9;
        break;
    }
    return bmr * activityMultiplier;
  }
}