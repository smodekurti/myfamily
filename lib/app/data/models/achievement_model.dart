import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_model.freezed.dart';
part 'achievement_model.g.dart';

@freezed
class AchievementModel with _$AchievementModel {
  const factory AchievementModel({
    required String id,
    required String userId,
    required String familyId,
    required String achievementId, // Reference to achievement definition
    required DateTime unlockedAt,
  }) = _AchievementModel;

  factory AchievementModel.fromJson(Map<String, dynamic> json) => _$AchievementModelFromJson(json);
}

// Achievement definitions
class AchievementType {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const AchievementType(
    this.id,
    this.name,
    this.description,
    this.icon,
  );

  static const firstTask = AchievementType('first_task', 'First Task', 'Complete your first task', Icons.check_circle);
  static const taskMaster = AchievementType('task_master', 'Task Master', 'Complete 10 tasks', Icons.star);
  static const taskExpert = AchievementType('task_expert', 'Task Expert', 'Complete 50 tasks', Icons.workspace_premium);
  static const streakStarter = AchievementType('streak_starter', 'Streak Starter', 'Maintain a 3-day streak', Icons.local_fire_department);
  static const streakChampion = AchievementType('streak_champion', 'Streak Champion', 'Maintain a 7-day streak', Icons.whatshot);
  static const streakLegend = AchievementType('streak_legend', 'Streak Legend', 'Maintain a 30-day streak', Icons.auto_awesome);
  static const pointsCollector = AchievementType('points_collector', 'Points Collector', 'Earn 100 points', Icons.monetization_on);
  static const pointsChampion = AchievementType('points_champion', 'Points Champion', 'Earn 500 points', Icons.emoji_events);
  static const pointsLegend = AchievementType('points_legend', 'Points Legend', 'Earn 1000 points', Icons.military_tech);
  static const earlyBird = AchievementType('early_bird', 'Early Bird', 'Complete a task before 8 AM', Icons.wb_twilight);
  static const nightOwl = AchievementType('night_owl', 'Night Owl', 'Complete a task after 10 PM', Icons.nightlight);
  static const weeklyWarrior = AchievementType('weekly_warrior', 'Weekly Warrior', 'Complete 5 tasks in a week', Icons.calendar_today);

  static const List<AchievementType> values = [
    firstTask,
    taskMaster,
    taskExpert,
    streakStarter,
    streakChampion,
    streakLegend,
    pointsCollector,
    pointsChampion,
    pointsLegend,
    earlyBird,
    nightOwl,
    weeklyWarrior,
  ];
}

// Helper functions for Supabase integration
class AchievementModelHelpers {
  static AchievementModel fromSupabase(Map<String, dynamic> json) => AchievementModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    familyId: json['family_id'] as String,
    achievementId: json['achievement_id'] as String,
    unlockedAt: DateTime.parse(json['unlocked_at'] as String),
  );

  static Map<String, dynamic> toSupabase(AchievementModel achievement) => {
    'id': achievement.id,
    'user_id': achievement.userId,
    'family_id': achievement.familyId,
    'achievement_id': achievement.achievementId,
    'unlocked_at': achievement.unlockedAt.toIso8601String(),
  };
}

