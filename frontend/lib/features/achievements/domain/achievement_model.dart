import 'package:flutter/material.dart';

import 'achievement_icons.dart';

/// Categoría de logro (valores del API).
enum AchievementCategory {
  strength('strength', 'Fuerza'),
  consistency('consistency', 'Constancia'),
  volume('volume', 'Volumen'),
  records('records', 'Récords'),
  bodyProgress('body_progress', 'Progreso corporal'),
  routines('routines', 'Rutinas'),
  profile('profile', 'Perfil'),
  special('special', 'Especiales');

  final String apiValue;
  final String label;

  const AchievementCategory(this.apiValue, this.label);

  static AchievementCategory? fromApi(String? value) {
    if (value == null) return null;
    for (final cat in AchievementCategory.values) {
      if (cat.apiValue == value) return cat;
    }
    return null;
  }
}

/// Nivel para logros de fuerza.
enum AchievementTier {
  bronze('bronze', 'Bronce', Color(0xFFCD7F32)),
  silver('silver', 'Plata', Color(0xFFB8B8B8)),
  gold('gold', 'Oro', Color(0xFFFFD54F));

  final String apiValue;
  final String label;
  final Color accentColor;

  const AchievementTier(this.apiValue, this.label, this.accentColor);

  static AchievementTier? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final tier in AchievementTier.values) {
      if (tier.apiValue == value) return tier;
    }
    return null;
  }
}

/// Logro devuelto por GET /api/achievements/.
class UserAchievement {
  final String id;
  final AchievementCategory category;
  final AchievementTier? tier;
  final String title;
  final String subtitle;
  final String description;
  final String iconKey;
  final String? imageUrl;
  final bool isUnlocked;
  final double progress;
  final String? progressLabel;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.id,
    required this.category,
    required this.tier,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconKey,
    this.imageUrl,
    required this.isUnlocked,
    this.progress = 0,
    this.progressLabel,
    this.unlockedAt,
  });

  IconData get icon => achievementIconFor(iconKey);

  Color get accentColor => tier?.accentColor ?? const Color(0xFFE2F163);

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id']?.toString() ?? '',
      category: AchievementCategory.fromApi(json['category']?.toString()) ??
          AchievementCategory.special,
      tier: AchievementTier.fromApi(json['tier']?.toString()),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? 'emoji_events',
      imageUrl: json['image_url']?.toString(),
      isUnlocked: json['is_unlocked'] == true,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      progressLabel: json['progress_label']?.toString(),
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString())
          : null,
    );
  }
}

class AchievementsState {
  final List<UserAchievement> achievements;
  final int unlockedCount;
  final int totalCount;
  final bool isLoading;
  final String? error;
  final List<String> pendingCelebrations;

  const AchievementsState({
    this.achievements = const [],
    this.unlockedCount = 0,
    this.totalCount = 0,
    this.isLoading = false,
    this.error,
    this.pendingCelebrations = const [],
  });

  List<UserAchievement> get unlocked =>
      achievements.where((a) => a.isUnlocked).toList();

  List<UserAchievement> get locked =>
      achievements.where((a) => !a.isUnlocked).toList();

  List<UserAchievement> get vitrineCandidates {
    final unlockedSorted = List<UserAchievement>.from(unlocked)
      ..sort((a, b) {
        final aTime = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    if (unlockedSorted.length >= 2) {
      return unlockedSorted.take(2).toList();
    }
    if (unlockedSorted.length == 1) {
      final next = locked.where((a) => a.progress > 0).toList()
        ..sort((a, b) => b.progress.compareTo(a.progress));
      if (next.isNotEmpty) {
        return [unlockedSorted.first, next.first];
      }
      return unlockedSorted;
    }
    final inProgress = locked.where((a) => a.progress > 0).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    return inProgress.take(2).toList();
  }

  AchievementsState copyWith({
    List<UserAchievement>? achievements,
    int? unlockedCount,
    int? totalCount,
    bool? isLoading,
    String? error,
    List<String>? pendingCelebrations,
    bool clearError = false,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingCelebrations: pendingCelebrations ?? this.pendingCelebrations,
    );
  }

  static AchievementsState fromApiResponse(
    Map<String, dynamic> data, {
    List<String> pendingCelebrations = const [],
    bool isLoading = false,
    String? error,
  }) {
    final list = (data['achievements'] as List? ?? [])
        .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
        .toList();

    return AchievementsState(
      achievements: list,
      unlockedCount: (data['unlocked_count'] as num?)?.toInt() ??
          list.where((a) => a.isUnlocked).length,
      totalCount:
          (data['total_count'] as num?)?.toInt() ?? list.length,
      pendingCelebrations: pendingCelebrations,
      isLoading: isLoading,
      error: error,
    );
  }
}
